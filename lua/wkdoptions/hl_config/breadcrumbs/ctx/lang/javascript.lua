---@module 'wkdoptions.hl_config.breadcrumbs.ctx.lang.javascript'
---@brief JavaScript/TypeScript context extraction
---
--- Handles:
---   - Object literals: const obj = { key: value }
---   - Classes: class User { method() {} }
---   - Member expressions: api.client.fetch()

local lazy = require("lib.lua.lazy")
local ts = lazy.require("..utils.ts_helpers")
local txt = lazy.require("..utils.text_utils")
local memo = lazy.require("lib.lua.memo")

local M = {}

-- Node type sets
local LITERAL_TYPES = {
  object = true,
  pair = true,
  property_identifier = true,
  shorthand_property_identifier = true,
}

local DECLARATION_TYPES = {
  variable_declarator = true,
  lexical_declaration = true,
  variable_declaration = true,
}

-----------------------------------------------------------
-- Literal Detection
-----------------------------------------------------------

---@param node TSNode|nil
---@nodiscard
function M.detect_literal_field(node)
  if not node then
    return false
  end

  if LITERAL_TYPES[node:type()] then
    return true
  end

  return ts.find_ancestor(node, { object = true }) ~= nil
end

-----------------------------------------------------------
-- Owner Extraction
-----------------------------------------------------------

--- Collect keys from nested object literal
---@nodiscard
local collect_keys = memo.fn(function(node)
  if not node then
    return {}
  end

  local keys = {}
  local current = node
  local depth = 0

  while current and depth < 10 do
    local t = current:type()

    if t == "pair" then
      local key_node = ts.field_node(current, "key")
      if key_node then
        local text = ts.node_text(key_node)
        local key = txt.unquote(text)
        if key and #key > 0 then
          table.insert(keys, 1, key)
        end
      end
    elseif t == "object" then
      -- Continue upward
    else
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

--- Find variable from declaration/assignment
---@nodiscard
local find_variable = memo.fn(function(node)
  if not node then
    return nil
  end

  local current = node
  local depth = 0

  while current and depth < 15 do
    local t = current:type()

    if DECLARATION_TYPES[t] then
      local name_node = ts.field_node(current, "name")
      if name_node then
        return ts.node_text(name_node)
      end
      break
    end

    -- Also check assignment_expression
    if t == "assignment_expression" then
      local left = ts.field_node(current, "left")
      if left then
        local text = ts.node_text(left)
        -- Clean: remove spaces and trailing =
        return text:gsub("%s+", ""):gsub("%s*=.*", "")
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

---@param node TSNode|nil
---@nodiscard
function M.extract_owner(node)
  if not node then
    return nil
  end

  local keys = collect_keys(node)
  local var = find_variable(node)

  if not var or var == "" then
    return nil
  end

  if #keys == 0 then
    return var
  end

  -- Build container (without last key)
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
-- Container Extraction
-----------------------------------------------------------

---@param node TSNode|nil
---@param max_depth integer|nil
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

    -- Class declaration
    if t == "class_declaration" then
      local name_node = ts.field_node(current, "name")
      if name_node then
        table.insert(chain, 1, ts.node_text(name_node))
      end
    end

    -- Method inside class
    if t == "method_definition" or t == "public_field_definition" then
      local class = ts.find_ancestor(current, { class_declaration = true })
      if class then
        local name_node = ts.field_node(class, "name")
        if name_node then
          table.insert(chain, 1, ts.node_text(name_node))
        end
      end
    end

    -- Member expression: obj.prop
    if t == "member_expression" then
      local full = ts.node_text(current)
      -- Extract left side
      local container = full:match("^(.-)%.([%w_$]+)%s*$")
      if container and #container > 0 then
        table.insert(chain, 1, container)
      end
    end

    -- Object literal
    if t == "object" then
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

  chain = txt.dedupe_consecutive(chain)
  return table.concat(chain, ".")
end

-----------------------------------------------------------
-- Base Extraction
-----------------------------------------------------------

---@param node TSNode|nil
---@nodiscard
function M.extract_base(node)
  if not node then
    return nil
  end

  local t = node:type()

  -- Method definition
  if t == "method_definition" then
    local name_node = ts.field_node(node, "name")
    if name_node then
      return ts.node_text(name_node) .. "()"
    end
  end

  -- Property/identifier
  if t == "property_identifier" or t == "identifier" or t == "shorthand_property_identifier" then
    return ts.node_text(node)
  end

  -- Pair key
  if t == "pair" then
    local key_node = ts.field_node(node, "key")
    if key_node then
      return txt.unquote(ts.node_text(key_node))
    end
  end

  return txt.extract_identifier(ts.node_text(node), "javascript")
end

---@type Breadcrumbs.LangModule
return M
