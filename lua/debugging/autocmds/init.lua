---@module 'debugging.autocmds'

local M = {}

---@param modules autocmds_modules
---@return nil
function M.attach(modules)
  if modules.list_autocmds and modules.list_autocmds == true then
  	require("debugging.autocmds.list_autocmds")
  end
end

return M
