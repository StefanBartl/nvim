---@module 'debugging'

local M = {}

---@return nil
function M.setup()
  require("debugging.autocmds").attach { list_autocmds = true }
	require("debugging.markdown").attach { inline_debug_fixed = false }
	require("debugging.terminals").attach { keylogger = false }
	require("debugging.usercmds").attach()
end

return M
