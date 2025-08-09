---@module 'lsp.languages.go'
---@class LangGoQoL

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangGo", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "go",
    callback = function(_) end,
  })
end

return M
