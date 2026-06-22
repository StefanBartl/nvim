---@module 'plugins.ai.gp'

---@type LazyPluginSpec[]
return {
  {
    "robitx/gp.nvim",
    lazy = true,
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = function()
      local conf = require("config.gp_config.config")
      require("gp").setup(conf)
    end,
  },
}
