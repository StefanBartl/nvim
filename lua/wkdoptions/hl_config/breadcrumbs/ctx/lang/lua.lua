---@module 'wkdoptions.hl_config.breadcrumbs.ctx.lang.lua'
---@brief Lua-specific context extraction
---
--- Handles:
---   - Table constructors: M = { key = value }
---   - Nested tables: M = { Util = { fn = ... } }
---   - Dot/method index: obj.field, obj:method()
---   - Function declarations: function M.run() / M:run()

local lazy = require("lib.lazy")
local ts = lazy.require("..utils.ts_helpers")
local txt = lazy.require("..utils.text_utils")
local memo = lazy.require("lib.memo")

local M = {}

-- Node type sets for O(1) lookup
local LITERAL_TYPES = {
  table_constructor = true,
  field = true,
  pair = true,
}

local DECLARATION_TYPES = {
  local_statement = true,
  local_declaration = true,
  assignment = true,
  variable_declaration = true,
}

-----------------------------------------------------------
-- Literal Detection
-----------------------------------------------------------

---@nodiscard
function M.detect_literal_field(node)
  if not node then
    return false
  end

  -- Direct type check
  if LITERAL_TYPES[node:type()] then
    return true
  end

  -- Check if inside table_constructor
  return ts.find_ancestor(node, { table_constructor = true }) ~= nil
end

-----------------------------------------------------------
-- Owner Extraction (from literals)
-----------------------------------------------------------

--- Collect field key chain inside table constructor
--- Returns keys in order (outer → inner)
---@nodiscard
local collect_keys = memo.fn(function(node)
  if not node then
    return {}
  end

  local keys = {}
  local current = node
  local depth = 0
  local MAX_DEPTH = 10

  while current and depth < MAX_DEPTH do
    local t = current:type()

    if t == "field" or t == "pair" then
      local text = ts.node_text(current)
      local key = txt.extract_lua_field_key(text)

      if key and #key > 0 then
        table.insert(keys, 1, key) -- Insert at front
      end
    elseif t == "table_constructor" then
      -- Continue upward
    else
      -- Stop at non-table node
      break
    end

    local parent = current:parent()
    if not parent or parent == current then
      break
    end

    current = parent
    depth = depth + 1
  end

  return keys
end, { weak = "k", size = 32 })

--- Find variable name from assignment/declaration
---@nodiscard
local find_variable = memo.fn(function(node)
  if not node then
    return nil
  end

  local current = node
  local depth = 0
  local MAX_DEPTH = 15

  while current and depth < MAX_DEPTH do
    local t = current:type()

    if DECLARATION_TYPES[t] then
      -- Try to get left side / variables field
      local left = ts.field_node(current, "left") or ts.field_node(current, "variables")

      if left then
        local text = ts.node_text(left)
        -- Clean up: "local M" → "M", "M, N" → "M"
        local var = text:match("^%s*local%s+([%w_]+)") or text:match("^%s*([%w_]+)")

        if var and #var > 0 then
          return var
        end
      end

      break
    end

    local parent = current:parent()
    if not parent or parent == current then
      break
    end

    current = parent
    depth = depth + 1
  end

  return nil
end, { weak = "k", size = 32 })

---@nodiscard
function M.extract_owner(node)
  if not node then
    return nil
  end

  local keys = collect_keys(node)
  local var = find_variable(node)

  -- No variable found
  if not var or var == "" then
    return nil
  end

  -- No keys: just return variable
  if #keys == 0 then
    return var
  end

  -- Build: M.key1.key2 (without last key - that's the current field)
  local container_keys = {}
  for i = 1, #keys - 1 do
    container_keys[i] = keys[i]
  end

  if #container_keys == 0 then
    return var
  end

  return var .. "." .. table.concat(container_keys, ".")
end

-----------------------------------------------------------
-- Container Extraction (from index expressions)
-----------------------------------------------------------

---@nodiscard
function M.extract_container(node, max_depth)
  if not node then
    return nil
  end

  max_depth = max_depth or 2
  local chain = {}

  local current = node
  local depth = 0

  while current and depth < max_depth do
    local t = current:type()

    -- Function declaration: function M.run()
    if t == "function_declaration" or t == "function_definition" then
      local name_node = ts.field_node(current, "name")
      if name_node then
        local full = ts.node_text(name_node) -- "M.run" or "M:run"
        -- Extract container: M.run → M
        local container = full:match("^(.+)[%.:]([%w_]+)$")
        if container and #container > 0 then
          table.insert(chain, 1, container)
        end
      end
    end

    -- Dot/method index: obj.field, obj:method
    if t == "dot_index_expression" or t == "method_index_expression" then
      local full = ts.node_text(current)
      -- Extract left side: obj.field → obj
      local container = full:match("^(.+)[%.:]([%w_]+)$")
      if container and #container > 0 then
        table.insert(chain, 1, container)
      end
    end

    -- Also check for table literal owner
    if t == "table_constructor" then
      local owner = find_variable(current)
      if owner then
        table.insert(chain, 1, owner)
      end
    end

    local parent = current:parent()
    if not parent or parent == current then
      break
    end

    current = parent
    depth = depth + 1
  end

  if #chain == 0 then
    return nil
  end

  -- Deduplicate consecutive segments
  chain = txt.dedupe_consecutive(chain)

  return table.concat(chain, ".")
end

-----------------------------------------------------------
-- Base Identifier (fallback)
-----------------------------------------------------------

---@nodiscard
function M.extract_base(node)
  if not node then
    return nil
  end

  local t = node:type()

  -- Field/pair in table
  if t == "field" or t == "pair" then
    local text = ts.node_text(node)
    local key = txt.extract_lua_field_key(text)
    if key and #key > 0 then
      return key
    end
  end

  -- Function declaration
  if t == "function_declaration" or t == "function_definition" then
    local name_node = ts.field_node(node, "name")
    if name_node then
      local full = ts.node_text(name_node)
      -- Extract just the method name: M.run → run()
      local base = full:match("[%.:]([%w_]+)$") or full
      if base and #base > 0 then
        return base .. "()"
      end
    end
  end

  -- Plain identifier
  if t == "identifier" or t == "name" then
    local text = ts.node_text(node)
    if text and #text > 0 then
      return text
    end
  end

  -- Fallback: use text utils
  return txt.extract_identifier(ts.node_text(node), "lua")
end

---@type Breadcrumbs.LangModule
return M
