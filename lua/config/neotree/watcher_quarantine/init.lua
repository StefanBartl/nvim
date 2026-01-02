---@module 'config.neotree.watcher_quarantine'
---@brief Safe file-watcher management during file operations (Windows EPERM fix)
---
--- This module implements a "quarantine" system to prevent EPERM errors and
--- UI freezes during file operations on Windows. It works by:
--- 1. Stopping all file watchers before destructive operations
--- 2. Suppressing EPERM notifications during the quarantine period
--- 3. Safely restarting watchers after filesystem has settled
--- 4. Providing async-safe refresh that waits for quarantine to end

local M = {}

---@class WatcherQuarantineState
---@field in_quarantine boolean Global quarantine active
---@field quarantine_until number Timestamp when quarantine ends (vim.loop.now())
---@field suspended_paths table<string, number> Per-path quarantine timestamps
---@field error_suppressed boolean EPERM suppression active
---@field original_notify function|nil Backup of original vim.notify

---@type WatcherQuarantineState
local S = {
  in_quarantine = false,
  quarantine_until = 0,
  suspended_paths = {},
  error_suppressed = false,
  original_notify = nil,
}

---Check if currently in global quarantine period
---@return boolean
function M.is_quarantined()
  if not S.in_quarantine then
    return false
  end

  local now = vim.loop.now()
  if now >= S.quarantine_until then
    -- Quarantine expired naturally
    M._auto_exit_quarantine()
    return false
  end

  return true
end

---Check if specific path is quarantined
---@param path string File/directory path
---@return boolean
function M.is_path_quarantined(path)
  if not path then
    return false
  end

  local now = vim.loop.now()
  local until_time = S.suspended_paths[path]

  if not until_time then
    return false
  end

  if now >= until_time then
    -- Path quarantine expired
    S.suspended_paths[path] = nil
    return false
  end

  return true
end

---Enter quarantine mode: stop all watchers and suppress EPERM errors
---@param duration_ms integer Duration in milliseconds (default: 1500)
---@param paths string[]|nil Specific paths to quarantine (optional)
function M.enter_quarantine(duration_ms, paths)
  duration_ms = duration_ms or 1500

  local now = vim.loop.now()
  S.in_quarantine = true
  S.quarantine_until = now + duration_ms
  S.error_suppressed = true

  -- Add specific paths if provided
  if paths then
    for _, path in ipairs(paths) do
      S.suspended_paths[path] = S.quarantine_until
    end
  end

  -- Stop all Neo-tree file watchers
  pcall(function()
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    if watcher and watcher.stop_all then
      watcher.stop_all()
    end
  end)

  -- Patch error handler to suppress EPERM
  M._patch_error_handler()
end

---Exit quarantine early (if operation completed faster than expected)
function M.exit_quarantine()
  S.in_quarantine = false
  S.quarantine_until = 0
  S.error_suppressed = false
  S.suspended_paths = {}

  M._unpatch_error_handler()
end

---Auto-exit when quarantine expires naturally
---@private
function M._auto_exit_quarantine()
  S.in_quarantine = false
  S.error_suppressed = false
  S.suspended_paths = {}

  M._unpatch_error_handler()
end

---Patch Neo-tree's error handler to suppress EPERM during quarantine
---@private
function M._patch_error_handler()
  -- Store original notify (only once)
  if not S.original_notify then
    S.original_notify = vim.notify
  end

  -- Patch notify to filter EPERM
  vim.notify = function(msg, level, opts)
    -- Suppress EPERM errors during quarantine
    if S.error_suppressed and type(msg) == "string" then
      -- Match various EPERM formats
      if msg:match("EPERM") or msg:match("permission denied") or msg:match("Operation not permitted") then
        return -- Suppress
      end
    end

    -- Call original for non-EPERM messages
    S.original_notify(msg, level, opts)
  end
end

---Restore original error handler
---@private
function M._unpatch_error_handler()
  if S.original_notify then
    vim.notify = S.original_notify
    S.original_notify = nil
  end
end

---Safe refresh with quarantine awareness
---Waits for quarantine to end before refreshing Neo-tree
---@param state_name string Neo-tree source name (e.g., "filesystem")
---@param callback fun()|nil Optional callback after refresh completes
function M.safe_refresh(state_name, callback)
  local function do_refresh()
    -- Check if still in quarantine
    if M.is_quarantined() then
      -- Still quarantined, retry later
      vim.defer_fn(do_refresh, 200)
      return
    end

    -- Quarantine ended, safe to refresh
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if not ok_mgr then
      return
    end

    -- Get state
    local state_ok, state = pcall(manager.get_state, state_name)
    if not state_ok or not state then
      return
    end

    -- Try command-based refresh first (safer than direct manager.refresh)
    local commands_ok, commands = pcall(require, "neo-tree.sources." .. state_name .. ".commands")
    if commands_ok and commands and type(commands.refresh) == "function" then
      pcall(commands.refresh, state)
    else
      -- Fallback to manager refresh
      pcall(manager.refresh, state_name)
    end

    -- Execute callback if provided
    if callback and type(callback) == "function" then
      vim.defer_fn(callback, 100)
    end
  end

  -- Initial delay before checking quarantine
  vim.defer_fn(do_refresh, 100)
end

---Check if file watchers are healthy
---@return boolean healthy
---@return string|nil reason
function M.health_check()
  local ok, watcher = pcall(require, "neo-tree.sources.filesystem.lib.file_watcher")
  if not ok then
    return false, "file_watcher module not available"
  end

  if not watcher then
    return false, "file_watcher is nil"
  end

  if not watcher.stop_all then
    return false, "file_watcher missing stop_all function"
  end

  return true
end

---Restart all watchers safely (only when not quarantined)
---@return boolean success
---@return string|nil error_message
function M.restart_watchers()
  if M.is_quarantined() then
    return false, "still in quarantine"
  end

  -- Stop all watchers
  pcall(function()
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    if watcher and watcher.stop_all then
      watcher.stop_all()
    end
  end)

  -- Restart via refresh after short delay
  vim.defer_fn(function()
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if ok and manager then
      pcall(manager.refresh, "filesystem")
    end
  end, 500)

  return true
end

---Cleanup on module unload
function M._cleanup()
  M.exit_quarantine()
end

return M

