---@module 'bindings.usrcmds.case.query'
--- The `:Cases` querschnitt: field filters and cross-case listing, built on
--- the same registry/meta everything else in this module already uses. No
--- route-per-field code — init.lua generates one route per entry in
--- `config.infocard_fields`, all landing here.

local config = require("bindings.usrcmds.case.config")
local registry = require("bindings.usrcmds.case.registry")
local meta = require("bindings.usrcmds.case.meta")
local detect = require("bindings.usrcmds.case.detect")

local M = {}

--- Substring, case-insensitive match against a `.case.json` field. A
--- nil/empty pattern means "field is set at all" — the free lookup for
--- "which cases still need this field filled in" (`:Cases company` with no
--- argument lists everyone who HAS a company, so the complement is visible
--- by elimination against `:Cases list`).
---@param field string  One of config.infocard_fields.
---@param pattern string|nil
---@return Lib.Case.RegistryEntry[]
function M.by_field(field, pattern)
  local pat = (pattern and pattern ~= "") and pattern:lower() or nil
  local out = {}
  for _, e in ipairs(registry.list()) do
    local m = meta.read(e.dir) or {}
    local value = m[field]
    if pat == nil then
      if value ~= nil and value ~= "" then
        out[#out + 1] = e
      end
    elseif type(value) == "string" and value:lower():find(pat, 1, true) then
      out[#out + 1] = e
    end
  end
  return out
end

--- Every case, bucketed by state (config.states order), for `:Cases list`.
---@return table<string, Lib.Case.RegistryEntry[]>
function M.by_state()
  local groups = {}
  for _, state in ipairs(config.states) do
    groups[state] = {}
  end
  for _, e in ipairs(registry.list()) do
    groups[e.state] = groups[e.state] or {}
    table.insert(groups[e.state], e)
  end
  return groups
end

--- AND-combination of `M.by_field` across several fields at once, for
--- `:Cases find company=Scan year=2026` (composer's `kv` grammar — the
--- reason this takes a table keyed by field name rather than two args like
--- `by_field`). An empty `kv` matches nothing, deliberately: "find" with no
--- criteria is a typo'd command, not "list everything" (`:Cases list`
--- already does that).
---@param kv table<string, string>
---@return Lib.Case.RegistryEntry[]
function M.by_fields(kv)
  local out = {}
  if next(kv) == nil then
    return out
  end
  for _, e in ipairs(registry.list()) do
    local m = meta.read(e.dir) or {}
    local matches = true
    for field, pattern in pairs(kv) do
      local value = m[field]
      local pat = (pattern and tostring(pattern) ~= "") and tostring(pattern):lower() or nil
      if pat == nil then
        if value == nil or value == "" then
          matches = false
          break
        end
      elseif not (type(value) == "string" and value:lower():find(pat, 1, true)) then
        matches = false
        break
      end
    end
    if matches then
      out[#out + 1] = e
    end
  end
  return out
end

--- The `n` most recently touched cases (mtime of the newest non-sidecar
--- file in each), newest first — for `:Cases recent`.
---@param n integer|nil  default 10
---@return { entry: Lib.Case.RegistryEntry, mtime: integer }[]
function M.recent(n)
  n = n or 10
  local rows = {}
  for _, e in ipairs(registry.list()) do
    local mtime = detect.last_touched(e.dir)
    if mtime then
      rows[#rows + 1] = { entry = e, mtime = mtime }
    end
  end
  table.sort(rows, function(a, b)
    return a.mtime > b.mtime
  end)
  local out = {}
  for i = 1, math.min(n, #rows) do
    out[i] = rows[i]
  end
  return out
end

--- Counts by state / company / year, for `:Cases stats`.
---@return { by_state: table<string, integer>, by_company: table<string, integer>, by_year: table<string, integer> }
function M.stats()
  local by_state, by_company, by_year = {}, {}, {}
  for _, e in ipairs(registry.list()) do
    by_state[e.state] = (by_state[e.state] or 0) + 1
    local m = meta.read(e.dir) or {}
    if m.company then
      by_company[m.company] = (by_company[m.company] or 0) + 1
    end
    if m.year then
      by_year[m.year] = (by_year[m.year] or 0) + 1
    end
  end
  return { by_state = by_state, by_company = by_company, by_year = by_year }
end

return M
