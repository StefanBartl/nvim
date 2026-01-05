---@module 'debugging.tools'

local M = {}

---@param opts Dbg.Tools.Modules
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.buffer_inspector or opts.all then
    require("debugging.tools.buffer_inspector").enable()
  end

  if opts.cursor_state and opts.cursor_state == true or opts.all == true then
    require("debugging.tools.cursor.state").enable()
  end

  if opts.vardump and opts.vardump == true or opts.all == true then
    require("debugging.tools.vardump").enable()
  end
end

return M
