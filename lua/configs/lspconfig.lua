local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Liste der LSP-Server und ihre Einstellungen
local servers = {
  ts_ls = {},      -- TypeScript/JavaScript
  eslint = {},        -- ESLint
  cssls = {},         -- CSS
  jsonls = {},        -- JSON
  sqls = {},          -- SQL
  tailwindcss = {},   -- Tailwind CSS
  gopls = {           -- Golang
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
        gofumpt = true,
      },
    },
  },
}

-- Gemeinsame on_attach-Funktion
local function on_attach(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }

  -- Keybindings für LSP
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

  -- Automatische Formatierung mit Conform
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        require("conform").format({ bufnr = bufnr })
      end,
    })
  end

  -- ESLint fix on save
  if client.name == "eslint" then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.execute_command({
          command = "eslint.applyAllFixes",
          arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
        })
      end,
    })
  end
end

-- ESLint-Server einrichten
lspconfig.eslint.setup({
  on_attach = on_attach,
  settings = {
    packageManager = "npm", -- Optional: Wähle den Paketmanager (npm oder yarn)
  },
})

-- Setup für jeden Server in der Liste
for server, config in pairs(servers) do
  lspconfig[server].setup(vim.tbl_extend("force", {
    on_attach = on_attach,
    capabilities = capabilities,
  }, config))
end
