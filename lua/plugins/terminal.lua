---@module 'plugins.terminal'
--- Terminal integration using ToggleTerm.

---@type LazyPluginSpec[]
return {

  -- ToggleTerm: Manage terminal layouts in splits, floats, and tabs
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true,
    lazy = false,
  },

}

