---@module 'config.neotree.utils'
---@brief Unified utilities for Neo-tree configuration

local M = {}

---Safe hide Neo-tree preview
---@return boolean success
function M.safe_hide_preview()
  local ok = pcall(function()
    local preview = require("neo-tree.sources.common.preview")
    if preview and preview.hide then
      preview.hide()
    end
  end)
  return ok
end

---@type Cfg.NeoTree.Utils.Module
return M
