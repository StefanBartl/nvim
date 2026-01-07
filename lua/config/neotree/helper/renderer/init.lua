---@module 'config.neotree.helper.renderer'
---AUDIT: Ist das genug ? funktinert dasd tatsächlich für: `lua\config\neotree\commands\mark\init.lua`

local M = {}

--- Redraw Neo-tree UI
function M.redraw()
  vim.cmd("Neotree refresh")
end

return M

