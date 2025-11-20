---@module 'plugins.textobjects'
--- Textobject extensions for motions and selections.

---@type LazyPluginSpec[]
return {

  --  mini.ai: Modern textobjects powered by Lua
  {
    "echasnovski/mini.ai",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup()
    end,
  },

  -- wellle/targets.vim: Extra textobjects for quotes, args, etc.
  {
    "wellle/targets.vim",
    event = "VeryLazy",
  },
}
