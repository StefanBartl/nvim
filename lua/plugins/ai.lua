---@module 'plugins.ai'
--- AI-based tools and integrations (Copilot, gp.nvim, etc.)

---@type LazyPluginSpec[]
return {

  -- GitHub Copilot via Lua integration
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({})
    end,
  },

  -- gp.nvim: ChatGPT-style Neovim integration
  {
    "robitx/gp.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local conf = require("lua.configs.gp_config.config")
      require("gp").setup(conf)
    end,
    event = "VeryLazy",
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
