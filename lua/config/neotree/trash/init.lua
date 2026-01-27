---@module 'config.neotree.trash'
---@brief Main orchestrator for Neo-tree trash functionality

local notify = require("lib.notify").create("[neotree.trash]")

-- Submodules
local platform = require("config.neotree.trash.platform")
local buffer_checker = require("config.neotree.trash.validation.buffer_checker")
local confirmation = require("config.neotree.trash.confirmation")
local operations = require("config.neotree.trash.operations")

-- Safety system
local safety = require("config.neotree.safety")
local watcher_quarantine = require("config.neotree.watcher_quarantine")

local M = {}

local fn = vim.fn
local defer_fn = vim.defer_fn
local str_format = string.format

---@type Cfg.NeoTree.Trash.Config
M.config = {
  use_safety_system = true,
  create_backups = true,
  confirm_dangerous = true,
  use_dry_run = true,
  auto_close_buffers = true,
  debug = true,
}

---Configure trash module
---@param config Cfg.NeoTree.Trash.Config|boolean|nil
function M.setup(config)
  if config then
    M.config = vim.tbl_deep_extend("force", M.config, config)
  end

  -- Pass config to submodules
  buffer_checker.set_config(M.config)
  operations.set_config(M.config)
end

---Debug notify helper
---@param msg string
local function debug_notify(msg)
  if M.config.debug then
    notify.info(msg)
  end
end

---Safely refresh Neo-tree
---@param state_name string
local function safe_refresh(state_name)
  watcher_quarantine.safe_refresh(state_name)
end

---Collect nodes to trash (marked or current)
---@param state Cfg.NeoTree.State
---@return Cfg.NeoTree.Node[] nodes
local function get_nodes_to_trash(state)
  if not state then
    return {}
  end

  local marks = state.explicitly_marked_node_ids or {}
  local nodes = {}

  -- CASE 1: Marked nodes exist
  if next(marks) then
    local tree = state.tree
    if tree and tree.get_node then
      for node_id, _ in pairs(marks) do
        local node = tree:get_node(node_id)
        if node then
          table.insert(nodes, node)
        end
      end
    end

    if #nodes > 0 then
      return nodes
    end
  end

  -- CASE 2: Current node (fallback)
  if state.tree and state.tree.get_node then
    local current = state.tree:get_node()
    if current then
      return { current }
    end
  end

  return {}
end

---Send single item to trash with all safety checks
---@param path string
---@param filename string
---@param ask_before_close boolean
---@return boolean success
---@return string message
---@return boolean user_cancelled
local function send_single_to_trash(path, filename, ask_before_close)
  filename = filename or fn.fnamemodify(path, ":t")

  -- STEP 1: Check and close buffers/previews FIRST (before validation)
  local has_refs, ref_info = buffer_checker.check_references(path)

  if has_refs then
    debug_notify(string.format("⚠ File '%s' has open references", filename))

    local closed, user_cancelled = buffer_checker.close_references(
      path,
      filename,
      ref_info,
      ask_before_close
    )

    if user_cancelled then
      return false, "user cancelled", true
    end

    if not closed then
      return false, "Could not close all references", false
    end

    -- Double-check after closure
    has_refs, ref_info = buffer_checker.check_references(path)
    if has_refs then
      notify.error(string.format(
        "❌ Still cannot delete '%s'\n%s\nPlease close manually or restart Neovim",
        filename,
        buffer_checker.format_remaining_references(ref_info)
      ))
      return false, "References still open", false
    end
  end

  -- STEP 2: Now validate (after buffers are closed)
  if M.config.use_safety_system then
    local valid, reason = safety.validation.validate_operation("delete", { path })
    if not valid then
      notify.error("Validation failed: " .. reason)
      return false, reason or "reason is nil", false
    end
  end

  -- STEP 3: Execute trash operation
  if not M.config.use_safety_system then
    local ok, msg = platform.send_to_trash(path)
    return ok, msg, false
  end

  -- With safety system
  local ok, msg = safety.safe_operation(function()
    watcher_quarantine.enter_quarantine(2000, { path })
    vim.wait(100)

    local success, err = platform.send_to_trash(path)

    if success then
      watcher_quarantine.safe_refresh("filesystem")
    end

    return success, err
  end, "delete", { path })

  return ok, msg or "msg is nil", false
end

---Main Neo-tree command: trash selected nodes
---@param state Cfg.NeoTree.State
function M.neotree_send_node_to_trash(state)
  local nodes = get_nodes_to_trash(state)

  if #nodes == 0 then
    notify.warn("No nodes selected")
    return
  end

  -- Collect paths and names
  local paths = {}
  local names = {}

  for i = 1, #nodes do
    local node = nodes[i]
    local path = node.path or node:get_id()
    if path then
      paths[#paths + 1] = path
      names[#names + 1] = node.name or fn.fnamemodify(path, ":t")
    end
  end

  if #paths == 0 then
    notify.warn("No valid paths found")
    return
  end

  -- Dry-run check
  if M.config.use_dry_run and safety.dry_run.enabled then
    safety.dry_run.log_operation("trash", {
      paths = paths,
      names = names,
      count = #paths,
    })
    notify.info(str_format("[DRY-RUN] Would trash %d items", #paths))
    return
  end

  -- Get confirmation mode
  local delete_mode = confirmation.get_confirmation_mode(names)
  if delete_mode == "cancel" then
    notify.info("ℹ️ Operation cancelled")
    return
  end

  ---@cast delete_mode Cfg.NeoTree.DeleteMode

  notify.info("Moving to Trash...")

  -- Create backups
  local backups_created = {}
  if M.config.create_backups then
    backups_created = operations.create_backups(paths, names)
  end

  -- Create recovery point
  if M.config.use_safety_system then
    safety.recovery.create_recovery_point("trash", paths, {
      backups = backups_created,
      names = names,
    })
  end

  -- Enter quarantine
  watcher_quarantine.enter_quarantine(2000, paths)

  -- Execute operations
  vim.schedule(function()
    defer_fn(function()
      local results = operations.execute_batch(
        paths,
        names,
        delete_mode,
        send_single_to_trash
      )

      -- Clear marks on success
      if results.success_count > 0 and state.explicitly_marked_node_ids then
        state.explicitly_marked_node_ids = {}
        pcall(function()
          local renderer = require("neo-tree.ui.renderer")
          renderer.redraw(state)
        end)
      end

      -- Refresh
      defer_fn(function()
        safe_refresh(state.name or "filesystem")
      end, 200)

      -- Final notifications
      operations.show_results(results, backups_created)
    end, 150)
  end)
end

---Toggle debug mode
function M.toggle_debug()
  M.config.debug = not M.config.debug
  buffer_checker.set_debug(M.config.debug)
  notify.info(str_format("Debug mode: %s", M.config.debug and "ENABLED" or "DISABLED"))
end

---Toggle dry-run
function M.toggle_dry_run()
  if safety.dry_run.enabled then
    safety.dry_run.disable()
  else
    safety.dry_run.enable()
  end
end

---Show statistics
function M.show_stats()
  local backups = safety.backup.list_backups()
  local recovery_points = safety.recovery.list_recovery_points()
  local queue_status = safety.queue.status()

  local stats = {
    "=== Neo-tree Trash Statistics ===",
    "",
    string.format("Safety System: %s", M.config.use_safety_system and "✓" or "✗"),
    string.format("Debug Mode: %s", M.config.debug and "✓" or "✗"),
    string.format("Auto-Close Buffers: %s", M.config.auto_close_buffers and "YES" or "NO"),
    string.format("Backups: %d", #backups),
    string.format("Recovery Points: %d", #recovery_points),
    string.format("Queue: %s", queue_status.processing and "PROCESSING" or "IDLE"),
    string.format("Dry-Run: %s", safety.dry_run.enabled and "✓" or "✗"),
    "",
    "User Commands:",
    "  :NeoTreeTrashStats     - Show this message",
    "  :NeoTreeTrashDebug     - Toggle debug mode",
    "  :NeoTreeTrashDryRun    - Toggle dry-run mode",
  }

  notify.info(table.concat(stats, "\n"))
end

return M
