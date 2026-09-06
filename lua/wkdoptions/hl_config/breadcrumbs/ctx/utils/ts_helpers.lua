---@module 'wkdoptions.hl_config.breadcrumbs.ctx.utils.ts_helpers'
---@brief TreeSitter node helpers with memoization.
---
--- node_text / find_ancestor are memoized by node pointer; node_at_cursor is
--- cached per cursor position and reused until the cursor moves.

local lazy = require("lib.lua.lazy")
local memo = lazy.require("lib.lua.memo")

local M = {}

-- Current tick cache (invalidated per cursor move)
local TICK_CACHE = {
  pos = nil, ---@type any
  node = nil, ---@type TSNode|nil
}

-----------------------------------------------------------
-- Core Helpers
-----------------------------------------------------------

--- Safe text extraction from TS node (memoized)
--- Returns empty string on error instead of nil for consistent behavior
---@nodiscard
M.node_text = memo.fn(function(node)
  if not node then
    return ""
  end

  local ok, text = pcall(vim.treesitter.get_node_text, node, 0)
  return ok and (text or "") or ""
end, { weak = "k", size = 128 })

--- Find first ancestor matching type set (memoized)
--- Type set: { type_name = true, ... } for O(1) lookup
---@nodiscard
M.find_ancestor = memo.fn(function(node, type_set)
  if not node or type(type_set) ~= "table" then
    return nil
  end

  local current = node
  local depth = 0
  local MAX_DEPTH = 20 -- Safety limit

  while current and depth < MAX_DEPTH do
    if type_set[current:type()] then
      return current
    end

    local parent = current:parent()
    if not parent or parent == current then
      break
    end

    current = parent
    depth = depth + 1
  end

  return nil
end, { weak = "kv", size = 64 })

--- Get node at cursor (cached per cursor position)
--- Invalidates when cursor moves to avoid stale data
---@nodiscard
function M.node_at_cursor()
  -- Check if cursor moved
  local pos = vim.fn.getcurpos()
  if TICK_CACHE.pos and vim.deep_equal(TICK_CACHE.pos, pos) then
    return TICK_CACHE.node
  end

  -- Update cache
  TICK_CACHE.pos = pos

  local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
  if not ok_utils then
    TICK_CACHE.node = nil
    return nil
  end

  local ok_node, node = pcall(tsu.get_node_at_cursor)
  TICK_CACHE.node = ok_node and node or nil
  return TICK_CACHE.node
end

-----------------------------------------------------------
-- Utility: Safe field access
-----------------------------------------------------------

--- Get first node from field (safe)
---@nodiscard
---@param node TSNode|nil
---@param field_name string
---@return TSNode|nil
function M.field_node(node, field_name)
  if not node or type(field_name) ~= "string" then
    return nil
  end

  local ok, field = pcall(node.field, node, field_name)
  if not ok or not field or type(field) ~= "table" then
    return nil
  end

  return field[1]
end

-----------------------------------------------------------
-- Cache Management
-----------------------------------------------------------

--- Invalidate tick cache (call on BufEnter/CursorMoved)
---@return nil
function M.invalidate_tick()
  TICK_CACHE.pos = nil
  TICK_CACHE.node = nil
end

return M
