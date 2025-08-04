<<<<<<< HEAD
---@module 'plugins.editing'
--- Editing tools: commenting, autotags, templates, quickfix enhancements, TODOs.

---@type LazyPluginSpec[]
return {

  -- Auto Template Strings for JS/TS
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
  },

  -- Comment.nvim: Toggle code comments
  {
    "numToStr/Comment.nvim",
    keys = {
      { "tcl", mode = "n",          desc = "[Comment] Toggle current line" },
      { "tl",  mode = { "n", "o" }, desc = "[Comment] Toggle linewise" },
      { "tl",  mode = "x",          desc = "[Comment] Toggle linewise (visual)" },
      { "tcb", mode = "n",          desc = "[Comment] Toggle current block" },
      { "tb",  mode = { "n", "o" }, desc = "[Comment] Toggle blockwise" },
      { "tb",  mode = "x",          desc = "[Comment] Toggle blockwise (visual)" },
    },
    config = function(_, opts)
      require("Comment").setup(opts)
    end,
  },

  -- Treesitter-based HTML tag closing and renaming
  {
    "windwp/nvim-ts-autotag",
    opts = function()
      return {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
        per_filetype = {
          html = { enable_close = false },
        },
      }
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  {
    "mg979/vim-visual-multi",
    branch = 'master',
    lazy = false,
  },

}
=======
---@module 'plugins.editing'
--- Editing tools: commenting, autotags, templates, quickfix enhancements, TODOs.

---@type LazyPluginSpec[]
return {

  -- Auto Template Strings for JS/TS
  {
    "chrisgrieser/nvim-puppeteer",
    lazy = false,
  },

  -- Comment.nvim: Toggle code comments
  {
    "numToStr/Comment.nvim",
    keys = {
      { "tcl", mode = "n",          desc = "[Comment] Toggle current line" },
      { "tl",  mode = { "n", "o" }, desc = "[Comment] Toggle linewise" },
      { "tl",  mode = "x",          desc = "[Comment] Toggle linewise (visual)" },
      { "tcb", mode = "n",          desc = "[Comment] Toggle current block" },
      { "tb",  mode = { "n", "o" }, desc = "[Comment] Toggle blockwise" },
      { "tb",  mode = "x",          desc = "[Comment] Toggle blockwise (visual)" },
    },
    config = function(_, opts)
      require("Comment").setup(opts)
    end,
  },

  -- Treesitter-based HTML tag closing and renaming
  {
    "windwp/nvim-ts-autotag",
    opts = function()
      return {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
        per_filetype = {
          html = { enable_close = false },
        },
      }
    end,
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },

  {
    "mg979/vim-visual-multi",
    branch = 'master',
    lazy = false,
  },
}

>>>>>>> d71f64e (d)
