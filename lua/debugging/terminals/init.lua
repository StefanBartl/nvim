---@module 'debugging.terminals'

local M = {}

---@param opts Dbg.Terminals.Modules
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.keylogger and opts.keylogger == true or opts.all == true then
    require("debugging.terminals.keylogger").enable()
  end
end

return M
