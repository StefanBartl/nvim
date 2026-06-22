---@module 'wkdnvchad.ui.statusline.modules.highlighting'
-- =========================================================
-- Statusline Highlighting Utilities
--
-- Dieses Modul kapselt Hilfsfunktionen zum Arbeiten mit
-- Neovim-Statusline-Highlight-Sequenzen (%#Group#, %*).
-- Es ermöglicht das Entfernen bestehender Highlights,
-- das Öffnen und Wrappen von Highlight-Gruppen sowie
-- die Ermittlung der aktuellen Mode-Band-Gruppe
-- (z. B. Normal-, Insert-, Visual-Mode).
-- =========================================================

local M = {}

-- Cache for mode band groups
local mode_band_cache = nil
local last_mode = nil

---@nodiscard
--- Strip embedded statusline highlights
---@param s string
---@return string
function M.stl_strip_hl(s)
  -- Use lib.strings for replace operations
  local str = require("lib.lua.strings")
  s = str.replace_all(s, "%%#.-#", "")
  s = str.replace_all(s, "%%%*", "")
  return s
end

---@nodiscard
--- Open highlight group without reset
---@param group string
---@return string
function M.hl_open(group)
  return "%#" .. group .. "#"
end

---@nodiscard
--- Wrap payload with highlight group
---@param group string
---@param s string
---@return string
function M.hl_wrap(group, s)
  if not s or s == "" then
    return ""
  end
  return "%#" .. group .. "#" .. s .. "%*"
end

---@nodiscard
--- Get current mode band group with caching
---@return string
function M.mode_band_group()
  local ok_mode, mode_info = pcall(vim.api.nvim_get_mode)
  if not ok_mode or not mode_info or not mode_info.mode then
    return "St_Normalmode" -- Fallback
  end

  local m = mode_info.mode

  -- Return cached if mode unchanged
  if last_mode == m and mode_band_cache then
    return mode_band_cache
  end

  -- Update cache
  last_mode = m

  local ok_utils, utils = pcall(require, "nvchad.stl.utils")
  if not ok_utils then
    mode_band_cache = "St_Normalmode"
    return mode_band_cache
  end

  local name = (utils.modes[m] and utils.modes[m][2]) or "Normal"
  mode_band_cache = "St_" .. name .. "mode"

  return mode_band_cache
end

-- Clear cache on mode change
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("WkdNvChadHighlightCache", { clear = true }),
  callback = function()
    mode_band_cache = nil
    last_mode = nil
  end,
  desc = "Clear mode band cache on mode change"
})

return M
