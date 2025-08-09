local lspconfig = require("lspconfig")
local nvlsp = require("nvchad.configs.lspconfig")
local attach = require("lsp.attach")

lspconfig.omnisharp.setup({
  cmd = {
    "C:\\tools\\LanguageServerProtocol\\csharp\\omnisharp\\OmniSharp.exe",
    "--languageserver",
    "--hostPID",
    tostring(vim.fn.getpid()),
  },
  capabilities = nvlsp.capabilities,
  on_attach = attach.on_attach,
  on_init = nvlsp.on_init,
})
