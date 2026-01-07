---@module 'config.neotree.trash'
---@brief Move selected files/folders to system Trash with comprehensive safety features
---
--- Features:
--- - Automatic backup before deletion
--- - Input validation (prevents system directory deletion)
--- - Watcher quarantine (prevents EPERM errors)
--- - Batch operation support with marking
--- - Undo history integration
--- - Cross-platform trash support (Windows, Linux, macOS)
---
--- Safety layers applied:
--- 1. Validation - Checks if path is safe to delete
--- 2. Confirmation - User must confirm dangerous operations
--- 3. Backup - Creates automatic backup before deletion
--- 4. Quarantine - Stops watchers to prevent EPERM
--- 5. Recovery Point - Allows automatic retry on failure
-- AUDIT: Modularize

-- Safety system integration
local safety = require("config.neotree.safety")
local watcher_quarantine = require("config.neotree.watcher_quarantine")

local notify = require("lib.notify").create("[neotree.trash]")

local M = {}

local api, uv = vim.api, vim.loop
local fn = vim.fn
local resolve, system = fn.resolve, fn.system
local defer_fn = vim.defer_fn
local sh_error = vim.v.shell_error
local str_format = string.format

---@type Cfg.NeoTree.Trash.Config
M.config = {
  use_safety_system = true,
  create_backups = true,
  confirm_dangerous = true,
  use_dry_run = true,
}

---Configure trash module
---@param config Cfg.NeoTree.Trash.Config|nil
function M.setup(config)
  if config then
    M.config = vim.tbl_deep_extend("force", M.config, config)
  end
end

---Escape shell argument in a platform-appropriate way
---@param path string
---@return string
local function escape_shell_arg(path)
  if uv.os_uname().sysname == "Windows_NT" then
    return "'" .. path:gsub("'", "''") .. "'"
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

---Close all buffers and previews related to path
---@param path string
local function close_related_buffers_and_previews(path)
  local normalized_path = resolve(path):gsub("\\", "/")

  -- Close affected buffers
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) then
      local buf_name = api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local normalized_buf = resolve(buf_name):gsub("\\", "/")
        if normalized_buf:sub(1, #normalized_path) == normalized_path or normalized_buf == normalized_path then
          pcall(api.nvim_buf_delete, buf, { force = true, unload = true })
        end
      end
    end
  end

  -- Close Neo-tree preview if open
  pcall(function()
    local preview = require("neo-tree.ui.preview")
    if preview and preview.close then
      preview.close()
    end
  end)

  -- Close float windows that might show the path
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local win_buf = api.nvim_win_get_buf(win)
      local buf_name = api.nvim_buf_get_name(win_buf)
      if buf_name ~= "" then
        local normalized_buf = resolve(buf_name):gsub("\\", "/")
        if normalized_buf:sub(1, #normalized_path) == normalized_path then
          pcall(api.nvim_win_close, win, true)
        end
      end
    end
  end
end

---Send file/directory to system trash using platform-specific method
---@param path string
---@return boolean success
---@return string message
local function send_to_trash_impl(path)
  local sys = uv.os_uname().sysname
  local esc = escape_shell_arg(path)

  local function has_exe(name)
    return fn.executable(name) == 1
  end

  local ok = false
  local msg = "no supported trash command found"

  if sys ~= "Windows_NT" then
    -- Linux/macOS trash methods
    if has_exe("gio") then
      local out = system({ "gio", "trash", path })
      ok, msg = sh_error == 0, out
    elseif has_exe("trash") then
      local out = system({ "trash", path })
      ok, msg = sh_error == 0, out
    elseif has_exe("trash-put") then
      local out = system({ "trash-put", path })
      ok, msg = sh_error == 0, out
    elseif has_exe("kioclient5") then
      local out = system({ "kioclient5", "move", path, "trash:/" })
      ok, msg = sh_error == 0, out
    elseif sys == "Darwin" and has_exe("osascript") then
      local applescript = str_format('tell application "Finder" to delete POSIX file %s', esc)
      local out = system({ "osascript", "-e", applescript })
      ok, msg = sh_error == 0, out
    else
      -- Fallback: manual trash directory
      local home = uv.os_homedir()
      local trashdir = home .. "/.local/share/Trash/files"
      if not uv.fs_stat(trashdir) then
        local okc, errc = pcall(fn.mkdir, trashdir, "p")
        if not okc then
          return false, "failed to create trash dir: " .. tostring(errc)
        end
      end
      local dest = trashdir .. "/" .. fn.fnamemodify(path, ":t")
      local ok_mv, err_mv = os.rename(path, dest)
      ok, msg = ok_mv, ok_mv and ("moved to " .. dest) or tostring(err_mv)
    end
  else
    -- Windows: PowerShell RecycleBin method
    close_related_buffers_and_previews(path)

    local stat = uv.fs_stat(path)
    local is_dir = stat and stat.type == "directory"

    vim.wait(100)

    local ps_script
    if is_dir then
      ps_script = str_format(
        "$ErrorActionPreference='Stop'; "
          .. "Add-Type -AssemblyName Microsoft.VisualBasic; "
          .. "try { "
          .. "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(%s,'OnlyErrorDialogs','SendToRecycleBin') "
          .. "} catch { "
          .. "Write-Error $_.Exception.Message; exit 1 "
          .. "}",
        esc
      )
    else
      ps_script = str_format(
        "$ErrorActionPreference='Stop'; "
          .. "Add-Type -AssemblyName Microsoft.VisualBasic; "
          .. "try { "
          .. "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(%s,'OnlyErrorDialogs','SendToRecycleBin') "
          .. "} catch { "
          .. "Write-Error $_.Exception.Message; exit 1 "
          .. "}",
        esc
      )
    end

    local out = system({ "powershell", "-NoProfile", "-Command", ps_script })
    ok, msg = sh_error == 0, out

    -- Fallback for directories
    if not ok and is_dir then
      local fallback_script = str_format(
        "$path = %s; "
          .. "if (Test-Path $path) { "
          .. "Get-ChildItem -Path $path -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; "
          .. "Remove-Item -Path $path -Force -Recurse -ErrorAction Stop "
          .. "}",
        esc
      )
      local _ = system({ "powershell", "-NoProfile", "-Command", fallback_script })
      if sh_error == 0 then
        ok, msg = true, "moved via fallback method"
      end
    end
  end

  return ok, msg
end

--- fix: return value annotaitons
---Send to trash with full safety features
---@param path string
-- ---@return boolean success
-- ---@return string message
function M.send_to_trash(path)
  if not M.config.use_safety_system then
    -- Direct trash without safety
    return send_to_trash_impl(path)
  end

  -- Use full safety system
  return safety.safe_operation(function()
    -- Enter quarantine (EPERM prevention)
    watcher_quarantine.enter_quarantine(2000, { path })

    -- Close related resources
    close_related_buffers_and_previews(path)
    vim.wait(100)

    -- Execute trash operation
    local ok, msg = send_to_trash_impl(path)

    -- Safe refresh (waits for quarantine)
    if ok then
      watcher_quarantine.safe_refresh("filesystem")
    end

    ---@diagnostic disable-next-line
    return ok, msg
  end, "delete", { path })
end

---Safely refresh Neo-tree after file operations
---@param state_name string
local function safe_refresh(state_name)
  watcher_quarantine.safe_refresh(state_name)
end

--- Collect nodes to trash (marked nodes or current node)
---@param state Cfg.NeoTree.State
---@return table[] nodes Array of nodes (may be empty)
local function get_nodes_to_trash(state)
  if not state then
    return {}
  end

  local marks = state.explicitly_marked_node_ids or {}
  local nodes = {}

  -- Collect marked nodes first
  for node_id, _ in pairs(marks) do
    -- Try to find node by id among current tree's children
    if state.current_node and state.current_node.children then
      for _, child in ipairs(state.current_node.children) do
        if child.id == node_id then
          table.insert(nodes, child)
          break
        end
      end
    end
  end

  -- Return marked nodes if any
  if #nodes > 0 then
    return nodes
  end

  -- Fallback to current_node
  if state.current_node then
    return { state.current_node }
  end

  return {}
end

---Neo-tree command: move selected nodes to trash with full safety
---@param state Cfg.NeoTree.State Neo-tree state
---@return nil
function M.neotree_send_node_to_trash(state)
  local nodes = get_nodes_to_trash(state)

  if #nodes == 0 then
    notify.warn("No nodes selected")
    return
  end

  -- Collect paths and names
  ---@type string[]
  local paths = {}
  ---@type string[]
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

  -- === SAFETY LAYER 1: VALIDATION ===
  if M.config.use_safety_system then
    local valid, reason = safety.validation.validate_operation("delete", paths)
    if not valid then
      notify.error("Operation denied: " .. reason)
      return
    end
  end

  -- === SAFETY LAYER 2: DRY-RUN CHECK ===
  if M.config.use_dry_run and safety.dry_run.enabled then
    safety.dry_run.log_operation("trash", {
      paths = paths,
      names = names,
      count = #paths,
    })
    notify.info(str_format("[DRY-RUN] Would trash %d items", #paths))
    return
  end

  -- === SAFETY LAYER 3: CONFIRMATION ===
  local prompt
  if #paths == 1 then
    prompt = str_format("Move to Trash: %s ? (y/N) ", names[1])
  else
    prompt = str_format("Move %d items to Trash? (y/N) ", #paths)
  end

  local ans = fn.input(prompt)
  api.nvim_command("redraw")

  if ans ~= "y" and ans ~= "Y" then
    notify.info("Cancelled")
    return
  end

  notify.info("Moving to Trash...")

  -- === SAFETY LAYER 4: BACKUP ===
  local backups_created = {}
  if M.config.create_backups then
    for i = 1, #paths do
      local path = paths[i]
      local backup_path, err = safety.backup.create_backup(path, "trash")
      if backup_path then
        backups_created[path] = backup_path
        notify.debug(str_format("Backup: %s", backup_path))
      else
        notify.warn(str_format("Backup failed for %s: %s", names[i], err or "unknown"))
      end
    end
  end

  -- === SAFETY LAYER 5: RECOVERY POINT ===
  if M.config.use_safety_system then
    safety.recovery.create_recovery_point("trash", paths, {
      backups = backups_created,
      names = names,
    })
  end

  -- === SAFETY LAYER 6: WATCHER QUARANTINE ===
  watcher_quarantine.enter_quarantine(2000, paths)

  -- Close related resources
  for i = 1, #paths do
    close_related_buffers_and_previews(paths[i])
  end

  vim.wait(100)

  -- === EXECUTE OPERATIONS ===
  vim.schedule(function()
    defer_fn(function()
      local failed = false
      local success_count = 0
      local failed_items = {}

      for i = 1, #paths do
        local path = paths[i]
        local ok, msg = send_to_trash_impl(path)

        if ok then
          success_count = success_count + 1

          -- Add to undo history
          local undo_ok, undo_module = pcall(require, "config.neotree.undo")
          if undo_ok and undo_module.add_to_history then
            undo_module.add_to_history(path, names[i])
          end
        else
          failed = true
          table.insert(failed_items, {
            path = path,
            name = names[i],
            error = msg,
          })

          local clean_msg = msg:match("([^\r\n]+)") or msg
          notify.error(str_format("✗ Failed: %s - %s", names[i], clean_msg))

          -- Attempt recovery if safety enabled
          if M.config.use_safety_system then
            local recovered = safety.recovery.attempt_recovery({
              operation = "trash",
              path = path,
              message = msg,
            })
            if recovered then
              notify.info(str_format("Recovery attempted for: %s", names[i]))
            end
          end
        end
      end

      -- Clear marks after successful operations
      if success_count > 0 and state.explicitly_marked_node_ids then
        state.explicitly_marked_node_ids = {}
        pcall(function()
          local renderer = require("neo-tree.ui.renderer")
          renderer.redraw(state)
        end)
      end

      -- Safe refresh (waits for quarantine)
      defer_fn(function()
        safe_refresh(state.name or "filesystem")
      end, 200)

      -- Final notification
      if success_count > 0 then
        local msg = str_format("✓ Moved to Trash (%d items)", success_count)
        if failed then
          msg = msg .. str_format(" - %d failed", #failed_items)
        end
        notify.info(msg)

        -- Show backup info if created
        if M.config.create_backups and next(backups_created) then
          notify.info(str_format("Backups created: %d", vim.tbl_count(backups_created)))
        end
      else
        notify.error("All operations failed")
      end

      -- Show recovery hint if failures
      if #failed_items > 0 and M.config.create_backups then
        notify.info("Tip: Use :NeoTreeBackupList to restore from backups")
      end
    end, 150)
  end)
end

---Enable/disable safety features
---@param enabled boolean
function M.set_safety_enabled(enabled)
  M.config.use_safety_system = enabled
  notify.info(str_format("Safety system: %s", enabled and "ENABLED" or "DISABLED"))
end

---Toggle dry-run mode
function M.toggle_dry_run()
  if safety.dry_run.enabled then
    safety.dry_run.disable()
  else
    safety.dry_run.enable()
  end
end

---Show trash statistics
function M.show_stats()
  local backups = safety.backup.list_backups()
  local recovery_points = safety.recovery.list_recovery_points()
  local queue_status = safety.queue.status()

  local stats = {
    "=== Neo-tree Trash Statistics ===",
    "",
    string.format("Safety System: %s", M.config.use_safety_system and "ENABLED" or "DISABLED"),
    string.format("Backups: %d", #backups),
    string.format("Recovery Points: %d", #recovery_points),
    string.format("Queue Status: %s", queue_status.processing and "PROCESSING" or "IDLE"),
    string.format("Pending Operations: %d", queue_status.pending),
    string.format("Dry-Run Mode: %s", safety.dry_run.enabled and "ENABLED" or "DISABLED"),
    "",
    "Commands:",
    "  :NeoTreeBackupList     - Browse and restore backups",
    "  :NeoTreeDryRunToggle   - Toggle test mode",
    "  :Cfg.NeoTree.TrashStats     - Show this message",
  }

  notify.info(table.concat(stats, "\n"))
end

return M
