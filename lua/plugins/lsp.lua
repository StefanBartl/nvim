---@module 'plugins.lsp'
--- Language Server Protocol integration, formatting, and diagnostics tools.

---@type LazyPluginSpec[]
return {
  -- {
  --   "antosha417/nvim-lsp-file-operations",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     -- Uncomment whichever supported plugin(s) you use
  --     -- "nvim-tree/nvim-tree.lua",
  --     "nvim-neo-tree/neo-tree.nvim",
  --     -- "simonmclean/triptych.nvim"
  --   },
  --   config = function()
  --     require("lsp-file-operations").setup()
  --   end,
  -- },

  -- LazyDev: Completion and docs for Lua `require` modules
  {
    "folke/lazydev.nvim",
    ft = "lua",
    dependencies = {
      {
        "DrKJeff16/wezterm-types",
        lazy = true,
        version = false, -- Get the latest version
      },
    },

    opts = {
      library = {
        { path = "${3rd}/luv/library",   words = { "vim%.uv", "uv", "vim%.loop" } },
        { path = "lazydev.nvim/types" },
        { path = "luvit-meta/library",   words = { "vim%.uv", "uv", "vim%.loop" } },
        { path = "plenary.nvim/types",   mods = { "plenary" } },
        { path = "telescope.nvim/types", mods = { "telescope" } },
        { "nvim-dap-ui" },
        { path = "wezterm-types",        mods = { "wezterm" } },
        { path = "LazyVim",              words = { "LazyVim" } },
        { path = "nvim-treesitter",      mods = { "vim.treesitter" } },
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

      require("config.copilot.cmp")

      -- Disable completion in any scratch/utility buffer (buftype ~= "" --
      -- nofile, prompt, terminal, quickfix, ...). Without this, cmp's popup
      -- also shows over lib.nvim.ui.kit's own floating input/chooser/
      -- confirm/form surfaces (all buftype=nofile), where <CR> is bound to
      -- "confirm the visible completion" (see nvchad.configs.cmp's
      -- `select = true`) -- so submitting e.g. a filename in filetree.nvim's
      -- create/rename prompt could silently confirm a fuzzy-matched
      -- completion/snippet instead.
      local prev_enabled = opts.enabled
      opts.enabled = function()
        if vim.bo.buftype ~= "" then
          return false
        end
        return type(prev_enabled) ~= "function" or prev_enabled()
      end
    end,
  },

  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = function()
      require("lspsaga").setup({
        beacon = {
          enable = false,
        },
        breadcrumb = {
          enable = true,
          show_file = true,
          folder_level = 1,
        },
        hover = {
          enable = false,
        },
        lightbulb = {
          enabled = false,
        },
        rename = {
          enable = false,
        },
        term_toggle = {
          enable = false,
        },
      })
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter", -- optional
      "nvim-tree/nvim-web-devicons",     -- optional
    },
  },

  -- Blink-based completion for LazyDev (optional)
  -- {
  --   "saghen/blink.cmp",
  --   version = "1.*", -- pin to the latest v1.x tag so prebuilt binaries match
  --   opts = {
  --     sources = {
  --       default = { "lazydev", "lsp", "path", "snippets", "buffer" },
  --       providers = {
  --        lazydev = {
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
  -- No `config` here on purpose: `lsp.formatter.conform.setup()` (called from
  -- `lsp.init`) is the single authoritative `conform.setup()` call — it runs
  -- after plugin startup and carries the full formatter/resolve() config. A
  -- second `conform.setup()` here would just be silently overwritten by it.
  { "stevearc/conform.nvim" },

  -- Workspace-wide diagnostics (LSP-level)
  {
    "artemave/workspace-diagnostics.nvim",
    event = "LspAttach",
  },

  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = function()
      require("config.inc_rename")
    end,
  },

  {
    "oribarilan/lensline.nvim",
    branch = "release/2.x",
    event = "LspAttach",
    config = function()
      require("lensline").setup({
        profiles = {
          {
            name = "minimal",
            style = {
              placement = "inline",
              prefix = "",
              render = "focused", -- optionally render lenses only for focused function
            },
          },
        },
      })
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
}
