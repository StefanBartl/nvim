---@module 'plugins.colorscheme.tokyonight'

return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "storm", -- "storm" hat kräftigere Farben als "night"
    light_style = "day",
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      variables = {},
      sidebars = "dark",
      floats = "dark",
    },
    sidebars = { "qf", "help", "terminal" },
    day_brightness = 0.3,
    hide_inactive_statusline = false,
    dim_inactive = false,
    lualine_bold = true,

    -- WICHTIG: Farbanpassungen für mehr Intensität
    on_colors = function(colors)
      -- Intensivere Akzentfarben
      colors.blue = "#7aa2f7"    -- Statt default #7aa2f7
      colors.cyan = "#7dcfff"    -- Statt default #7dcfff
      colors.green = "#9ece6a"   -- Statt default #9ece6a
      colors.orange = "#ff9e64"  -- Statt default #ff9e64
      colors.purple = "#bb9af7"  -- Statt default #bb9af7
      colors.red = "#f7768e"     -- Statt default #f7768e
      colors.yellow = "#e0af68"  -- Statt default #e0af68
      colors.magenta = "#bb9af7" -- Zusätzlich
      colors.teal = "#1abc9c"    -- Zusätzlich
    end,

    on_highlights = function(hl, colors)
      -- Intensivere TODO-Comments
      hl.TodoBgFIX = { bg = colors.red, fg = colors.black, bold = true }
      hl.TodoFgFIX = { fg = colors.red, bold = true }
      hl.TodoSignFIX = { fg = colors.red, bold = true }

      hl.TodoBgTODO = { bg = colors.blue, fg = colors.black, bold = true }
      hl.TodoFgTODO = { fg = colors.blue, bold = true }
      hl.TodoSignTODO = { fg = colors.blue, bold = true }

      hl.TodoBgWARN = { bg = colors.orange, fg = colors.black, bold = true }
      hl.TodoFgWARN = { fg = colors.orange, bold = true }
      hl.TodoSignWARN = { fg = colors.orange, bold = true }

      hl.TodoBgNOTE = { bg = colors.green, fg = colors.black, bold = true }
      hl.TodoFgNOTE = { fg = colors.green, bold = true }
      hl.TodoSignNOTE = { fg = colors.green, bold = true }

      hl.TodoBgHACK = { bg = colors.purple, fg = colors.black, bold = true }
      hl.TodoFgHACK = { fg = colors.purple, bold = true }
      hl.TodoSignHACK = { fg = colors.purple, bold = true }

      hl.TodoBgPERF = { bg = colors.magenta, fg = colors.black, bold = true }
      hl.TodoFgPERF = { fg = colors.magenta, bold = true }
      hl.TodoSignPERF = { fg = colors.magenta, bold = true }
    end,
  },
}
