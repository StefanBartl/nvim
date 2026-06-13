---@module 'custom.markdown.util.clipboard'
--- Clipboard helper functions.

local M = {}

--- Copy text to clipboard register
---@param text string
function M.copy(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg("*", text)
end

return M
