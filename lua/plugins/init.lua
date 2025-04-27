return {

  --===========================
--=== ESSENTIALS ============
--===========================

  -- Treesitter: Syntax parsing and highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
      ensure_installed = require("custom.treesitter-parser"),
      highlight = {
        enable = true,
        use_languagetree = true,
      },
      indent = { enable = true },
    },
     textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["ab"] = "@block.outer",
          ["ib"] = "@block.inner",
          ["ap"] = "@parameter.outer",
          ["ip"] = "@parameter.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = {
          ["]m"] = "@function.outer",
          ["]c"] = "@class.outer",
          ["]b"] = "@block.outer",
          ["]p"] = "@parameter.inner",
        },
        goto_previous_start = {
          ["[m"] = "@function.outer",
          ["[c"] = "@class.outer",
          ["[b"] = "@block.outer",
          ["[p"] = "@parameter.inner",
        },
      },
    },
  },

  -- Plenary: Lua helper library used by many plugins
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
  },

--===========================
--=== FUZZY FINDING =========
--===========================

  -- Telescope: Powerful fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "telescope")
      local telescope = require("telescope")
      telescope.setup(opts)
      for _, ext in ipairs(opts.extensions_list or {}) do
        telescope.load_extension(ext)
      end
    end,
  },

  -- Search.nvim: Tab-based UI for telescope
  {
    "FabianWirth/search.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      require("search").setup({
        mappings = { next = "<Tab>", prev = "<C-p>" },
        append_tabs = {
          { "Commits", builtin.git_commits, available = function() return vim.fn.isdirectory(".git") == 1 end },
        },
        tabs = {
          { "Files", function(opts)
              opts = opts or {}
              if vim.fn.isdirectory(".git") == 1 then
                builtin.git_files(opts)
              else
                builtin.find_files(opts)
              end
            end
          },
          { name = "All Files", tele_func = builtin.find_files, tele_opts = { no_ignore = true, hidden = true } },
          { name = "Grep", tele_func = builtin.live_grep },
          { name = "Buffers", tele_func = builtin.buffers },
        },
        collections = {
          git = {
            initial_tab = 1,
            tabs = {
              { name = "Branches", tele_func = builtin.git_branches },
              { name = "Commits",  tele_func = builtin.git_commits },
              { name = "Stashes",  tele_func = builtin.git_stash },
            }
          }
        }
      })
    end,
  },

  -- fzf-lua: Alternative fuzzy finder
  {
    "ibhagwan/fzf-lua",
    lazy = false,
  },

--===========================
--=== FILE NAVIGATION ======
--===========================

  -- Harpoon: Fast file navigation
  {
    "ThePrimeagen/harpoon",
    lazy = false,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("harpoon").setup()
      require("telescope").load_extension("harpoon")
      require("configs.harpoon")
    end,
  },

--===========================
--=== LSP & FORMATTING ======
--===========================

  -- LSP Config: Core LSP plugin
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    config = function()
      require("configs.lspconfig")
    end,
  },

  -- Conform: Formatting engine
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          json = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          tailwindcss = { "prettier" },
          sql = { "sql_formatter" },
          go = { "gofmt", "goimports", "golines" },
        },
        format_on_save = { ["*"] = { timeout_ms = 5000 } },
      })
    end,
  },

  -- Trouble: Show LSP diagnostics in a sidebar
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
      })
    end,
  },

--===========================
--=== GIT INTEGRATION =======
--===========================

  -- LazyGit: External Git UI
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit", "LazyGitConfig", "LazyGitCurrentFile",
      "LazyGitFilter", "LazyGitFilterCurrentFile"
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    },
  },

  -- DiffView: Visual Git diff tool
  {
    "sindrets/diffview.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = true,
  },

--===========================
--=== MARKDOWN ==============
--===========================

  -- Markdown Preview (browser)
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = "cd app && npm install",
  },

  -- Vim-Markdown: Syntax highlighting, checkboxes etc.
  {
    "preservim/vim-markdown",
    ft = { "markdown" },
  },

--===========================
--=== EDITING TOOLS =========
--===========================

  -- Better Quickfix Window
  {
    "kevinhwang91/nvim-bqf",
    ft = 'qf',
    opts = {
      auto_enable = true,
      auto_resize_height = true,
    },
    config = function(_, opts)
      require("bqf").setup(opts)
    end,
  },

  -- Auto Template Strings (JS/TS)
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
  },

  -- Comments: Toggle code comments
  {
    "numToStr/Comment.nvim",
    keys = {
      { "tcl", mode = "n",          desc = "Comment toggle current line" },
      { "tl",  mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "tl",  mode = "x",          desc = "Comment toggle linewise (visual)" },
      { "tcb", mode = "n",          desc = "Comment toggle current block" },
      { "tb",  mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "tb",  mode = "x",          desc = "Comment toggle blockwise (visual)" },
    },
    config = function(_, opts)
      require("Comment").setup(opts)
    end,
  },

  -- HTML tag closing/renaming with Treesitter
  {
    "windwp/nvim-ts-autotag",
    opts = function()
      return {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
        per_filetype = { ["html"] = { enable_close = false } },
      }
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  -- Mini.ai: Text object enhancements (e.g. "daf" for "delete around function")
  {
    "echasnovski/mini.ai",
    version = "*",
  },

--===========================
--=== MISC TOOLS ============
--===========================

  -- Zen Mode: Focus writing
  {
    "folke/zen-mode.nvim",
  },

  -- Visual multi-cursor support (like in VSCode)
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      vim.g.VM_default_mappings = 0
    end,
    config = function()
      vim.g.VM_maps = {
        ["Find Under"]         = "<C-y>",
        ["Find Subword Under"] = "<C-y>",
      }
    end,
  },

--===========================
--=== PERSONAL PROJECTS =====
--===========================

  -- nvim-containers: Manage container engines from inside Neovim
  {
    dir = "/media/steve/Depot/MyGithub/nvim-containers",
    event = "VeryLazy",
    config = function()
      require("containers").setup({
        engine = "podman",
      })
    end,
  },

  -- nvim-cmdlog: Manage your command history
  {
    dir = "/media/steve/Depot/MyGithub/nvim-cmdlog/",
    lazy = false,
    config = function()
      require("cmdlog").setup({
        picker = "telescope",
    })
    end,
  },

  {
    "floatterminal.local",
    dir = vim.fn.stdpath("config") .. "/lua/custom/floatterminal",
    lazy = false,
    config = function()
      require("custom.floatterminal") -- Registriert Floaterminal-Command hier korrekt
    end,
  },



}
