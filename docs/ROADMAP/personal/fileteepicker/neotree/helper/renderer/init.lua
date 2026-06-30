---@module 'config.neotree.helper.renderer'

local M = {}

--- Redraw Neo-tree UI for specific state
---@param state Cfg.NeoTree.State|nil Neo-tree state (optional, falls back to refresh command)
---@return nil
function M.redraw(state)
  if state then
    -- Try to use Neo-tree's internal renderer for the specific state
    local ok, renderer = pcall(require, "neo-tree.ui.renderer")
    if ok and renderer.redraw then
      pcall(renderer.redraw, state)
      return
    end
  end

  -- Fallback: global refresh
  vim.cmd("Neotree refresh")
end

return M
