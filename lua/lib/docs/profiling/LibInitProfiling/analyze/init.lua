---@module 'docs.profiling.LibInitProfiling.analyze'
-- =========================================================
-- Startup Profiling Analyzer (multi-run, multi-variant)
--
-- Analysiert mehrere --startuptime Logs gruppiert nach
-- Varianten-Ordnern (z. B. Lazy / Normal / UltraLazy).
--
-- Für jedes Modul (z. B. lib, lib.*, lib/**) werden über alle
-- Läufe hinweg statistische Kennzahlen berechnet:
--
--   * mean (Durchschnitt)
--   * median
--   * min / max
--   * runs (Anzahl Läufe)
--
-- Architektur:
--   root/
--     VariantA/
--       startup1.log
--       startup2.log
--     VariantB/
--       startup1.log
--       startup2.log
--
-- Die Analyse ist erweiterbar für spätere Metriken
-- (z. B. Std-Abweichung, Percentiles, CSV-Export).
-- =========================================================

local M = {}

-- =========================================================
-- configuration
-- =========================================================

---@class LibInitProfilingConfig
---@field root string
---@field include_prefixes string[]
---@field min_time_ms number

---@type LibInitProfilingConfig
local DEFAULT_CONFIG = {
  root = "lib/docs/profiling/LibInitProfiling",
  include_prefixes = { "lib", "lib.", "lib/" },
  min_time_ms = 0.0,
}

-- =========================================================
-- filesystem helpers
-- =========================================================

---@param path string
---@return string[]
local function scandir(path)
  local out = {}
  local fs = vim.loop.fs_scandir(path)
  if not fs then
    return out
  end
  while true do
    local name, t = vim.loop.fs_scandir_next(fs)
    if not name then
      break
    end
    if t == "directory" then
      out[#out + 1] = name
    end
  end
  return out
end

---@param path string
---@return string[]
local function scan_logs(path)
  local out = {}
  local fs = vim.loop.fs_scandir(path)
  if not fs then
    return out
  end
  while true do
    local name, t = vim.loop.fs_scandir_next(fs)
    if not name then
      break
    end
    if t == "file" and name:match("%.log$") then
      out[#out + 1] = path .. "/" .. name
    end
  end
  table.sort(out)
  return out
end

-- =========================================================
-- parsing
-- =========================================================

---@param line string
---@return number|nil total
---@return number|nil self
---@return string|nil module
local function parse_line(line)
  -- example:
  -- 766.196  011.331  000.476: require('lib')
  local total, self, mod =
    line:match("^%d+%.%d+%s+(%d+%.%d+)%s+(%d+%.%d+):%s+require%('([^']+)'%)")

  if not mod then
    return nil, nil, nil
  end

  return tonumber(total), tonumber(self), mod
end

---@param mod string
---@param prefixes string[]
---@return boolean
local function match_prefix(mod, prefixes)
  for _, p in ipairs(prefixes) do
    if mod == p or mod:sub(1, #p) == p then
      return true
    end
  end
  return false
end

-- =========================================================
-- statistics
-- =========================================================

---@param values number[]
---@return number
local function mean(values)
  local s = 0
  for _, v in ipairs(values) do
    s = s + v
  end
  return s / #values
end

---@param values number[]
---@return number
local function median(values)
  table.sort(values)
  local n = #values
  if n % 2 == 1 then
    return values[(n + 1) / 2]
  end
  return (values[n / 2] + values[n / 2 + 1]) / 2
end

---@param values number[]
---@return number, number
local function minmax(values)
  local minv, maxv = values[1], values[1]
  for i = 2, #values do
    minv = math.min(minv, values[i])
    maxv = math.max(maxv, values[i])
  end
  return minv, maxv
end

-- =========================================================
-- core analysis
-- =========================================================

---@class ModuleRuns
---@field total number[]
---@field self number[]

---@class VariantStats
---@field runs integer
---@field modules table<string, ModuleRuns>

---@param logfile string
---@param cfg LibInitProfilingConfig
---@return table<string, ModuleRuns>
local function analyze_file(logfile, cfg)
  local f = io.open(logfile, "r")
  if not f then
    error("cannot open log: " .. logfile)
  end

  ---@type table<string, ModuleRuns>
  local modules = {}

  for line in f:lines() do
    local total, self, mod = parse_line(line)
    if mod and match_prefix(mod, cfg.include_prefixes) and total >= cfg.min_time_ms then
      local m = modules[mod]
      if not m then
        m = { total = {}, self = {} }
        modules[mod] = m
      end
      m.total[#m.total + 1] = total
      m.self[#m.self + 1] = self
    end
  end

  f:close()
  return modules
end

---@param cfg LibInitProfilingConfig|nil
---@return table<string, VariantStats>
function M.analyze_all(cfg)
  cfg = cfg or DEFAULT_CONFIG

  ---@type table<string, VariantStats>
  local variants = {}

  for _, variant in ipairs(scandir(cfg.root)) do
    if variant ~= "analyze" then
      local vpath = cfg.root .. "/" .. variant
      local logs = scan_logs(vpath)

      ---@type VariantStats
      local vst = {
        runs = #logs,
        modules = {},
      }

      for _, logfile in ipairs(logs) do
        local per_file = analyze_file(logfile, cfg)
        for mod, runs in pairs(per_file) do
          local acc = vst.modules[mod]
          if not acc then
            acc = { total = {}, self = {} }
            vst.modules[mod] = acc
          end
          for _, t in ipairs(runs.total) do
            acc.total[#acc.total + 1] = t
          end
          for _, s in ipairs(runs.self) do
            acc.self[#acc.self + 1] = s
          end
        end
      end

      variants[variant] = vst
    end
  end

  return variants
end

-- =========================================================
-- reporting
-- =========================================================

---@param variants table<string, VariantStats>
function M.print(variants)
  for vname, vst in pairs(variants) do
    print("")
    print("== " .. vname .. " ==")
    print(string.format("runs: %d", vst.runs))
    print(string.format("%-50s %10s %10s %10s %10s",
      "module", "mean", "median", "min", "max"))
    print(string.rep("-", 96))

    for mod, runs in pairs(vst.modules) do
      if #runs.total > 0 then
        local avg = mean(vim.deepcopy(runs.total))
        local med = median(vim.deepcopy(runs.total))
        local minv, maxv = minmax(runs.total)

        print(string.format(
          "%-50s %10.3f %10.3f %10.3f %10.3f",
          mod, avg, med, minv, maxv
        ))
      end
    end
  end
end

-- =========================================================
-- entrypoint
-- =========================================================

---@param cfg LibInitProfilingConfig|nil
function M.run(cfg)
  local variants = M.analyze_all(cfg)
  M.print(variants)
end

return M

