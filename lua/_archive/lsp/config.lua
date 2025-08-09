---@module 'lsp.config'
---@
local M = {}

local nvlsp = require("nvchad.configs.lspconfig")
local lsp_servers = require("lsp.servers")

require("lazydev").setup({})
nvlsp.defaults()
vim.lsp.enable(lsp_servers)

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

require("lsp.languageservers.lua_ls").setup()
require("lsp.languageservers.csharp")
require("lsp.languageservers.clangd")

return M
