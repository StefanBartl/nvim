---@module 'plugins.ai'

---@type LazyPluginSpec[]
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({})
    end,
  },
  {
    "robitx/gp.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    config = function()
      local conf = require("config.gp_config.config")
      require("gp").setup(conf)
    end,
  },

  -- Optional: Copilot.vim legacy plugin (disabled)
  -- {
  --   "github/copilot.vim",
  --   event = "InsertEnter",
  --   config = function()
  --     vim.api.nvim_set_var("copilot_no_tab_map", true)
  --   end,
  -- },
}
