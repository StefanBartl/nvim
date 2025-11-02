---@module 'lib.debug'

local M = {}

---@return nil
function M.setup()
  require("debug.autocmds.list_autocmds")
end

return M
