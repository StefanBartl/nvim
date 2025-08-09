local lspconfig = require("lspconfig")
lspconfig.gopls.setup({})

require("nvim-treesitter.configs").setup({
  ensure_installed = { "go" },
  highlight = { enable = true },
})

require("lsp_signature").setup({
  bind = true,
  floating_window = true,
  hint_enable = true,
  handler_opts = {
    border = "rounded"
  }
})
