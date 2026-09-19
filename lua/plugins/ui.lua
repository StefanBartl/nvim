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
    -- `NoiceErrors`, Plural: noice builds its single commands from the keys
    -- of its command table, and that key is `errors`. `NoiceError` was a
    -- stub that no plugin command ever replaced -- it loaded noice, did
    -- nothing, and answered E492 on the second call.
    cmd = { "Noice", "NoiceAll", "NoiceHistory", "NoiceDismiss", "NoiceErrors" },
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

  {
    "MunifTanjim/nui.nvim",
  },

  -- `nvzone/minty` (and its `nvzone/volt` dependency) left on 2026-09-19:
  -- the right-click menu's "Color Picker" entry opens ui.nvim's
  -- `ui.colorpicker` now (`:UI color [#hex]`), a hue row + saturation x
  -- lightness grid + shades in a ui.kit float.

  -- Replaces `nvchad.colorify` -- the `require("nvchad.colorify").run()`
  -- call that used to live in `lua/nvchad/au.lua` is gone entirely, not
  -- merely guarded off, see that file's own comment in its place. Inline
  -- highlighting for hex codes, CSS colour functions and named colours.
  -- Standalone: colorify only ever ran because an nvconfig default said so,
  -- not because of any NvChad-specific code.
  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  -- Opt-in alternative to the entry above: richer per-match rendering
  -- (background/foreground/virtual text, chosen per filetype) plus its own
  -- toggle commands, at the cost of a second, heavier colorizer. Flip
  -- `enabled` on ONE of these two, never both -- running both double-
  -- highlights every match.
  -- {
  -- "brenoprata10/nvim-highlight-colors",
  -- enabled = false,
  -- cmd = { "HighlightColorsToggle", "HighlightColorsOn", "HighlightColorsOff" },
  -- opts = {},
  -- },
}
