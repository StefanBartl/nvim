---@module 'plugins.trouble'
---@brief trouble.nvim plugin specification with spell-check integration.

local numbering = require("config.trouble.numbering")

return {
  {
    "folke/trouble.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    version = "*",
    lazy = false,

    config = function()
      require("trouble").setup({
        preview = {
          type     = "split",
          relative = "win",
          position = "right",
          size     = 0.30,
        },

        modes = {
          -- Standard LSP diagnostics
          diagnostics = {
            mode = "diagnostics",

            preview = {
              type     = "split",
              relative = "win",
              position = "right",
              size     = 0.30,
            },

            formatters = {
              index = numbering.index_prefix(),
              main  = "message",
            },
          },

          -- Quickfix list
          qflist = {
            mode = "qflist",

            preview = {
              type     = "split",
              relative = "win",
              position = "right",
              size     = 0.30,
            },

            formatters = {
              index = numbering.index_prefix(),
              main  = "message",
            },
          },

          -- Location list
          loclist = {
            mode = "loclist",

            preview = {
              type     = "split",
              relative = "win",
              position = "right",
              size     = 0.30,
            },

            formatters = {
              index = numbering.index_prefix(),
              main  = "message",
            },
          },
        },
      })

      require("config.trouble.spell").setup({
        severity = vim.diagnostic.severity.WARN,

        -- Toggle spell session
        keymap = "<leader>zs",

        -- Interactive correction
        keymap_fix = "<leader>z=",

        -- Accept first suggestion
        keymap_fix1 = "<leader>z1",
      })
    end,
  },
}
