---@module 'config.neotree.actions.traverse'
---@brief Bi-directional tree navigation for Neo-tree
---@description
--- Unified module for navigating up and down the directory hierarchy.
--- Handles CWD synchronization, tree root updates, and node selection.
---
--- Features:
--- - Navigate up one level (like cd ..)
--- - Navigate down to a directory node (set as new root)
--- - Smart CWD handling (window-local for float/current, global for sidebars)
--- - Automatic node selection after navigation
--- - Integration with cwd_sync pause mechanism
---
--- Usage:
---   local traverse = require("config.neotree.actions.traverse")
---   traverse.up(state)        -- Navigate to parent directory
---   traverse.down(state)      -- Navigate into selected directory node

local notify = require("lib.notify").create("[config.neotree.actions.traverse]")

local M = {}

local node_utils = require("config.neotree.utils.node")
local fn = vim.fn

---Pause CWD sync to prevent conflicts
---@param duration_ms integer Pause duration in milliseconds
---@return nil
local function pause_cwd_sync(duration_ms)
  local ok_sync, sync = pcall(require, "config.neotree.cwd_sync")
  if ok_sync and sync.pause_sync then
    sync.pause_sync(duration_ms)
  end
end

---Determine the appropriate cd command based on window position
---@param state Cfg.NeoTree.State
---@return string cd_command Either "lcd" or "cd"
local function get_cd_command(state)
  local position = (state.window and state.window.position)
    or require("config.neotree").get_default_position()

  -- Float/Current windows use window-local CWD to avoid global side-effects
  return (position == "current" or position == "float") and "lcd" or "cd"
end

---Change working directory safely
---@param dir string Target directory path
---@param cd_cmd string Either "lcd" or "cd"
---@return boolean success, string? error_msg
local function change_directory(dir, cd_cmd)
  local escaped = fn.fnameescape(dir)
  local ok, err = pcall(function()
    vim.cmd(string.format("%s %s", cd_cmd, escaped))
  end)

  if not ok then
    return false, tostring(err)
  end

  return true, nil
end

---Navigate the tree to a new root
---@param state Cfg.NeoTree.State
---@param target_dir string New root directory
---@return boolean success
local function navigate_tree(state, target_dir)
  -- Try Neo-tree's built-in navigation commands in priority order
  if state.commands and state.commands.navigate_up then
    state.commands.navigate_up(state)
    return true
  elseif state.commands and state.commands.set_root then
    state.commands.set_root(state, target_dir)
    return true
  else
    -- Fallback to manager.navigate
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if ok_mgr then
      manager.navigate(state, target_dir)
      return true
    end
  end

  return false
end

---Select a specific node in the tree after navigation
---@param state Cfg.NeoTree.State
---@param target_path string Path of node to select
---@param delay_ms? integer Delay before selection (default: 100)
---@return nil
local function select_node_deferred(state, target_path, delay_ms)
  delay_ms = delay_ms or 100

  vim.defer_fn(function()
    local tree = state.tree
    if not tree then return end

    local parent_node = state.current_node
    if not parent_node or not parent_node.children then return end

    for _, child in ipairs(parent_node.children) do
      local child_path, _ = node_utils.get_path(child)
      if child_path == target_path then
        if tree.set_selection then
          pcall(tree.set_selection, tree, child_path)
        end
        break
      end
    end
  end, delay_ms)
end

---Refresh the tree display
---@param state Cfg.NeoTree.State
---@return nil
local function refresh_tree(state)
  local ok_mod, refresher = pcall(require, "config.neotree.refresh_adapter")
  if ok_mod then
    refresher.refresh(state)
  end
end

---Navigate up one directory level
---@param state Cfg.NeoTree.State
---@return boolean success
function M.up(state)
  -- Pause CWD sync for 3 seconds to allow manual navigation
  pause_cwd_sync(3000)

  -- 1) Resolve current root directory
  local current_root = state.path
  if not current_root or current_root == "" then
    local tree = state.tree
    if not tree then
      notify.warn("No tree available")
      return false
    end

    local node = node_utils.get_current(state)
    if not node then
      notify.warn("No node under cursor")
      return false
    end

    local path, _ = node_utils.get_path(node)
    if path == "" then
      notify.warn("No path under cursor")
      return false
    end

    current_root = (fn.isdirectory(path) == 1) and path or fn.fnamemodify(path, ":h")
  end

  -- 2) Calculate parent directory
  local parent = fn.fnamemodify(current_root, ":h")
  if parent == current_root or parent == "" then
    notify.warn("Already at top-level directory")
    return false
  end

  -- 3) Change working directory
  local cd_cmd = get_cd_command(state)
  local ok, err = change_directory(parent, cd_cmd)
  if not ok then
    notify.error(("CWD change failed: %s"):format(err))
    return false
  end

  -- 4) Save old path for later selection
  local old_path = current_root

  -- 5) Navigate tree to parent
  local nav_ok = navigate_tree(state, parent)
  if not nav_ok then
    notify.error("Failed to navigate tree")
    return false
  end

  -- 6) Select the old directory in the new view
  select_node_deferred(state, old_path)

  -- 7) Refresh tree display
  refresh_tree(state)

  notify.info(("cwd → %s"):format(parent))
  return true
end

---Navigate down into a directory node (set as new root)
---@param state Cfg.NeoTree.State
---@return boolean success
function M.down(state)
  -- Pause CWD sync for 3 seconds
  pause_cwd_sync(3000)

  -- 1) Get current node
  local node = node_utils.get_current(state)
  if not node then
    notify.info("No node under cursor")
    return false
  end

  -- 2) Validate it's a directory
  local path, is_dir = node_utils.get_path(node)
  if path == "" then
    notify.warn("No path under cursor")
    return false
  end

  local target_dir = is_dir and path or fn.fnamemodify(path, ":h")

  -- 3) Change working directory
  local cd_cmd = get_cd_command(state)
  local ok, err = change_directory(target_dir, cd_cmd)
  if not ok then
    notify.error(("CWD change failed: %s"):format(err))
    return false
  end

  -- 4) Navigate tree and reveal
  local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
  if ok_cmd and neo_cmd then
    neo_cmd.execute({
      source = "filesystem",
      dir = target_dir,
      reveal = true
    })
  else
    local nav_ok = navigate_tree(state, target_dir)
    if not nav_ok then
      notify.error("Failed to navigate tree")
      return false
    end
  end

  -- 5) Refresh tree display
  refresh_tree(state)

  notify.info(("cwd → %s"):format(target_dir))
  return true
end

return M
