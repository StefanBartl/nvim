---@module 'lsp.languages.systems.zig'
---@class LangZigQoL

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangZig", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "zig",
    callback = function(_) end,
  })
end

---@type Lsp.Languages.ConfiguredLangs.Zig.Module
return M
