
---@module 'custom.utils.toggle_transparency'

local M = {}

-- globaler Schalter
vim.g.transparency = true

-- Funktion zum (De-)Aktivieren
function M.toggle()
  vim.g.transparency = not vim.g.transparency
  require("base46").load_all_highlights() -- zwingt Theme-Neuladung
end

return M
