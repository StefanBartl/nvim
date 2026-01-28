---@module 'plugins.ui'
--- UI enhancements for command-line, messages, and focused writing.

---@type LazyPluginSpec[]
return {
  {
    "s1n7ax/nvim-window-picker",
    version = "2.*",
    config = function()
      require("window-picker").setup({
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          -- filter using buffer options
          bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = { "neo-tree", "neo-tree-popup", "notify" },
            -- if the buffer type is one of following, the window will be ignored
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    end,
  },

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

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
  },
}
