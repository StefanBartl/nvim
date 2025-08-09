---@module 'lsp.core.util'
---@class LspUtil

local M = {}

---@param bufnr integer
---@return boolean
function M.any_client_can_format(bufnr)
  bufnr = bufnr or 0
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, c in ipairs(clients) do
    local caps = c.server_capabilities or {}
    if caps.documentFormattingProvider or caps.documentRangeFormattingProvider then
      return true
    end
  end
  return false
end

return M
