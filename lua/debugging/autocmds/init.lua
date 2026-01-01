---@module 'debugging.autocmds'

local M = {}

---@param opts autocmds_modules
---@return nil
function M.enable(opts)
  opts = opts or {}

  if opts.list_autocmds and opts.list_autocmds == true then
    require("debugging.autocmds.list_autocmds")
  end
end

return M
