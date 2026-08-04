---@module 'bindings.usrcmds.case.query'
--- The `:Cases` querschnitt: field filters and cross-case listing, built on
--- the same registry/meta everything else in this module already uses. No
--- route-per-field code — init.lua generates one route per entry in
--- `config.infocard_fields`, all landing here.

local config = require("bindings.usrcmds.case.config")
local registry = require("bindings.usrcmds.case.registry")
local meta = require("bindings.usrcmds.case.meta")

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

return M
