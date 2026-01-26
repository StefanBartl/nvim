---@module 'wkdoptions.hl_config.breadcrumbs.ctx.providers.ts_symbol'
---@brief TreeSitter semantic symbol provider
---
--- Builds symbol chains like: Class → method()
--- Priority: 80

local lazy = require("lib.lazy")
local ts = lazy.require("wkdoptions.hl_config.breadcrumbs.ctx.utils.ts_helpers")
local memo = lazy.require("lib.memo")

local M = {}

-- Semantic container types to keep in chain
local KEEP_TYPES = {
  function_declaration = true,
  function_definition = true,
  method_declaration = true,
  method_definition = true,
  class_declaration = true,
  class_specifier = true,
  struct_specifier = true,
  interface_declaration = true,
  module_declaration = true,
  namespace_definition = true,
  impl_item = true,
}

--- Extract identifier from node
---@nodiscard
local function extract_identifier(node)
  -- Try name field first
  local name_field = ts.field_node(node, "name")
  if name_field then
    local text = ts.node_text(name_field)
    if text and #text > 0 then
      return text
    end
  end

  -- Fallback: search for identifier-like children
  local want = {
    identifier = true,
    property_identifier = true,
    field_identifier = true,
    type_identifier = true,
    name = true,
  }

  local function find_ident(n, depth)
    depth = depth or 0
    if depth > 2 then
      return nil
    end

    if want[n:type()] then
      local text = ts.node_text(n)
      if text and #text > 0 then
        return text
      end
    end

    local cnt = n:child_count()
    for i = 0, cnt - 1 do
      local result = find_ident(n:child(i), depth + 1)
      if result then
        return result
      end
    end

    return nil
  end

  return find_ident(node, 0)
end

--- Build symbol chain (memoized)
---@nodiscard
local collect_chain = memo.fn(function(node)
  if not node then
    return {}
  end

  local names = {}
  local current = node
  local depth = 0
  local MAX_DEPTH = 20

  while current and depth < MAX_DEPTH do
    local t = current:type()

    if KEEP_TYPES[t] then
      local ident = extract_identifier(current)

      if ident and #ident > 0 then
        -- Add () for function-like nodes
        if t:find("function") or t:find("method") then
          if not ident:find("%)$") then
            ident = ident:gsub("%s+$", "") .. "()"
          end
        end

        table.insert(names, 1, ident) -- Insert at front
      end
    end

    local parent = current:parent()
    if not parent or parent == current then
      break
    end

    current = parent
    depth = depth + 1
  end

  return names
end, { weak = "k", size = 64 })

---@nodiscard
function M.enabled(cfg)
  return cfg.use_treesitter_symbol == true
end

---@nodiscard
function M.extract(node, cfg)
  if not node then
    return nil
  end

  -- Check if TS is available
  local ok_ts = pcall(require, "vim.treesitter")
  if not ok_ts then
    return nil
  end

  -- Check literal preference
  if cfg.prefer_owner_in_literals then
    local ft = vim.bo.filetype
    local ok_lang, lang = pcall(
      require,
      "wkdoptions.hl_config.breadcrumbs.ctx.lang." .. ft
    )

    if ok_lang and type(lang.detect_literal_field) == "function" then
      if lang.detect_literal_field(node) then
        return nil -- Skip literals
      end
    end
  end

  -- Build chain
  local names = collect_chain(node)

  if #names == 0 then
    return nil
  end

  return table.concat(names, " → ")
end

return M
