---@module 'debugging.markdown'

local M = {}
---@param modules markdown_modules
---@return nil
function M.attach(modules)
  if modules.inline_debug_fixed and modules.inline_debug_fixed == true then
  	require("debugging.markdown.inline_debug")
  end
end

return M
