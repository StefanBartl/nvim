---@module 'lsp.languages.app.csharp'
---@class LangCsQoL

local Autocmd = require("lib.nvim.autocmd")

local M = {}

---@return nil
function M.enable()
  local grp = Autocmd.group("LangCs", true)
  Autocmd.create("FileType", function(_) end, {
    group = grp,
    pattern = "cs",
  })
end

---@type Lsp.Languages.ConfiguredLangs.CSharp.Module
return M
