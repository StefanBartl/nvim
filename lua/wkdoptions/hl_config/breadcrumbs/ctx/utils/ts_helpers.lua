---@module 'wkdoptions.hl_config.breadcrumbs.ctx.utils.ts_helpers'
---@brief TreeSitter utilities with memoization and pre-compiled patterns
---
--- Performance optimizations:
---   - node_text: memoized by node pointer (weak-key cache)
---   - find_ancestor: memoized by (node, type_set) pair
---   - node_at_cursor: cached per vim.fn.getcurpos() hash
---   - Pre-compiled TS queries stored in bytecode cache

local lazy = require("lib.lazy")
local memo = lazy.require("lib.memo")

local M = {}

-- Pre-compiled pattern cache (persists across calls)
---@type table<string, Breadcrumbs.TSPattern>
local PATTERN_CACHE = {}

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
-- Pre-compiled Pattern System
-----------------------------------------------------------

--- Compile and cache TS query pattern
--- Patterns are stored with language+pattern hash for fast lookup
---@nodiscard
---@param lang string # Language name (e.g., "lua", "javascript")
---@param pattern string # TreeSitter query pattern
---@return Breadcrumbs.TSPattern|nil
function M.compile_pattern(lang, pattern)
  if type(lang) ~= "string" or type(pattern) ~= "string" then
    return nil
  end

  -- Generate cache key
  local cache_key = lang .. ":" .. vim.fn.sha256(pattern):sub(1, 16)

  -- Check cache
  if PATTERN_CACHE[cache_key] then
    return PATTERN_CACHE[cache_key]
  end

  -- Compile query
  local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, lang)
  if not ok_parser or not parser then
    return nil
  end

  local ok_query, query = pcall(vim.treesitter.query.parse, lang, pattern)
  if not ok_query or not query then
    return nil
  end

  -- Store in cache
  local compiled = {
    query = query,
    cache_key = cache_key,
  }

  PATTERN_CACHE[cache_key] = compiled
  return compiled
end

--- Execute pre-compiled pattern on node
--- Returns first capture or nil
---@nodiscard
---@param pattern Breadcrumbs.TSPattern
---@param node TSNode
---@return TSNode|nil
function M.exec_pattern(pattern, node)
  if not pattern or not node then
    return nil
  end

  local ok, iter = pcall(pattern.query.iter_captures, pattern.query, node, 0)
  if not ok then
    return nil
  end

  -- Return first capture
  for id, capture_node in iter do
    if capture_node then
      return capture_node
    end
  end

  return nil
end

-----------------------------------------------------------
-- Common Pattern Presets (Lazy-compiled on first use)
-----------------------------------------------------------

local PRESETS = {}

--- Get or compile preset pattern
---@nodiscard
---@param lang string
---@param preset_name string
---@return Breadcrumbs.TSPattern|nil
function M.get_preset(lang, preset_name)
  local key = lang .. ":" .. preset_name

  if PRESETS[key] then
    return PRESETS[key]
  end

  -- Define presets per language
  local patterns = {
    lua = {
      function_name = [[
        (function_declaration
          name: (dot_index_expression) @name)
        (function_declaration
          name: (identifier) @name)
      ]],
      table_field = [[
        (field
          name: (identifier) @name)
      ]],
    },
    javascript = {
      method_name = [[
        (method_definition
          name: (property_identifier) @name)
      ]],
      class_name = [[
        (class_declaration
          name: (identifier) @name)
      ]],
    },
  }

  local lang_patterns = patterns[lang]
  if not lang_patterns then
    return nil
  end

  local pattern_str = lang_patterns[preset_name]
  if not pattern_str then
    return nil
  end

  local compiled = M.compile_pattern(lang, pattern_str)
  PRESETS[key] = compiled
  return compiled
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

--- Clear all caches (for testing/debugging)
---@return nil
function M.clear_caches()
  -- Clear memoized caches (via lib.memo)
  -- Note: lib.memo doesn't expose clear API, so we rely on weak tables

  -- Clear tick cache
  TICK_CACHE.pos = nil
  TICK_CACHE.node = nil

  -- Keep pattern cache (expensive to rebuild)
end

--- Invalidate tick cache (call on BufEnter/CursorMoved)
---@return nil
function M.invalidate_tick()
  TICK_CACHE.pos = nil
  TICK_CACHE.node = nil
end

return M
