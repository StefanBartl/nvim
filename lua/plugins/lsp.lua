---@module 'plugins.lsp'
--- What this config adds to the LSP setup on top of lsp.nvim's pack.
---
--- The specs that used to live here -- lazydev, conform, lspsaga, lensline,
--- inc-rename, workspace-diagnostics, trouble -- moved into
--- `lsp.pack.{core,ui}` and are installed through `import = "lsp.pack"` in
--- init.lua. What is left is the part that is genuinely about *this* config
--- and would be wrong to ship in a plugin.
---
--- lazy merges `opts` across every spec for the same plugin, which is what
--- makes this split work at all: the pack contributes the lazydev source and
--- the utility-buffer guard, this file contributes a personal word list and
--- the Copilot bridge, and nvim-cmp ends up with both.

---@type LazyPluginSpec[]
return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}

      -- Completes this config's personal StefanBartl/*.nvim plugin names
      -- ("documentation.nvim", not just "documentation") as one atomic
      -- candidate each, ranked by persisted use frequency. See that module's
      -- doc comment for how it composes with cmp's own default sorting.
      --
      -- The plugin list is this config's data, so it is handed over rather
      -- than reached for: lsp.nvim's completion source takes a reader.
      table.insert(opts.sources, { name = "personal_names", priority = 100 })
      require("lsp.completion.personal_names").setup({
        labels = function()
          return require("plugins.personal.list").read()
        end,
      })

      -- Hide Copilot's inline suggestion while cmp's menu is open.
      --
      -- This used to read `require("config.copilot.cmp")` -- which loads the
      -- module and returns its table without ever calling `setup()`. The
      -- bridge had therefore never run: Copilot kept showing its suggestion
      -- behind the completion menu.
      require("config.copilot.cmp").setup()
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
        },
      })
    end,
  },
  ]]
}
