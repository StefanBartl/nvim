---@module 'debugging.usercmds'

local M = {}

---@param opts Dbg.Usercmds.Modules
---@return nil
function M.setup(opts)
  opts = opts or {}

  if opts.reports and opts.reports == true or opts.all == true then
    require("debugging.usercmds.reports").enable()
  end

  if opts.neotree and opts.neotree == true or opts.all == true then
    require("debugging.usercmds.neotree_safety").enable()
  end
end

return M
