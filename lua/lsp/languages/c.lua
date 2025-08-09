---@module 'lsp.languages.c'
---@class LangCQoL

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangC", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = { "c", "cpp" },
    callback = function(_) end,
  })
end

return M
