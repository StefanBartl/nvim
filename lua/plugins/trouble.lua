---@module 'plugins.trouble'
---@brief trouble.nvim plugin specification with SpellChecker integration.

local numbering = require("config.trouble.numbering")

return {
  {
    "folke/trouble.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    version = "*",
    lazy    = false,

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

      -- SpellChecker ───────────────────────────────────────────────────────
      require("config.trouble.spell").setup({
        severity    = vim.diagnostic.severity.WARN,

        -- Global toggle keymap (no lang / no scope → defaults to en / buf)
        keymap      = "<leader>zs",

        -- Per-buffer correction keymaps (attached when a session is active)
        keymap_fix  = "<leader>z=",   -- z= menu, then advance
        keymap_fix1 = "<leader>z1",   -- accept first suggestion, advance
        keymap_next = "]s",           -- jump to next spell error

        -- Set to false to always use the quickfix fallback
        use_trouble = true,
      })
    end,
  },
}
