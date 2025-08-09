---@module 'plugins.essentials'
--- Contains essential plugin dependencies for syntax parsing (treesitter),
--- AST text objects, and shared Lua functionality (plenary).

---@type LazyPluginSpec[]
return {

  -- Treesitter: Syntax highlighting, indenting, and text objects based on AST
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {},
    opts = function(_, opts)
      -- Use external parser list
      opts.ensure_installed = require("configs.treesitter_parser")

      -- Syntax highlighting and indenting
      opts.highlight = {
        enable = true,
        use_languagetree = true,
      }
      opts.indent = { enable = true }

      -- AST-based text objects: functions, classes, parameters, blocks
      opts.textobjects = vim.tbl_deep_extend("force", opts.textobjects or {}, {
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

  -- Plenary: Shared Lua functions used by many plugins (fs, async, path, job, etc.)
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
  },

}
