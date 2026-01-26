---@module 'plugins.treesitter'
--- Treesitter core, textobjects, and context view.
--- This splits textobject keymaps/config out of the core plugin and applies
--- them where the extension is actually loaded.

---@type LazyPluginSpec[]
return {

  -- Core Treesitter: highlighting/indent/modules bootstrap
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", -- keep parsers up to date
    event = { "BufReadPost", "BufNewFile" }, -- load on first useful file
    -- Note: do not configure textobjects here
    opts = function(_, opts)
      ---@type table
      opts = opts or {}

      -- Pull external parser list; fall back to empty if missing
      local ok, parser_list = pcall(require, "config.treesitter.parser")
      opts.ensure_installed = ok and parser_list or opts.ensure_installed or {}

      -- Syntax highlighting and indenting
      opts.matchup = { enable = true }
      opts.highlight = {
        enable = true,
        use_languagetree = true,
        additional_vim_regex_highlighting = false,
      }
      opts.indent = { enable = true }

      return opts
    end,
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- Treesitter Textobjects: motions and selections on AST nodes
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- Configure the textobjects module explicitly
    config = function()
      ---@type table
      local textobjects = {
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
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
            ["]b"] = "@block.outer",
            ["]p"] = "@parameter.inner",
          },
          goto_next_end = {
            ["]F"] = "@function.outer",
            ["]C"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
            ["[b"] = "@block.outer",
            ["[p"] = "@parameter.inner",
          },
          goto_previous_end = {
            ["[F"] = "@function.outer",
            ["[C"] = "@class.outer",
          },
        },
      }

      require("nvim-treesitter.configs").setup({ textobjects = textobjects })
    end,
  },

  -- Sticky AST context (function/class header at top of window)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("treesitter-context").setup()
    end,
  },
}
