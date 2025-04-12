return {

-- 1. Essential dependencies and tools

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua", "go", "javascript", "typescript", "json", "css", "html"
      },
    },
  },

  -- Plenary, a necessary dependency for many other plugins
  "nvim-lua/plenary.nvim",
  -- Telescope for fuzzy finding files, buffers, etc.
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    -- TODO: Wenn trouble installiert ist
    --opts = function()
    --  return require "configs.telescope"
    --end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "telescope")
      local telescope = require "telescope"
      telescope.setup(opts)
      -- Load extensions
      for _, ext in ipairs(opts.extensions_list) do
        telescope.load_extension(ext)
      end
    end,
  },

  -- Telescope Search UI
  {
    "FabianWirth/search.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local builtin = require('telescope.builtin')
      require("search").setup({
        mappings = {
          next = "<Tab>",
          prev = "<C-p>"
        },
        append_tabs = {
          {
            "Commits",
            builtin.git_commits,
            available = function()
              return vim.fn.isdirectory(".git") == 1
            end
          }
        },
        tabs = {
          {
            "Files",
            function(opts)
              opts = opts or {}
              if vim.fn.isdirectory(".git") == 1 then
                builtin.git_files(opts)
              else
                builtin.find_files(opts)
              end
            end
          },
          {
            name = "All Files",
            tele_func = builtin.find_files,
            tele_opts = { no_ignore = true, hidden = true }
          },
          {
            -- Neuer Tab für Grep
            name = "Grep",
            tele_func = builtin.live_grep, -- Verwende `live_grep` für Grep durch alle Dateien
          },
          {
            -- Neuer Tab für Buffers
            name = "Buffers",
            tele_func = builtin.buffers, -- Verwende `buffers` zum Durchsuchen der offenen Buffer
          },
        },
        collections = {
          -- Die "git" Sammlung, wie im ursprünglichen Setup
          git = {
            initial_tab = 1, -- Git branches
            tabs = {
              { name = "Branches", tele_func = builtin.git_branches },
              { name = "Commits",  tele_func = builtin.git_commits },
              { name = "Stashes",  tele_func = builtin.git_stash },
            }
          }
        }
      })
    end
  },

  -- FZF for fuzzy finding files, buffers, etc.
  {
    "ibhagwan/fzf-lua",
    lazy = false,
  },


-- 2. File management

  -- Harpoon for managing multiple files and quick navigation
  {
    "ThePrimeagen/harpoon",
    lazy = false,                          -- Load immediately
    dependencies = {
      { "nvim-telescope/telescope.nvim" }, -- Telescope integration
      { "nvim-lua/plenary.nvim" },
    },
    config = function()
      require("harpoon").setup()
      require("telescope").load_extension("harpoon")
      require("configs.harpoon")
    end,
  },


-- 3. LSP completion
-- TODO
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
        format_on_save = {
          -- Enable for specific filetypes
          ["*"] = { timeout_ms = 5000 },
        },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
        {
          "folke/lazydev.nvim",
          ft = "lua", -- only load on lua files
          opts = {
            library = {
              -- See the configuration section for more details
              -- Load luvit types when the `vim.uv` word is found
              { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
          },
        },
    },
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Trouble.nvim for displaying LSP diagnostics
  {
    "folke/trouble.nvim",
    dependencies = "nvim-tree/nvim-web-devicons", -- Abhängigkeit für Icons
    version = "*",
    lazy = false, -- Lade das Plugin direkt beim Start
    config = function()
      require("trouble").setup({
        mode = "document_diagnostics", -- Standardmodus
        auto_open = false,             -- Öffnet Trouble nicht automatisch
        auto_close = true,             -- Schließt Trouble, wenn keine Fehler vorhanden sind
        auto_preview = false,          -- Vorschau bei Auswahl deaktivieren
      })
    end,
  },



-- 4. Git related plugins

-- TODO: Optimales gut plugin finden
  -- Fugitive for Git commands within Neovim
  {
    "tpope/vim-fugitive",
    lazy = false, -- Stelle sicher, dass Fugitive sofort geladen wird
  },

  -- LazyGit integration for terminal Git UI
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    }
  },

  -- Neogit for a Magit-like Git interface
  {
    "TimUntersberger/neogit",
    requires = { "nvim-lua/plenary.nvim" },
    config = function()
      require("neogit").setup({})
    end,
  },

  -- DiffView for visualizing Git diffs
  {
    "sindrets/diffview.nvim",
    requires = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = true,
  },


--  5. Dockertools

  -- Dockertools
  {
    "kkvh/vim-docker-tools",
    lazy = false,
    config = function()
    -- Anpassung der Anzeigeformate (optional)
      vim.api.nvim_set_var("dockertools_container_format", "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}")
      -- vim.g.dockertools_container_format = 'table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'
    end,
  },

  -- Denops Docker Integration
  {
    "vim-denops/denops.vim",
    lazy = false, -- Lade es sofort, um sicherzustellen, dass es verfügbar ist
    config = function()
      -- Optional: Überprüfen, ob Deno korrekt funktioniert
      vim.cmd [[
        command! DenopsCheckHealth echo "Denops Health Check"
      ]]
    end,
  },
  -- Denops Docker Integration
  {
    "skanehira/denops-docker.vim",
    lazy = false,
    dependencies = { "vim-denops/denops.vim" },
    config = function()
      -- Lade den Docker-Teil des Plugins
      vim.cmd [[
        command! DenopsReload call denops#server#restart()
      ]]
    end,
  },


-- 6. Markdown

  -- Markdown Preview
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = "cd app && npm install",
  },

  -- Checkboxes, Tabellen-Highlighting, und mehr
  {
    "preservim/vim-markdown",
    ft = { "markdown" },
    config = function()
    end,
  },

  -- Headlines, Blöcke hervorheben
  --{
  --  "lukas-reineke/headlines.nvim",
  --  ft = { "markdown" },
  --  config = function()
  --    require("headlines").setup()
  --  end,
  --},


-- 7. Code formatting, folding, and syntax highlighting

  -- Better Quickfix Window for better quickfix window
  {
    "kevinhwang91/nvim-bqf",
    ft = 'qf',
    opts = {
      auto_enable = true,
      auto_resize_height = true, -- Automatically adjust the height of the quickfix window
    },
    config = function(_, opts)
      require("bqf").setup(opts)
    end,
  },


  -- Auto Template Strings
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false, -- plugin lazy-loads itself. Can also load on filetypes.
  },

  -- TODO: Erklären was das macht, wie man das weiter erweitern kann, wie man es anwendet im workflow
  -- TODO: ctrl / sollte das machen
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
      require("Comment").setup(opts) -- Initialisiert das Plugin
    end,
  },

  -- TODO: In nvim.cmp integirieren!
   -- GitHub Copilot integration
   {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.api.nvim_set_var("copilot_no_tab_map", true) -- Prevent conflicts with tab mappings
    end,
  },

  -- Use treesitter to autoclose and autorename html tag
  {
    "windwp/nvim-ts-autotag",
    opts = function()
      return {
        enable_close = true,           -- Auto close tags
        enable_rename = true,          -- Auto rename pairs of tags
        enable_close_on_slash = false, -- Auto close on trailing </
        per_filetype = {
          ["html"] = {
            enable_close = false
          }
        }
      }
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  -- Use delete keybindings like daf, dif (delete around/inside function) usw

  { 'echasnovski/mini.ai', version = '*' },


  -- ChatGPT

  {
      "jackMort/ChatGPT.nvim",
      event = "VeryLazy",
      dependencies = {
          "MunifTanjim/nui.nvim",
          "nvim-lua/plenary.nvim",
          "nvim-telescope/telescope.nvim",
      },
      config = function()
          require("chatgpt").setup({
              api_key_cmd = "echo $OPENAI_API_KEY",
          })
      end,
  },


-- 8. MISC Plugins

  -- Zen Mode
  {
    "folke/zen-mode.nvim",
  },


}
