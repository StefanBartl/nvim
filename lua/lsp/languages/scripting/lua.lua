---@module 'lsp.languages.scripting.lua'
---@class LangLuaQoL

local Autocmd = require("lib.nvim.autocmd")

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangLua", { clear = true })
  Autocmd.create("FileType", function(_) end, {
    group = grp,
    pattern = "lua",
  })
end

---@type Lsp.Languages.ConfiguredLangs.Lua.Module
return M
