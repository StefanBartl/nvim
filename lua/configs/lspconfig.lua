local nvlsp = require("nvchad.configs.lspconfig")
local lspconfig = require("lspconfig")
local lsp_servers = require("configs.lsp_servers")

require("lazydev").setup({})

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
  -- Autoformat über conform
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
        local range_params = vim.lsp.util.make_range_params(0, "utf-16")
        local params = {
          textDocument = range_params.textDocument,
          range = range_params.range,
          context = { only = { "source.fixAll.eslint" } },
        }
        local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
        if result then
          for _, res in pairs(result) do
            for _, action in pairs(res.result or {}) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
              end
              if type(action.command) == "table" then
                vim.lsp.buf_request(bufnr, "workspace/executeCommand", action.command, function() end)
              end
            end
          end
        end
      end,
    })
  end

  -- Optional: eigene Keymaps hier ergänzen

  -- Wichtig: auch NvChads Original on_attach aufrufen
  if nvlsp.on_attach then
    nvlsp.on_attach(client, bufnr)
  end
end

-- Alle Server aus custom/configs/lsp_servers.lua initialisieren
for server, config in pairs(lsp_servers) do
  lspconfig[server].setup(vim.tbl_extend("force", {
    on_attach = on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }, config))
end

-- lua_ls separat behandeln (weil lazydev gewisse Dinge automatisch patched)
lspconfig.lua_ls.setup({
  on_attach = on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  settings = {
    Lua = {
      runtime = {
        -- Neovim uses LuaJIT
        version = "LuaJIT",
        path = vim.split(package.path, ";"),
      },
      diagnostics = {
        -- Recognize the `vim` global and optionally `vim.uv`
        globals = { "vim", "vim.uv" },
      },
      workspace = {
        library = vim.tbl_extend("force",
          vim.api.nvim_get_runtime_file("", true),
          {
            vim.fn.stdpath("config"),
            "/home/steve/Custom/nvim-types/neodev.nvim/types",
          }
        ),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false, -- Disable telemetry for privacy
      },
      completion = {
        callSnippet = "Replace", -- Optional: how snippets expand
      },
    },
  },
})
