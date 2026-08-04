---@module 'bindings.usrcmds.case.migrate'
--- One-time move from the legacy layout — Cases/<nr> flat, Cases/<company>/<nr>
--- nested, and a separate top-level Closed/<company>/<nr> — to the flat
--- Cases/<state>/<nr> layout config.lua now describes (MIGRATION.md §1).
---
--- Idempotent by construction: scan_legacy() skips any child of a legacy
--- root whose name is itself a configured state (Open/Closed/Reassigned),
--- so a second run finds nothing left to move — that's also what makes
--- config.cases_root safe to scan as "the old Cases/ root" even though
--- it's the SAME path as the new container: before the first run its only
--- children are legacy case dirs, after the run its only children are the
--- three state folders, and scan_legacy() only ever picks up the former.

local config = require("bindings.usrcmds.case.config")
local meta = require("bindings.usrcmds.case.meta")
local detect = require("bindings.usrcmds.case.detect")
local mkdirp = require("lib.nvim.fs.mkdirp")

local M = {}

local uv = vim.uv or vim.loop

-- Pre-migration roots: config.cases_root was the flat+company-nested "open"
-- area; a separate top-level Closed/ (sibling of Cases/, not under it) held
-- the closed ones the same way.
local LEGACY_ROOTS = {
  { dir = config.cases_root, state = "Open" },
  { dir = config.root .. "/Closed", state = "Closed" },
}

local STATE_NAMES = {}
for _, s in ipairs(config.states) do
  STATE_NAMES[s] = true
end

---@param dir string
---@return string[]
local function subdirs(dir)
  local names = {}
  local fd = uv.fs_scandir(dir)
  if not fd then
    return names
  end
  while true do
    local name, typ = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    if typ == "directory" then
      names[#names + 1] = name
    end
  end
  return names
end

---@param root string
---@return { short: string, dir: string, company: string|nil }[]
local function scan_legacy(root)
  local out = {}
  for _, name in ipairs(subdirs(root)) do
    if not STATE_NAMES[name] then
      if name:match("^%d+$") then
        out[#out + 1] = { short = name, dir = root .. "/" .. name, company = nil }
      else
        local company_dir = root .. "/" .. name
        for _, short in ipairs(subdirs(company_dir)) do
          if short:match("^%d+$") then
            out[#out + 1] = { short = short, dir = company_dir .. "/" .. short, company = name }
          end
        end
      end
    end
  end
  return out
end

---@class Lib.Case.MigrationStep
---@field short string
---@field from string
---@field to string
---@field company string|nil
---@field state string

--- What WOULD move. Pure (fs_scandir reads only).
---@return Lib.Case.MigrationStep[]
function M.plan()
  local steps = {}
  for _, root in ipairs(LEGACY_ROOTS) do
    for _, e in ipairs(scan_legacy(root.dir)) do
      steps[#steps + 1] = {
        short = e.short,
        from = e.dir,
        to = config.state_dir(root.state) .. "/" .. e.short,
        company = e.company,
        state = root.state,
      }
    end
  end
  return steps
end

---@param steps Lib.Case.MigrationStep[]
---@return string[]
function M.describe(steps)
  local lines = {}
  for _, s in ipairs(steps) do
    lines[#lines + 1] = ("move  %s  ->  %s%s"):format(
      s.from,
      s.to,
      s.company and (" (company: " .. s.company .. ")") or ""
    )
  end
  return lines
end

---@class Lib.Case.MigrationResult
---@field step Lib.Case.MigrationStep
---@field ok boolean
---@field err string|nil

--- Write/complete `.case.json` BEFORE moving — it travels with fs_rename —
--- then move. Existing sidecar fields always win over a fresh guess;
--- `company` from the legacy path is the one thing that would otherwise be
--- lost the moment the company folder disappears.
---@param steps Lib.Case.MigrationStep[]
---@return Lib.Case.MigrationResult[]
function M.run(steps)
  local results = {}
  for _, s in ipairs(steps) do
    local m = meta.read(s.from) or {}
    m.case = m.case or s.short
    m.company = m.company or s.company
    m.title = m.title or detect.title(s.from)
    m.name = m.name or detect.name(s.from)
    if not m.links or #m.links == 0 then
      m.links = detect.links(s.from)
    end
    m.year = m.year or os.date("%Y")
    m.blueprint = m.blueprint or config.default_blueprint
    m.created = m.created or os.date("!%Y-%m-%dT%H:%M:%SZ")
    meta.write(s.from, m)

    mkdirp(config.state_dir(s.state))
    local ok, err = uv.fs_rename(s.from, s.to)
    results[#results + 1] = { step = s, ok = ok and true or false, err = err }
  end
  return results
end

--- Remove now-empty legacy parent dirs left behind (old company folders,
--- the old top-level Closed/ itself). Only ever removes a directory that a
--- fresh scan confirms has zero entries — never assumes.
---@return string[] removed
---@return string[] kept
function M.cleanup()
  local candidates = {}
  for _, root in ipairs(LEGACY_ROOTS) do
    for _, name in ipairs(subdirs(root.dir)) do
      if not STATE_NAMES[name] and not name:match("^%d+$") then
        candidates[#candidates + 1] = root.dir .. "/" .. name
      end
    end
  end
  candidates[#candidates + 1] = config.root .. "/Closed"

  local removed, kept = {}, {}
  for _, dir in ipairs(candidates) do
    local fd = uv.fs_scandir(dir)
    if fd then
      local any = uv.fs_scandir_next(fd) ~= nil
      if any then
        kept[#kept + 1] = dir
      else
        local ok = uv.fs_rmdir(dir)
        if ok then
          removed[#removed + 1] = dir
        else
          kept[#kept + 1] = dir
        end
      end
    end
  end
  return removed, kept
end

return M
