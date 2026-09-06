---@module 'plugins.ui_icons'
--- Icon-provider plugin specs: nvim-web-devicons as the primary (NvChad's
--- own default).
---@type LazyPluginSpec[]

return {
  -- Primary: nvim-web-devicons (NvChad's default)
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      override = {},
      default = true,
      strict = true,
      override_by_filename = {},
      override_by_extension = {},
    },
  },

  -- Optional: mini.icons as fallback/alternative
  {
    "echasnovski/mini.icons",
    version = false,
    lazy = true,
    enabled = false, -- disabled, nvim-web-devicons is preferred
    config = function()
      require("mini.icons").setup({
        style = "glyph", -- or "ascii"
      })
    end,
  },

  -- Optional: mini.nvim collection (if other mini modules are used)
  {
    "echasnovski/mini.nvim",
    version = false,
    lazy = true,
    enabled = false, -- only enable if explicitly needed
  },
}
