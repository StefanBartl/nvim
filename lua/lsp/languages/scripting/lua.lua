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

  -- AUDIT:
  require("lsp.languages.scripting.lua_hl").setup()
end

---@type Lsp.Languages.ConfiguredLangs.Webdev.Lua.Module
return M
