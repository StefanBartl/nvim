---@module 'lsp.languages.systems.zig'
---@class LangZigQoL

local Autocmd = require("lib.nvim.autocmd")

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangZig", { clear = true })
  Autocmd.create("FileType", function(_) end, {
    group = grp,
    pattern = "zig",
  })
end

---@type Lsp.Languages.ConfiguredLangs.Zig.Module
return M
