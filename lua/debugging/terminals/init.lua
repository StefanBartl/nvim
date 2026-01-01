---@module 'debugging.terminals'

local M = {}
---@param opts terminals_modules
---@return nil
function M.attach(opts)
  opts = opts or {}

  if opts.keylogger and opts.keylogger == true then
    require("debugging.terminals.keylogger")
  end
end

return M
