---@module 'debugging.terminals'

local M = {}
---@param modules terminals_modules
---@return nil
function M.attach(modules)
  if modules.keylogger and modules.keylogger == true then
    require("debugging.terminals.keylogger")
  end
end

return M
