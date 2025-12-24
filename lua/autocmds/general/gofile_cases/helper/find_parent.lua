---@module 'autocmds.general.gofile_cases.helper.find_parent'
--- Helper: climb the treesitter AST to find the first parent node whose type is in `types`.
--- Returns the found node or nil.
--- Usage: local node = require('autocmds.general.gofile_cases.helper.find_parent')(start_node, { "link_destination" })

require("@tyoes.tsnode")

---@param node TSNode|nil
---@param types string[] list of node type names to match
---@return TSNode|nil
local function find_parent(node, types)
  -- Defensive: ensure `types` is a table to avoid runtime errors when misused.
  if type(types) ~= "table" then
    return nil
  end

  while node do
    -- Use pcall defensively to avoid runtime errors if the node does not implement expected methods.
    local ok_type, ntype = pcall(function() return node:type() end)
    if not ok_type or type(ntype) ~= "string" then
      -- If we cannot read the type, abort the climb safely.
      return nil
    end
    if vim.tbl_contains(types, ntype) then
      return node
    end
    local ok_parent, parent_node = pcall(function() return node:parent() end)
    if not ok_parent then
      return nil
    end
    node = parent_node
  end

  return nil
end

return find_parent
