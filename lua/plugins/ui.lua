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
  -- + nvim-notify
  {
    "folke/noice.nvim",
    lazy = false,
    opts = require "config.noice",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },

  -- Zen Mode: Distraction-free writing
  {
    "folke/zen-mode.nvim",
  },
}
