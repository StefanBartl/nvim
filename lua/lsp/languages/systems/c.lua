---@module 'lsp.languages.systems.c'
---@class LangCQoL

local Autocmd = require("lib.nvim.autocmd")

local M = {}

---@return nil
function M.enable()
  local grp = Autocmd.group("LangC", true)
  Autocmd.create("FileType", function(_) end, {
    group = grp,
    pattern = { "c", "cpp" },
  })
end

---@type Lsp.Languages.ConfiguredLangs.C.Module
return M
