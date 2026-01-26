---@module 'config.neotree.open.window.controller.position'
---@brief Position normalization and validation

local notify = require("lib.notify").create("[config.neotree.open.window.controller.position]")

local M = {}

---@type table<string, true>
local VALID_POSITIONS = {
  left = true,
  right = true,
  float = true,
  current = true,
}

---Normalize position to valid value
---@param pos Cfg.NeoTree.Position
---@return Cfg.NeoTree.Position
function M.normalize(pos)
  if VALID_POSITIONS[pos] then
    return pos
  end

  local cfg = require("config.neotree").options
  if cfg.debug then
    notify.warn(string.format("[neo-tree] Invalid position '%s', using default", pos))
  end

  return require("config.neotree").get_default_position()
end

---Check if position is valid
---@param pos string
---@return boolean
function M.is_valid(pos)
  return VALID_POSITIONS[pos] == true
end

return M
