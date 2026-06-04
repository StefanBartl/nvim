---@module 'lsp.languages.scripting.lua'
---@class LangLuaQoL

local M = {}

---@return nil
function M.enable()
  local grp = vim.api.nvim_create_augroup("LangLua", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = grp,
    pattern = "lua",
    callback = function(_) end,
  })
end

---@type Lsp.Languages.ConfiguredLangs.Webdev.Lua.Module
return M
