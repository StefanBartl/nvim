local nvlsp = require("nvchad.configs.lspconfig")
local attach = require("lsp.attach")
local lspconfig = require("lspconfig")

lspconfig.ts_ls.setup({
  capabilities = nvlsp.capabilities,
  on_attach = attach.on_attach,
  on_init = nvlsp.on_init,
})
