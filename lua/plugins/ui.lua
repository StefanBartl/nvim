---@module 'plugins.ui'
--- UI enhancements for command-line, messages, and focused writing.

---@type LazyPluginSpec[]
return {

  -- Better Quickfix UI
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      auto_enable = true,
      auto_resize_height = true,
    },
    config = function(_, opts)
      require("bqf").setup(opts)
    end,
  },

  -- Noice: Enhanced command line and LSP UI
  {
    "folke/noice.nvim",
    lazy = false,
    event = nil,
    opts = require "config.noice",
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "rcarriga/nvim-notify",
        main = "notify", -- tells Lazy which module to setup
        opts = require "config.notify", -- config/notify/init.lua returns a table
        init = function()
          -- ensure Neovim uses nvim-notify for vim.notify
          local ok, notify = pcall(require, "notify")
          if ok then
            vim.notify = notify
          end
        end,
      },
    },
  },

  -- Zen Mode: Distraction-free writing
  {
    "folke/zen-mode.nvim",
  },
}
