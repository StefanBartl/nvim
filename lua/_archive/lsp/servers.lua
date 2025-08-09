---@module 'lsp.servers'
-- Registry: returns a map server_name -> config_table

local M = {}

M.lua_ls = (function() return require("lua.lsp.languageservers.lua_ls") end)()

M.ts_ls = (function() return require("swd.typescript") end)()

M.gopls = (function() return require("lsp.languageservers.gopls") end)()

M.zls = (function() return require("lsp.languageservers.zls") end)()

M.clangd = (function() return require("lsp.languageservers.clangd") end)()

M.omnisharp = (function() return require("lsp.languageservers.csharp") end)()

return M
