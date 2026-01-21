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

---@class WkdNvC.UI.Stl.Modules.Highlighting
---@field stl_strip_hl fun(s: string): string
--- Entfernt eingebettete Statusline-Highlight-Sequenzen
--- ("%#Group#" und "%*") aus einem String.
--- Geeignet, um Inhalte anschließend erneut mit
--- eigenen Highlight-Gruppen zu wrappen.
---
---@field hl_open fun(group: string): string
--- Öffnet eine Statusline-Highlight-Gruppe ohne
--- abschließendes Reset ("%*").
--- Wird verwendet, wenn ein Highlight-Band über
--- mehrere Module hinweg fortgeführt werden soll.
---
---@field hl_wrap fun(group: string, s: string): string
--- Wrapped einen String vollständig in eine
--- Statusline-Highlight-Gruppe inklusive Reset.
--- Leere oder nil-Strings ergeben einen leeren Rückgabewert.
---
---@field mode_band_group fun(): string
--- Ermittelt die aktuelle Mode-Band-Highlight-Gruppe
--- basierend auf dem aktuellen Vim-Mode.
--- Rückgabeformat: "St_<Name>mode"
--- Beispiele: "St_Normalmode", "St_Insertmode".

-- Type Usage:
-- ---@type WkdNvC.UI.Stl.Modules.Highlighting
-- local hl_module = require("lib.lazy").require("wkdnvchad.ui.statusline.modules.highlighting")

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
