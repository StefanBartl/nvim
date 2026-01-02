---@module 'debugging.usercmds'
---FIX: types

local M = {}

---@param opts table
---@return nil
function M.enable(opts)
  opts = opts or {}

  if opts.reports or opts.all == true then
    require("debugging.usercmds.reports").enable()
  end

  if opts.neotree or opts.all == true then
    require("debugging.usercmds.neotree_safety").enable()
  end
end

return M
