---@module 'custom.themes.hackthebox'

---@class ThemeColors
local M = {}

-- Hauptfarben
M.base_30 = {
  white       = "#a4b1cd",
  darker_black= "#131b28",
  black       = "#1a2332", -- nvim bg
  black2      = "#202a3a",
  one_bg      = "#242e3e", -- StatusLine & Pmenu
  one_bg2     = "#2e384a",
  one_bg3     = "#3a4559",
  grey        = "#495469",
  grey_fg     = "#58647a",
  grey_fg2    = "#646f85",
  light_grey  = "#7b869c",
  red         = "#ff3e3e",
  baby_pink   = "#ff8484",
  pink        = "#ff7edb",
  line        = "#2e384a", -- für lines etc.
  green       = "#9fef00",
  vibrant_green = "#c5f467",
  blue        = "#004cff",
  nord_blue   = "#5cb2ff",
  yellow      = "#ffaf00",
  sun         = "#ffcc5c",
  purple      = "#9f00ff",
  dark_purple = "#c16cfa",
  teal        = "#2ee7b6",
  cyan        = "#5cecc6",
  statusline_bg = "#1f293a",
  lightbg     = "#2b3546",
  pmenu_bg    = "#9fef00",
  folder_bg   = "#004cff",
}

-- Terminalfarben (optional)
M.base_16 = {
  base00 = "#1a2332",
  base01 = "#202a3a",
  base02 = "#242e3e",
  base03 = "#3a4559",
  base04 = "#646f85",
  base05 = "#a4b1cd",
  base06 = "#c8d1e1",
  base07 = "#ffffff",
  base08 = "#ff3e3e",
  base09 = "#ffaf00",
  base0A = "#ffcc5c",
  base0B = "#9fef00",
  base0C = "#2ee7b6",
  base0D = "#004cff",
  base0E = "#9f00ff",
  base0F = "#c16cfa",
}

-- Theme-Name
M.type = "dark"

M = require("base46").override_theme(M, "hackthebox")

return M
