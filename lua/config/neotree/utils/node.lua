---@module 'config.neotree.utils.node'
---@brief Neo-tree node extraction and collection utilities

local M = {}

---Get current node from state.tree (safe)
---@param state Cfg.NeoTree.State Neo-tree state
---@return Cfg.NeoTree.Node|nil node
function M.get_current(state)
  -- Validate state and tree presence
  local tree = state and state.tree
  if not tree then
    return nil
  end

  -- Resolve node from cursor position
  return tree:get_node()
end

---Get path from Neo-tree node
---@param node Cfg.NeoTree.Node|nil
---@return string path, boolean is_dir
function M.get_path(node)
  -- Early return if node is nil
  if not node then
    return "", false
  end

  -- Neo-tree nodes expose the path directly as a field
  local path = node.path or ""
  if path == "" then
    return "", false
  end

  -- Check whether the path points to a directory
  local is_dir = vim.fn.isdirectory(path) == 1
  return path, is_dir
end

---Collect nodes to operate on (marked nodes or current node)
---@param state Cfg.NeoTree.State Neo-tree state
---@return Cfg.NeoTree.Node[] nodes Array of nodes (may be empty)
function M.collect_nodes(state)
  local tree = state and state.tree
  if not tree then
    return {}
  end

  -- 1) Collect explicitly marked nodes
  local marks = state.explicitly_marked_node_ids or {}
  ---@type Cfg.NeoTree.Node[]
  local marked_nodes = {}

  for node_id, _ in pairs(marks) do
    -- Marked nodes must be resolved by id via the tree
    local node = tree:get_node(node_id)
    if node then
      table.insert(marked_nodes, node)
    end
  end

  if #marked_nodes > 0 then
    return marked_nodes
  end

  -- 2) Fallback: resolve current node via node_utils (never state.current_node)
  local node = M.get_current(state)
  if node then
    return { node }
  end

  return {}
end

---Extract paths from nodes
---@param nodes table[] Array of nodes
---@return string[] paths, string[] names
function M.extract_paths(nodes)
  local paths = {}
  local names = {}

  for i = 1, #nodes do
    local node = nodes[i]
    local path = node.path or node.uri or (node.get_id and node:get_id())
    if path then
      paths[#paths + 1] = path
      names[#names + 1] = node.name or vim.fn.fnamemodify(path, ":t")
    end
  end

  return paths, names
end

return M
