---@module 'uv_doc.search'
---@brief Fuzzy search and candidate filtering

local M = {}

local strings = require("lib.lua.strings")
local cache = require("usrcmds.uv_doc.cache")
local normalize = require("usrcmds.uv_doc.normalize")

--- Returns candidates matching query
---@param query string|nil
---@nodiscard
---@return string[]
function M.candidates_for(query)
  local all = cache.get_symbols() or {}

  if not query or strings.is_empty_or_space(query) then
    return all
  end

  local normalized = normalize.to_uv(query)
  local q = strings.replace_plain(normalized, "uv_", "")

  -- Try prefix expansion first
  local prefix = normalize.get_prefix(q)
  if prefix then
    ---@type string[]
    local matches = {}
    for i = 1, #all do
      local name = all[i]
      if strings.starts_with(name, prefix) or strings.contains(name, prefix) then
        matches[#matches + 1] = name
      end
    end
    return matches
  end

  -- Fuzzy substring match
  local needle = q:lower()
  ---@type string[]
  local matches = {}
  for i = 1, #all do
    local name = all[i]
    if strings.contains(name:lower(), needle) then
      matches[#matches + 1] = name
    end
  end

  return matches
end

return M
