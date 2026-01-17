---@module 'config.neotree.commands.mark'
--- Neo-tree marking commands: toggle mark on nodes for batch operations

local notify = require("lib.notify").create("[neotree.commands.mark]")

local renderer = require("config.neotree.helper.renderer")
local node_utils = require("config.neotree.utils.node")

local M = {}

--- Toggle mark on the current node
---@param state Cfg.NeoTree.State
---@param auto_advance? boolean Move cursor down after marking (default: true)
---@return nil
function M.toggle_mark(state, auto_advance)
  if auto_advance == nil then
    auto_advance = true
  end

  local node = node_utils.get_current(state)
  if not node then
    notify.warn("no node under cursor")
    return
  end

  local node_id = node.id
  local marks = state.explicitly_marked_node_ids or {}
  local is_marked = marks[node_id] ~= nil

  if is_marked then
    marks[node_id] = nil
    notify.info("✗ Unmarked: " .. (node.name or "<unknown>"))
  else
    marks[node_id] = true
    notify.info("✓ Marked: " .. (node.name or "<unknown>"))
  end

  state.explicitly_marked_node_ids = marks
  renderer.redraw(state)

  -- Move cursor down for multi-selection convenience
  if auto_advance then
    vim.schedule(function()
      vim.cmd("normal! j")
    end)
  end
end

--- Clear all marks
---@param state Cfg.NeoTree.State
---@return nil
function M.clear_all_marks(state)
  if state.explicitly_marked_node_ids then
    state.explicitly_marked_node_ids = {}

    -- Refresh to update visuals
    renderer.redraw(state)

    notify.info("Cleared all marks")
  else
    notify.info("No marks to clear")
  end
end

--- Mark all files in the current directory node
---@param state Cfg.NeoTree.State
---@return nil
function M.mark_all_in_directory(state)
  local tree = state.tree
  if not tree then
    notify.warn("No tree available")
    return
  end

  local current_node = tree:get_node()
  if not current_node then
    notify.warn("No node under cursor")
    return
  end

  -- Find parent directory
  local parent = current_node.type == "directory" and current_node
                 or tree:get_node(current_node:get_parent_id())

  if not parent then
    notify.warn("No parent directory found")
    return
  end

  -- Get children using tree:get_nodes() instead of parent.children
  ---@diagnostic disable-next-line: undefined-field
  local children = tree:get_nodes(parent:get_id())

  if not children or #children == 0 then
    notify.warn("Directory is empty")
    return
  end

  -- Mark all children (files only)
  local marks = state.explicitly_marked_node_ids or {}
  local count = 0

  for _, child in ipairs(children) do
    if child.type ~= "directory" then
      marks[child.id] = true
      count = count + 1
    end
  end

  state.explicitly_marked_node_ids = marks
  renderer.redraw(state)
  notify.info(string.format("Marked %d files", count))
end

--- Unmark all files in the current directory node
---@param state Cfg.NeoTree.State
---@return nil
function M.unmark_all_in_directory(state)
  local tree = state.tree
  if not tree then
    notify.warn("No tree available")
    return
  end

  local current_node = tree:get_node()
  if not current_node then
    notify.warn("No node under cursor")
    return
  end

  -- Find parent directory
  local parent = current_node.type == "directory" and current_node
                 or tree:get_node(current_node:get_parent_id())

  if not parent then
    notify.warn("No parent directory found")
    return
  end

  -- Get children using tree:get_nodes()
  local children = tree:get_nodes(parent:get_id())

  if not children or #children == 0 then
    notify.warn("Directory is empty")
    return
  end

  -- Unmark all children (files only)
  local marks = state.explicitly_marked_node_ids or {}
  local count = 0

  for _, child in ipairs(children) do
    if child.type ~= "directory" and marks[child.id] then
      marks[child.id] = nil
      count = count + 1
    end
  end

  state.explicitly_marked_node_ids = marks
  renderer.redraw(state)
  notify.info(string.format("Unmarked %d files", count))
end

return M
