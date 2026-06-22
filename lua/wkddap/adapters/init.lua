---@module 'wkddap.adapters'

local notify = require("lib.nvim.notify").create("[wkddap.adapters]")

local M = {}

--- Register all adapters for specified languages
---@param languages string[] List of languages
---@param custom_adapters table Custom adapter overrides
---@return boolean success
---@diagnostic disable-next-line: unused-local
function M.register_all(languages, custom_adapters)
  local registry = require("wkddap.registry")

  -- If no languages specified, use all supported
  if not languages or #languages == 0 then
    languages = registry.available_languages()
  end

  -- Register each language
  for _, lang in ipairs(languages) do
    local ok, err = registry.register(lang)
    if not ok then
      notify.warn(string.format(("[wkddap.adapters] Failed to register %s: %s") , lang, err or "unknown"))
    end
  end

  return true
end

return M
