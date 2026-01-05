---@module 'debugging.autocmds'

local M = {}

---@param opts Dbg.Autocmds.Modules|nil
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.list_autocmds == true or opts.all == true then
    require("debugging.autocmds.list_autocmds")
  end
end


return M
