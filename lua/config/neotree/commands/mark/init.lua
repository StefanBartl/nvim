---@module 'config.neotree.commands.mark'
--- Neo-tree marking commands: toggle mark on nodes for batch operations

local renderer = require("config.neotree.helper.renderer")
local node_utils = require("config.neotree.utils.node")

local M = {}

local notify, levels = vim.notify, vim.log.levels

--- Toggle mark on the current node
---@param state Cfg.NeoTree.State
---@return nil
function M.toggle_mark(state)
  local node = node_utils.get_current(state)
  if not node then
    notify("no node under cursor", levels.WARN)
    return
  end

  local node_id = node.id
  local marks = state.explicitly_marked_node_ids or {}
  local is_marked = marks[node_id] ~= nil

  if is_marked then
    marks[node_id] = nil
    notify("✗ Unmarked: " .. (node.name or "<unknown>"), levels.INFO)
  else
    marks[node_id] = true
    notify("✓ Marked: " .. (node.name or "<unknown>"), levels.INFO)
  end

  state.explicitly_marked_node_ids = marks
  renderer.redraw(state)

  -- Move cursor down for multi-selection convenience
  vim.schedule(function()
    vim.cmd("normal! j")
  end)
end

--- Clear all marks
---@param state Cfg.NeoTree.State
---@return nil
function M.clear_all_marks(state)
  if state.explicitly_marked_node_ids then
    state.explicitly_marked_node_ids = {}

    -- Refresh to update visuals
    renderer.redraw(state)

    notify("Cleared all marks", levels.INFO)
  else
    notify("No marks to clear", levels.INFO)
  end
end

--- Mark all files in the current directory node
---@param state Cfg.NeoTree.State
---@return nil
function M.mark_all_in_directory(state)
  local node = node_utils.get_current(state)
  if not node then
    notify("no node under cursor", levels.WARN)
    return
  end

  -- Determine parent directory
  local parent = node.type == "directory" and node or node.parent
  if not parent or not parent.children then
    return
  end

  local marks = state.explicitly_marked_node_ids or {}
  local count = 0

  for _, child in ipairs(parent.children) do
    if child.type ~= "directory" then
      marks[child.id] = true
      count = count + 1
    end
  end

  state.explicitly_marked_node_ids = marks
  renderer.redraw()

  notify(string.format("Marked %d files", count), levels.INFO)
end

return M
