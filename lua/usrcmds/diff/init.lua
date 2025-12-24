---@module 'usrcmds.diff'

local M = {}

---@param opts Usrcmds.diff.opts
---@return nil
function M.enable(opts)
    if opts.diff_exit == true or opts.enable_all then
        require("usrcmds.diff.diff_exit").enable()
    end
  if opts.diff_origin == true or opts.enable_all then
    require("usrcmds.diff.diff_origin").enable()
  end

end

return M
