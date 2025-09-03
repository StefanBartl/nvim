---@module 'plugins.treesitter'
--- Treesitter core, textobjects, and context view.
--- This splits textobject keymaps/config out of the core plugin and applies
--- them where the extension is actually loaded. It also adds small robustness
--- tweaks (TSUpdate, safe parser list import, sensible events).

---@type LazyPluginSpec[]
return {

  -- Core Treesitter: highlighting/indent/modules bootstrap
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",                         -- keep parsers up to date
    event = { "BufReadPost", "BufNewFile" },    -- load on first useful file
    -- Note: do not configure textobjects here
    opts = function(_, opts)
      -- Safely pull external parser list; fall back to empty if missing
      local ok, parser_list = pcall(require, "config.treesitter.parser")

      ---@type table
      opts = opts or {}

      -- Install set (external list preferred)
      opts.ensure_installed = ok and parser_list or opts.ensure_installed or {}

      -- Syntax highlighting and indenting
      opts.highlight = {
        enable = true,
        use_languagetree = true,
        additional_vim_regex_highlighting = false,
      }
      opts.indent = { enable = true }

      return opts
    end,
    config = function(_, opts)
      -- Important: apply only core opts here; textobjects are configured below
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- Treesitter Textobjects: motions and selections on AST nodes
  -- The keymaps/settings live here (co-located with the actual extension).
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
          lookahead = true, -- jump forward to the next textobject automatically
          keymaps = {
            -- functions
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            -- classes
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            -- blocks / conditionals / loops
            ["ab"] = "@block.outer",
            ["ib"] = "@block.inner",
            -- parameters/arguments
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

      -- Merge textobjects into Treesitter config without touching other modules
      require("nvim-treesitter.configs").setup({ textobjects = textobjects })
    end,
  },

  -- Sticky AST context (function/class header at top of window)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      -- Default setup is fine; tune here if needed
      require("treesitter-context").setup()
    end,
  },
}
