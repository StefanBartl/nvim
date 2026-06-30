---@module 'config.neotree.watcher_quarantine'
---@brief Safe file-watcher management during file operations (Windows EPERM fix)

local M = {}

---@type Cfg.NeoTree.WatcherQuarantine.State
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
    S.suspended_paths[path] = nil
    return false
  end

  return true
end

---Stop all Neo-tree file watchers safely
---@return boolean success
local function stop_watchers()
  local ok, fs_watch = pcall(require, "neo-tree.sources.filesystem.lib.fs_watch")
  if not ok or not fs_watch or not fs_watch.stop_watching then
    return false
  end

  pcall(fs_watch.stop_watching)
  return true
end

---Enter quarantine mode: stop all watchers
---@param duration_ms integer Duration in milliseconds (default: 1500)
---@param paths string[]|nil Specific paths to quarantine (optional)
function M.enter_quarantine(duration_ms, paths)
  duration_ms = duration_ms or 1500

  local now = vim.loop.now()
  S.in_quarantine = true
  S.quarantine_until = now + duration_ms
  S.error_suppressed = true

  if paths then
    for _, path in ipairs(paths) do
      S.suspended_paths[path] = S.quarantine_until
    end
  end

  -- Stop all Neo-tree file watchers
  stop_watchers()
end

---Exit quarantine early
function M.exit_quarantine()
  S.in_quarantine = false
  S.quarantine_until = 0
  S.error_suppressed = false
  S.suspended_paths = {}
end

---Auto-exit when quarantine expires naturally
---@private
function M._auto_exit_quarantine()
  S.in_quarantine = false
  S.error_suppressed = false
  S.suspended_paths = {}
end

---Safe refresh with quarantine awareness
---@param state_name string Neo-tree source name (e.g., "filesystem")
---@param callback fun()|nil Optional callback after refresh completes
function M.safe_refresh(state_name, callback)
  local function do_refresh()
    if M.is_quarantined() then
      vim.defer_fn(do_refresh, 200)
      return
    end

    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if not ok_mgr then
      return
    end

    local state_ok, state = pcall(manager.get_state, state_name)
    if not state_ok or not state then
      return
    end

    -- Try command-based refresh first (safer)
    local commands_ok, commands = pcall(require, "neo-tree.sources." .. state_name .. ".commands")
    if commands_ok and commands and type(commands.refresh) == "function" then
      pcall(commands.refresh, state)
    else
      pcall(manager.refresh, state_name)
    end

    if callback and type(callback) == "function" then
      vim.defer_fn(callback, 100)
    end
  end

  vim.defer_fn(do_refresh, 100)
end

---Check if file watchers are healthy
---@return boolean healthy
---@return string|nil reason
function M.health_check()
  local ok, fs_watch = pcall(require, "neo-tree.sources.filesystem.lib.fs_watch")
  if not ok then
    return false, "fs_watch module not available"
  end

  if not fs_watch then
    return false, "fs_watch is nil"
  end

  if not fs_watch.stop_watching then
    return false, "fs_watch missing stop_watching function"
  end

  return true
end

---Restart all watchers safely
---@return boolean success
---@return string|nil error_message
function M.restart_watchers()
  if M.is_quarantined() then
    return false, "still in quarantine"
  end

  stop_watchers()

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
