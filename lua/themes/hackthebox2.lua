---@module 'custom.themes.hackthebox2'

---@class ThemeColors
local M = {}

-- Base30: Main colores for UI-Elements in NvChad
M.base_30 = {
  white          = "#a4b1cd",
  black          = "#1a2332", -- bg
  darker_black   = "#131b28",
  black2         = "#202a3a",
  one_bg         = "#313f55",
  one_bg2        = "#2e384a",
  one_bg3        = "#3a4559",

  grey           = "#495469",
  grey_fg        = "#58647a",
  grey_fg2       = "#646f85",
  light_grey     = "#7b869c",

  red            = "#ff3e3e",
  baby_pink      = "#ff8484",
  pink           = "#ff7edb",

  green          = "#9fef00",
  vibrant_green  = "#c5f467",

  blue           = "#004cff",
  nord_blue      = "#5cb2ff",

  yellow         = "#ffaf00",
  sun            = "#ffcc5c",

  purple         = "#9f00ff",
  dark_purple    = "#c16cfa",

  teal           = "#2ee7b6",
  cyan           = "#5cecc6",

  statusline_bg  = "#1f293a",
  lightbg        = "#2b3546",
  pmenu_bg       = "#9fef00", -- Popup-bg
  folder_bg      = "#004cff", -- NvimTree folder
}

-- Base16: Standard-Colorpalette for terminal, Treesitter, etc.
M.base_16 = {
  base00 = "#1a2332", -- bg
  base01 = "#202a3a",
  base02 = "#313f55", -- Selection bg
  base03 = "#3a4559",
  base04 = "#646f85",
  base05 = "#a4b1cd", -- Standardtext
  base06 = "#c8d1e1",
  base07 = "#ffffff",
  base08 = "#ff3e3e", -- Red
  base09 = "#ffaf00", -- Orange/Yellow
  base0A = "#ffcc5c", -- Yellow
  base0B = "#9fef00", -- Green
  base0C = "#2ee7b6", -- Cyan
  base0D = "#004cff", -- Blue
  base0E = "#9f00ff", -- Magenta
  base0F = "#c16cfa", -- Bright Magenta
}

M.type = "dark"

return M


