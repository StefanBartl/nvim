---@module 'config.neotree.state.tree'
---@brief Stores last cursor position and expanded nodes in neo-tree

local M = {}

---@class NeoTreeTreeState
---@field node_id string|nil Last focused node ID
---@field expanded table<string, true> Set of expanded node IDs

---@type NeoTreeTreeState
local state = {
  node_id = nil,
  expanded = {},
}

--- Set the list of currently expanded nodes
---@param ids table<string, true>|nil Map of node_id -> true for expanded nodes
---@return nil
function M.set_expanded(ids)
  state.expanded = ids or {}
end

--- Get the set of currently expanded nodes
---@return table<string, true>
function M.get_expanded()
  return state.expanded
end

--- Set the last focused node ID
---@param node_id string|nil
---@return nil
function M.set_node(node_id)
  state.node_id = node_id
end

--- Get the last focused node ID
---@return string|nil
function M.get_node()
  return state.node_id
end

--- Reset all state (used when closing neo-tree)
---@return nil
function M.reset()
  state.node_id = nil
  state.expanded = {}
end

--- Capture current neo-tree state from a neo-tree state object
---@param neo_state table Neo-tree internal state
---@return boolean success
function M.capture_state(neo_state)
  if not neo_state or not neo_state.tree then
    return false
  end

  local tree = neo_state.tree

  -- Capture current node
  local node = tree:get_node()
  if node then
    state.node_id = node.id
  end

  -- Capture expanded nodes
  local expanded = {}
  if tree.nodes then
    for id, _ in pairs(tree.nodes) do
      if node.is_expanded then
        expanded[id] = true
      end
    end
  end

  state.expanded = expanded
  return true
end

--- Restore state to a neo-tree tree object
---@param tree table Neo-tree tree object
---@return boolean success
function M.restore_state(tree)
  if not tree then
    return false
  end

  -- Restore expanded nodes
  for id, _ in pairs(state.expanded) do
    local node = tree:get_node(id)
    if node and node.type == "directory" then
      pcall(function()
        tree:expand(node)
      end)
    end
  end

  -- Restore cursor position
  if state.node_id then
    pcall(function()
      tree:set_selection(state.node_id)
    end)
  end

  return true
end

return M
