---@module 'debugging'

local M = {}

---@return nil
function M.setup()
  require("debugging.autocmds").setup { list_autocmds = true }
	require("debugging.markdown").setup { inline_debug_fixed = false }
	require("debugging.terminals").setup { keylogger = false }
end

return M
