---@module 'config.neotree.state.tree'
---@brief Stores last cursor position and expanded nodes with batch operations

local M = {}

---@type Cfg.NeoTree.Tree
local state = {
  node_id = nil,
  expanded = {},
}

function M.set_expanded(ids)
  state.expanded = ids or {}
end

function M.get_expanded()
  return state.expanded
end

function M.set_node(node_id)
  state.node_id = node_id
end

function M.get_node()
  return state.node_id
end

function M.reset()
  state.node_id = nil
  state.expanded = {}
end

function M.capture_state(neo_state)
  if not neo_state or not neo_state.tree then
    return false
  end

  local tree = neo_state.tree

  local node = tree:get_node()
  if node then
    state.node_id = node.id
  end

  local expanded = {}
  if tree.nodes then
    for id, _node in pairs(tree.nodes) do
      if _node.is_expanded then
        expanded[id] = true
      end
    end
  end

  state.expanded = expanded
  return true
end

---PERFORMANCE: Batch restore with single tree operation
---@param tree table Neo-tree tree object
---@return boolean success
function M.restore_state(tree)
  if not tree then
    return false
  end

  -- PERFORMANCE: Collect all expand operations first
  local expand_nodes = {}
  for id, _ in pairs(state.expanded) do
    local node = tree:get_node(id)
    if node and node.type == "directory" then
      table.insert(expand_nodes, node)
    end
  end

  -- PERFORMANCE: Batch expand (if tree supports it)
  if tree.expand_batch then
    pcall(tree.expand_batch, tree, expand_nodes)
  else
    -- Fallback: Sequential expand
    for _, node in ipairs(expand_nodes) do
      pcall(tree.expand, tree, node)
    end
  end

  -- Restore cursor position
  if state.node_id then
    pcall(tree.set_selection, tree, state.node_id)
  end

  return true
end

return M
