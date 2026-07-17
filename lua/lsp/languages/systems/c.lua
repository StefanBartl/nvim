---@module 'lsp.languages.c'
---@class LangCQoL

local Autocmd = require("lib.nvim.autocmd")

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangC", { clear = true })
  Autocmd.create("FileType", function(_) end, {
    group = grp,
    pattern = { "c", "cpp" },
  })
end

---@type Lsp.Languages.ConfiguredLangs.C.Module
return M
