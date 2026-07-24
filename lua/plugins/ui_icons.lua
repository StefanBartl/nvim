---@module 'plugins.ui_icons'
---@type LazyPluginSpec[]

return {
  -- Primary: nvim-web-devicons (Standard für NvChad)
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

  -- Optional: mini.icons als Fallback/Alternative
  {
    "echasnovski/mini.icons",
    version = false,
    lazy = true,
    enabled = false, -- Deaktiviert, da nvim-web-devicons bevorzugt wird
    config = function()
      require("mini.icons").setup({
        style = "glyph", -- oder "ascii"
      })
    end,
  },

  -- Optional: mini.nvim Sammlung (wenn andere mini-Module genutzt werden)
  {
    "echasnovski/mini.nvim",
    version = false,
    lazy = true,
    enabled = false, -- Nur aktivieren wenn explizit benötigt
  },
}
