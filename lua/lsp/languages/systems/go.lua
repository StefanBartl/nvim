---@module 'lsp.languages.systems.go'
---@class LangGoQoL

local Autocmd = require("lib.nvim.autocmd")

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangGo", { clear = true })
  Autocmd.create("FileType", function(_) end, {
    group = grp,
    pattern = "go",
  })
end

---@type Lsp.Languages.ConfiguredLangs.Go.Module
return M
