---@module 'config.neotree.trash'
---@brief Trash orchestrator with single confirmation point

local notify = require("lib.notify").create("[neotree.trash]")
local memo = require("lib.memo")

-- Submodules
local platform = require("config.neotree.trash.platform")
local buffer_checker = require("config.neotree.trash.validation.buffer_checker")
local confirmation = require("config.neotree.trash.confirmation")
local operations = require("config.neotree.trash.operations")

-- Safety & Watcher
local safety = require("config.neotree.safety")
local watcher_quarantine = require("config.neotree.watcher_quarantine")

local M = {}

local fn = vim.fn
local defer_fn = vim.defer_fn

---@type Cfg.NeoTree.Trash.Config
M.config = {
  use_safety_system = true,
  create_backups = true,
  use_dry_run = true,
  auto_close_buffers = true, -- Always true now
  debug = false,
}

---Configure trash module
---@param config Cfg.NeoTree.Trash.Config|boolean|nil
---@return nil
function M.setup(config)
  if config then
    M.config = vim.tbl_deep_extend("force", M.config, config)
  end

  -- Force auto_close to true (no separate prompt anymore)
  M.config.auto_close_buffers = true

  buffer_checker.set_config(M.config)
  operations.set_config(M.config)
end

---Debug notify
---@param msg string
---@return nil
local function debug_notify(msg)
  if M.config.debug then
    notify.info(msg)
  end
end

---Safe refresh
---@param state_name string
---@return nil
local function safe_refresh(state_name)
  watcher_quarantine.safe_refresh(state_name)
end

---Collect nodes (memoized)
---@param state Cfg.NeoTree.State
---@return Cfg.NeoTree.Node[]
---@nodiscard
local get_nodes_to_trash = memo.fn(function(state)
  local mark_cmd = require("config.neotree.commands.mark")
  return mark_cmd.get_marked_or_current(state)
end, { size = 16 })

---Send single item to trash
---@param path string
---@param filename string
---@return boolean success
---@return string message
---@nodiscard
local function send_single_to_trash(path, filename)
  filename = filename or fn.fnamemodify(path, ":t")

  -- Check and auto-close references
  local has_refs, ref_info = buffer_checker.check_references(path)

  if has_refs then
    debug_notify(("⚠ File '%s' has open references"):format(filename))

    local closed = buffer_checker.auto_close_references(path, filename, ref_info)

    if not closed then
      return false, "Could not close all references"
    end

    -- Double-check
    has_refs, ref_info = buffer_checker.check_references(path)
    if has_refs then
      notify.error(("❌ Still cannot delete '%s'\nPlease close manually"):format(filename))
      return false, "References still open"
    end
  end

  -- Validation
  if M.config.use_safety_system then
    local valid, reason = safety.validation.validate_operation("delete", { path })
    if not valid then
      notify.error("Validation failed: " .. reason)
      return false, reason or "validation failed"
    end
  end

  -- Execute trash
  if not M.config.use_safety_system then
    return platform.send_to_trash(path)
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

  return ok, msg or "unknown error"
end

---Main Neo-tree command
---@param state Cfg.NeoTree.State
---@return nil
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
    local path = node.path or node.uri or node:get_id()
    if path then
      paths[#paths + 1] = path
      names[#names + 1] = node.name or fn.fnamemodify(path, ":t")
    end
  end

  if #paths == 0 then
    notify.warn("No valid paths found")
    return
  end

  -- Check for open buffers (for confirmation message)
  local has_any_refs = false
  for _, path in ipairs(paths) do
    local has_refs = buffer_checker.check_references(path)
    if has_refs then
      has_any_refs = true
      break
    end
  end

  -- SINGLE CONFIRMATION POINT
  local delete_mode = confirmation.get_unified_confirmation(names, has_any_refs)

  if delete_mode == "cancel" then
    notify.info("ℹ️ Operation cancelled")
    return
  end

  ---@cast delete_mode "all"|"individual"

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
      if results.success_count > 0 then
        local mark_cmd = require("config.neotree.commands.mark")
        pcall(mark_cmd.clear_all_marks, state)
      end

      -- Refresh
      defer_fn(function()
        safe_refresh(state.name or "filesystem")
      end, 200)

      -- Show results
      operations.show_results(results, backups_created)
    end, 150)
  end)
end

---Toggle debug
---@return nil
function M.toggle_debug()
  M.config.debug = not M.config.debug
  buffer_checker.set_config(M.config)
  notify.info(("Debug mode: %s"):format(M.config.debug and "ENABLED" or "DISABLED"))
end

---Toggle dry-run
---@return nil
function M.toggle_dry_run()
  if safety.dry_run.enabled then
    safety.dry_run.disable()
  else
    safety.dry_run.enable()
  end
end

---Show stats
---@return nil
function M.show_stats()
  local backups = safety.backup.list_backups()
  local recovery_points = safety.recovery.list_recovery_points()
  local queue_status = safety.queue.status()

  local stats = {
    "=== Neo-tree Trash Statistics ===",
    "",
    ("Safety System: %s"):format(M.config.use_safety_system and "✓" or "✗"),
    ("Debug Mode: %s"):format(M.config.debug and "✓" or "✗"),
    ("Auto-Close Buffers: YES (always enabled)"),
    ("Backups: %d"):format(#backups),
    ("Recovery Points: %d"):format(#recovery_points),
    ("Queue: %s"):format(queue_status.processing and "PROCESSING" or "IDLE"),
    ("Dry-Run: %s"):format(safety.dry_run.enabled and "✓" or "✗"),
    "",
    "User Commands:",
    "  :NeoTreeTrashStats     - Show this",
    "  :NeoTreeTrashDebug     - Toggle debug",
    "  :NeoTreeTrashDryRun    - Toggle dry-run",
  }

  notify.info(table.concat(stats, "\n"))
end

return M
