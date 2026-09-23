---@module 'plugins.ui'
--- UI enhancements for command-line, messages, and focused writing.

---@type LazyPluginSpec[]
return {
  -- `s1n7ax/nvim-window-picker` left on 2026-09-19: ui.nvim's `ui.windowpicker`
  -- is the primitive now (external-plugins report, the window-picker item).
  -- neo-tree's own `open_with_window_picker` (`<CR>` in filesystem/files.lua,
  -- the `W` keymap) needed no changes at all -- it does
  -- `pcall(require, "window-picker")` internally, and ui.nvim ships a
  -- `require("window-picker")` compatibility shim (`lua/window-picker/`)
  -- that delegates to `ui.windowpicker` for exactly that. Same
  -- `filter_rules` this spec used to pass, carried over as
  -- `ui.windowpicker`'s own shipped defaults.

  -- `kevinhwang91/nvim-bqf` left on 2026-09-19: the quickfix window's preview
  -- float and in-list filter are pickers.nvim's `quickfix` module now (on by
  -- default: `zf` refine, `zF` restore, `p` preview on/off in the list).

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

  -- `folke/zen-mode.nvim` (`:ZenMode`, pure defaults) left on 2026-09-19:
  -- ui.nvim's `ui.zen` is the distraction-free box now -- `:UI zen [on|off]`.

  {
    "MunifTanjim/nui.nvim",
  },

  -- `nvzone/minty` (and its `nvzone/volt` dependency) left on 2026-09-19:
  -- the right-click menu's "Color Picker" entry opens ui.nvim's
  -- `ui.colorpicker` now (`:UI color [#hex]`), a hue row + saturation x
  -- lightness grid + shades in a ui.kit float.

  -- Inline colour swatches (hex codes, CSS colour functions, named colours)
  -- were `catgoose/nvim-colorizer.lua` here, and `nvchad.colorify` before
  -- that. Since 2026-09-19 they are my.nvim's `hl_config.features.color_codes`
  -- (`highlight.color_codes`, on by default; `:My hl set color_codes.mode
  -- foreground|virtual` for the other renderings). Two colorizers would
  -- paint every match twice, so the plugin is gone rather than kept.
}
