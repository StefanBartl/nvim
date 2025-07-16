return {

  --===========================
  --=== ESSENTIALS ============
  --===========================

  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = function(_, opts)
      opts.ensure_installed = require("custom.treesitter-parser")
      opts.highlight = {
        enable = true,
        use_languagetree = true,
      }
      opts.indent = { enable = true }
      opts.textobjects = vim.tbl_deep_extend("force", opts.textobjects or {}, { -- Important: vim.tbl_deep_extend
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
      })
      return opts
    end,
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
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-github.nvim",
    },
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
          { name = "Grep",      tele_func = builtin.live_grep },
          { name = "Buffers",   tele_func = builtin.buffers },
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
      require("configs.harpoon_config")
    end,
  },

  --===========================
  --=== LSP & FORMATTING ======
  --===========================

  -- LSP Config: Core LSP plugin
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("configs.lspconfig")
    end,
  },

  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library" },
        --"./lua/@types",
      },
    },
  },
  { -- optional cmp completion source for require statements and module annotations
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      })
    end,
  },
  { -- optional blink completion source for require statements and module annotations
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
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

  {
    "artemave/workspace-diagnostics.nvim",
    lazy = false,
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

  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    config = function()
      require("configs.dap.init")
    end
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio"
    },
    config = function()
        local dap, dapui = require("dap"), require("dapui")
        dapui.setup()
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close()
        end
      end
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

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = true,
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
  --{
  --  "echasnovski/mini.ai",
  --  version = "*",
  --},

  {
    "folke/todo-comments.nvim",
    event = "BufReadPost",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = true,
      keywords = {
        FIX = {
          icon = " ",
          color = "error",                            -- can be a hex color, or a named color (see below)
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
        },
        INFO = { icon = " ", color = "info" },
        DEBUG = { icon = " ", color = "hint" },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
        EXP = {
          icon = "🔬", color = "test", alt = { "EXPERIMENT", "EXPERIMENTAL" },
        },
        REF = {
          icon = "󰁨 ",
          color = "hint",
          alt = { "REFACTOR", "REWRITE", "CLEANUP", "IMPROVE", "RESTRUCTURE" },
        },
        ADD = {
          icon = " ",
          color = "info",
          alt = { "EXT", "NEXT", "FUTURE", "ENHANCE", "HOOK" },
        },
        WATCH = {
          icon = " ",
          color = "warning",
          alt = { "MONITOR", "OBSERVE", "TRACK", "INSPECT", "SURVEILLANCE" },
        },
      },
    },
  },


  --===========================
  --=== MISC TOOLS ============
  --===========================

  -- Zen Mode: Focus writing
  {
    "folke/zen-mode.nvim",
  },

  -- GitHub Copilot integration
  --{
  --  "github/copilot.vim",
  --  event = "InsertEnter",
  --  config = function()
  --    vim.api.nvim_set_var("copilot_no_tab_map", true) -- Prevent conflicts with tab mappings
  --  end,
  --},

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({})
    end,
  },

  -- noice - cmdline ui
  {
    "folke/noice.nvim",
    lazy = false,
    event = nil,
    opts = require("configs.noice"),
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },

  -- gp.nvim - nvim ai prompt
  {
    "robitx/gp.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local conf = require("configs.gp_config")
      require("gp").setup(conf)
    end,
    event = "VeryLazy",
  },

  {
    'vim-denops/denops.vim',
    lazy = false,
  },
  -- keycaster
  {
    "hasundue/vim-keycasty",
    lazy = false, -- sofort beim Start laden
    init = function()
      vim.g.keycasty_output_win_title = "Keycast"
      --vim.cmd("KeycastStart")
    end,
    keys = {
      {
        "<leader>ks",
        "<cmd>KeycastStart<CR>",
        desc = "Keycasty: Start",
      },
      {
        "<leader>ke",
        "<cmd>KeycastStop<CR>",
        desc = "Keycasty: Stop",
      },
      {
        "<leader>kt",
        "<cmd>KeycastToggle<CR>",
        desc = "Keycasty: Toggle",
      },
    },
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

]]--


  --===========================
  --=== PERSONAL PROJECTS =====
  --===========================

  -- nvim-containers: Manage container engines from inside Neovim
  {
    dir = vim.fn.expand("~/MyGithub/nvim-containers"),
    event = "VeryLazy",
    config = function()
      require("containers").setup({})
    end,
  },

  -- nvim-cmdlog: Manage your command history
  {
    dir = vim.fn.expand("~/MyGithub/nvim-cmdlog"),
    config = function()
      require("cmdlog").setup({
        picker = "telescope",
      })
    end,
  },

  -- reposcope.nvim
  {
    dir = vim.fn.expand("~/MyGithub/reposcope.nvim"),
    name = "reposcope",
    event = "VeryLazy",
    config = function()
      require("reposcope.init").setup({})
    end,
  },

  -- myterm.local
  {
    name = "myterm.local",
    dir = vim.fn.stdpath("config") .. "/lua/custom/myterm",
    lazy = false,
    config = function()
      require("custom.myterm")
    end,
  },

  -- mygrep.nvim
  {
    dir = vim.fn.expand("~/MyGithub/mygrep.nvim"),
    name = "mygrep",
    lazy = false,
    config = function()
      require("mygrep").setup({
        tool_picker_style = "ui",
      })
    end,
  },

  -- train.nvim
  {
    dir = vim.fn.expand("~/MyGithub/train.nvim"),
    name = "train.nvim",
    cmd = { "Train", "TrainToday" },
    config = function()
      require("nvim-train").setup()
    end,
  },
}
