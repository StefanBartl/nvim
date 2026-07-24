---@module 'themes.vim_default'
--- Base46 theme approximating the classic Vim "default" look.
--- Goal: muted terminal-like palette, minimal contrast shifts, no fancy accents.
--- Notes:
---   * Designed for dark terminals; keep `termguicolors = false` for a true TTY vibe.
---   * Colors are intentionally conservative; Base46 integrations will inherit these.
---   * If you want the exact terminal palette, prefer the standalone colorscheme below.

---@class Base46Theme
local M = {}

-- Base30: UI + plugin accents (picked to be subtle and close to terminal defaults)
M.base_30 = {
  black = "#000000", -- bg
  darker_black = "#000000",
  black2 = "#0a0a0a",
  one_bg = "#111111",
  one_bg2 = "#171717",
  one_bg3 = "#1c1c1c",
  grey = "#6c6c6c",
  grey_fg = "#7a7a7a",
  grey_fg2 = "#8a8a8a",
  light_grey = "#999999",
  white = "#c0c0c0", -- fg-ish
  brighter_white = "#d0d0d0",

  -- Subdued ANSI-like accents
  red = "#ff5f5f",
  baby_pink = "#ff8787",
  pink = "#ff87af",
  green = "#87d787",
  vibrant_green = "#a8e0a8",
  blue = "#87afff",
  nord_blue = "#7aa2f7",
  yellow = "#ffd75f",
  sun = "#ffd787",
  purple = "#af87ff",
  dark_purple = "#9f7fff",
  teal = "#5fd7af",
  orange = "#ffaf5f",
  cyan = "#5fd7ff",

  statusline_bg = "#0f0f0f",
  lightbg = "#151515",
  pmenu_bg = "#1a1a1a",
  folder_bg = "#87afff",
  line = "#1a1a1a",
}

-- Base16: core fg/bg + syntax base (kept near a terminalish scheme)
M.base_16 = {
  base00 = "#000000", -- bg
  base01 = "#111111",
  base02 = "#1c1c1c",
  base03 = "#3a3a3a",
  base04 = "#6c6c6c",
  base05 = "#c0c0c0", -- fg
  base06 = "#cfcfcf",
  base07 = "#dfdfdf",
  base08 = "#ff5f5f", -- red
  base09 = "#ffaf5f", -- orange
  base0A = "#ffd75f", -- yellow
  base0B = "#87d787", -- green
  base0C = "#5fd7ff", -- cyan
  base0D = "#87afff", -- blue
  base0E = "#af87ff", -- purple
  base0F = "#ff8787", -- extra
}

M.type = "dark"

return M
