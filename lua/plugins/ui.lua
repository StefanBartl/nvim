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

  -- Noice Enhanced command line and LSP UI
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    cmd = { "Noice", "NoiceAll", "NoiceHistory", "NoiceDismiss", "NoiceError" },
    opts = require("config.noice"),
    dependencies = {
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
      "rcarriga/nvim-notify",
    },
  },

  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "UIEnter", -- or "VeryLazy"
    init = function()
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        ["Find Under"] = "<C-n>",
        ["Find Subword Under"] = "<C-n>",
        ["I BS"] = "", -- disable conflicting insert backspace
      }
    end,
  },

  -- Zen Mode: Distraction-free writing
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
  },
}
