---@meta
---@module 'wkdnvchad.ui.statusline.modules.highlighting.@types'

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
-- local hl_module = require("lib.lua.lazy").require("wkdnvchad.ui.statusline.modules.highlighting")

return {}
