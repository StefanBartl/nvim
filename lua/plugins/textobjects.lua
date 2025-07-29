---@module 'plugins.textobjects'
--- Textobject extensions for motions and selections.
--- Info: Treesitter itself is defined in `essentials.lua`, this file only adds enhancements.

---@type LazyPluginSpec[]
return {

  -- mini.ai: Modern textobjects powered by Lua
  -- {
  --   "echasnovski/mini.ai",
  --   version = "*",
  --   event = "VeryLazy",
  --   config = function()
  --     require("mini.ai").setup()
  --   end,
  -- },

  -- wellle/targets.vim: Extra textobjects for quotes, args, etc.
  -- {
  --   "wellle/targets.vim",
  --   event = "VeryLazy",
  -- },

  -- Treesitter-based textobjects (dependent on nvim-treesitter)
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   lazy = true,
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  -- },

}

