---@module 'wkdnvchad.ui.statusline.modules.highlighting'
-------------------------------------
-- MODULES HIGHLIGHTING
-------------------------------------

local M = {}

-- Strip embedded statusline highlights like "%#Group#" / "%*" to allow re-wrapping with our own group.
---@nodiscard
---@param s string
---@return string
function M.stl_strip_hl(s)
  return (s:gsub("%%#.-#", ""):gsub("%%%*", ""))
end

-- Open a highlight group without resetting at the end.
-- Use this when you want the band to keep filling the center area up to the next module.
---@nodiscard
---@param group string
---@return string
function M.hl_open(group)
  return "%#" .. group .. "#"
end

-- Wrap payload with a statusline highlight group.
---@nodiscard
---@param group string
---@param s string
---@return string
function M.hl_wrap(group, s)
  if not s or s == "" then
    return ""
  end
  return "%#" .. group .. "#" .. s .. "%*"
end

-- Compute current "mode band" highlight group, e.g. "St_Normalmode", "St_Insertmode", ...
-- Use this to wrap other modules so they visually match the mode/git band.
function M.mode_band_group()
  local utils = require("nvchad.stl.utils")
  local m = vim.api.nvim_get_mode().mode
  local name = (utils.modes[m] and utils.modes[m][2]) or "Normal"
  return "St_" .. name .. "mode"
end

return M
