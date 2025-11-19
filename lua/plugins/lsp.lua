---@module 'plugins.lsp'
--- Language Server Protocol integration, formatting, and diagnostics tools.

---@type LazyPluginSpec[]
return {

  -- LazyDev: Completion and docs for Lua `require` modules
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lazydev.nvim/types" },
        { path = "luvit-meta/library", words = { "vim%.uv", "uv", "vim%.loop" } },
        { "nvim-dap-ui" },
      },
    },
  },

  -- Completion source for LazyDev
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0,
      })
    end,
  },

  -- Blink-based completion for LazyDev (optional)
  -- {
  --   "saghen/blink.cmp",
  --   version = "1.*", -- pin to the latest v1.x tag so prebuilt binaries match
  --   opts = {
  --     sources = {
  --       default = { "lazydev", "lsp", "path", "snippets", "buffer" },
  --       providers = {
  --         lazydev = {
  --           name = "LazyDev",
  --           module = "lazydev.integrations.blink",
  --           score_offset = 100,
  --         },
  --       },
  --     },
  --     fuzzy = {
  --       implementation = "prefer_rust",
  --       prebuilt_binaries = {
  --         force_version = "v1.4.0",
  --       },
  --     },
  --     signature = { enabled = true },
  --   },
  -- },

  -- Conform: LSP-agnostic formatting engine
  {
    "stevearc/conform.nvim",
    config = function()
      local conform = require("conform")

      ---@diagnostic disable-next-line: redundant-parameter
      conform.setup({
        notify_on_error = false,
        format_on_save = { timeout_ms = 1200, lsp_fallback = true },
        formatters_by_ft = {
          lua = { "stylua" },
          javascript = { "prettierd", "prettier" },
          typescript = { "prettierd", "prettier" },
          typescriptreact = { "prettierd", "prettier" },
          json = { "jq", "prettierd", "prettier" },
          css = { "prettierd", "prettier" },
          sh = { "shfmt" },
          go = { "gofumpt", "goimports" }, -- keep golines opt-in
          markdown = { "prettierd", "mdformat", "prettier" },
        },
      })
    end,
  },

  -- Workspace-wide diagnostics (LSP-level)
  {
    "artemave/workspace-diagnostics.nvim",
    event = "LspAttach",
  },

  -- Trouble: Diagnostic list in sidebar (virtual text alternative)
  {
    "folke/trouble.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    version = "*",
    lazy = false,
    config = function()
      require("trouble").setup({
        mode = "document_diagnostics",
        auto_close = true,
        auto_preview = false,
        focus = true,
      })
    end,
  },

  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = function()
      require("config.inc_rename")
    end,
  },

  --[[
  {
    "iabdelkareem/csharp.nvim",
    ft = { "cs", "csproj", "sln" },
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
      "Tastyep/structlog.nvim",
    },
    config = function()
      require("mason").setup()
      require("csharp").setup({
        lsp = {
          omnisharp = {
            enable = true,
            cmd_path = "C:\\tools\\LanguageServerProtocol\\csharp\\omnisharp\\OmniSharp.exe",
          },
          --[[
          roslyn = {
            enable = true,
            cmd_path = "C:\\tools\\LanguageServerProtocol\\csharp\\roslyn-lsp\\content\\LanguageServer\\win-x64\\Microsoft.CodeAnalysis.LanguageServer.dll",
          },
        },
      })
    end,
  },

]]

    -- :TSToolsOrganizeImports - sorts and removes unused imports
    -- :TSToolsSortImports - sorts imports
    -- :TSToolsRemoveUnusedImports - removes unused imports
    -- :TSToolsRemoveUnused - removes all unused statements
    -- :TSToolsAddMissingImports - adds imports for all statements that lack one and can be imported
    -- :TSToolsFixAll - fixes all fixable errors
    -- :TSToolsGoToSourceDefinition - goes to source definition (available since TS v4.7)
    -- :TSToolsRenameFile - allow to rename current file and apply changes to connected files
    -- :TSToolsFileReferences - find files that reference the current file (available since TS v4.2)
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
  },

}
