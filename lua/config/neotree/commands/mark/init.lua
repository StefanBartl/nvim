---@module 'config.neotree.commands.mark'
--- Neo-tree marking commands: toggle mark on nodes for batch operations

local M = {}

local notify, levels = vim.notify, vim.log.levels

--- Toggle mark on the current node using Neo-tree's renderer
---@param state table
---@return nil
local function toggle_mark(state)
  local node = state.tree:get_node()
  if not node then
    notify("No node under cursor", levels.WARN)
    return
  end

  -- Use Neo-tree's built-in mark toggling via renderer
  local renderer = require("neo-tree.ui.renderer")

  -- Check if node is currently marked
  local marks = state.explicitly_marked_node_ids or {}
  local node_id = node:get_id()
  local is_marked = marks[node_id] ~= nil

  if is_marked then
    -- Unmark
    marks[node_id] = nil
    notify("✗ Unmarked: " .. (node.name or "node"), levels.INFO)
  else
    -- Mark
    marks[node_id] = true
    notify("✓ Marked: " .. (node.name or "node"), levels.INFO)
  end

  state.explicitly_marked_node_ids = marks

  -- Refresh the tree to show visual changes
  renderer.redraw(state)

  -- Move cursor down for quick multi-selection
  vim.schedule(function()
    vim.cmd("normal! j")
  end)
end

--- Clear all marks
---@param state table
---@return nil
local function clear_all_marks(state)
  if state.explicitly_marked_node_ids then
    state.explicitly_marked_node_ids = {}

    -- Refresh to update visuals
    local renderer = require("neo-tree.ui.renderer")
    renderer.redraw(state)

    notify("Cleared all marks", levels.INFO)
  else
    notify("No marks to clear", levels.INFO)
  end
end

--- Mark all nodes in current directory
---@param state table
---@return nil
local function mark_all_in_directory(state)
  local tree = state.tree
  if not tree then
    notify("No tree available", levels.WARN)
    return
  end

  local current_node = tree:get_node()
  if not current_node then
    return
  end

  -- Find parent directory
  local parent = current_node.type == "directory" and current_node or tree:get_node(current_node:get_parent_id())
  if not parent then
    return
  end

  -- Mark all children (files only)
  local marks = state.explicitly_marked_node_ids or {}
  local marked_count = 0

  if parent.children then
    for _, child in ipairs(parent.children) do
      if child.type ~= "directory" then
        local child_id = child:get_id()
        marks[child_id] = true
        marked_count = marked_count + 1
      end
    end
  end

  state.explicitly_marked_node_ids = marks

  -- Refresh to show visual changes
  local renderer = require("neo-tree.ui.renderer")
  renderer.redraw(state)

  notify(string.format("Marked %d files", marked_count), levels.INFO)
end

M.toggle_mark = toggle_mark
M.clear_all_marks = clear_all_marks
M.mark_all_in_directory = mark_all_in_directory

return M
