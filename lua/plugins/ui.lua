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
    opts = require("configs.noice_ui"),
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },

  -- Zen Mode: Distraction-free writing
  {
    "folke/zen-mode.nvim",
  },

}
