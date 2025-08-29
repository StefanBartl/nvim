---@module 'plugins.essentials'
--- Contains essential plugin dependencies

---@type LazyPluginSpec[]
return {

  -- Plenary: Shared Lua functions used by many plugins (fs, async, path, job, etc.)
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
  },

}
