---@module 'plugins.webdev'
--- resty.nvim's lazy.nvim spec -- an HTTP client plugin, VeryLazy-loaded.

return {
  {
    "lima1909/resty.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
  },
}
