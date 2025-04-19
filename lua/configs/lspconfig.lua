local nvlsp = require("nvchad.configs.lspconfig")
local lspconfig = require("lspconfig")
local lsp_servers = require("configs.lsp_servers")

-- Nutze NvChads Defaults
nvlsp.defaults()

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Custom on_attach kombiniert mit nvchad
local function on_attach(client, bufnr)
  -- Conform autoformat
  if client.supports_method("textDocument/formatting") then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        require("conform").format({ bufnr = bufnr })
      end,
    })
  end

  -- ESLint apply fixes
  if client.name == "eslint" then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { "source.fixAll.eslint" } }
        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
        if result then
          for _, res in pairs(result) do
            for _, action in pairs(res.result or {}) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
              end
              if type(action.command) == "table" then
                vim.lsp.buf.execute_command(action.command)
              end
            end
          end
        end
      end,
    })
  end

  -- Optional: weitere Keymaps/Autocommands hier

  -- Rufe auch NvChads Original on_attach auf
  if nvlsp.on_attach then
    nvlsp.on_attach(client, bufnr)
  end
end

-- ESLint separat behandeln (falls gewünscht)
lspconfig.eslint.setup({
  on_attach = on_attach,
  settings = {
    packageManager = "npm",
  },
})

-- Alle Server aus custom/configs/lsp_servers.lua
for server, config in pairs(lsp_servers) do
  lspconfig[server].setup(vim.tbl_extend("force", {
    on_attach = on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }, config))
end
