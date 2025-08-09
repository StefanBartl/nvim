---@module 'lsp.languages.csharp'
---@class LangCsQoL

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangCs", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "cs",
    callback = function(_) end,
  })
end

return M
