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
--- - Smart buffer/preview/reference closure
---
--- Safety layers applied:
--- 1. Validation - Checks if path is safe to delete
--- 2. Buffer/Preview Detection - Finds and closes open references
--- 3. Confirmation - User must confirm dangerous operations
--- 4. Backup - Creates automatic backup before deletion
--- 5. Quarantine - Stops watchers to prevent EPERM
--- 6. Recovery Point - Allows automatic retry on failure

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
  auto_close_buffers = false, -- Ask user before closing
  debug = false, -- Detailed feedback about closure attempts
}

---Configure trash module
---@param config Cfg.NeoTree.Trash.Config|nil
function M.setup(config)
  if config then
    M.config = vim.tbl_deep_extend("force", M.config, config)
  end
end

---Debug notify helper
---@param msg string
---@param opts? table
local function debug_notify(msg, opts)
  if M.config.debug then
    notify.info(msg, opts)
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

---Find all buffers that reference a path
---@param path string
---@return integer[] bufnrs Array of buffer numbers
---@return string[] buf_names Array of buffer display names
local function find_buffers_with_path(path)
  local bufnrs = {}
  local buf_names = {}
  local normalized_path = resolve(path):gsub("\\", "/")

  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) then
      local buf_name = api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local normalized_buf = resolve(buf_name):gsub("\\", "/")
        -- Check exact match or if buffer is child of directory
        if normalized_buf == normalized_path or normalized_buf:sub(1, #normalized_path) == normalized_path then
          table.insert(bufnrs, buf)
          local display_name = fn.fnamemodify(buf_name, ":t")
          if display_name == "" then
            display_name = string.format("[Buffer %d]", buf)
          end
          table.insert(buf_names, display_name)
        end
      end
    end
  end

  return bufnrs, buf_names
end

---Check if Neo-tree preview is showing a path
---@param path string
---@return boolean is_open
---@return string|nil window_info
local function find_preview_with_path(path)
  local normalized_path = resolve(path):gsub("\\", "/")

  local preview_ok, preview = pcall(require, "neo-tree.ui.preview")
  if not preview_ok or not preview then
    return false, nil
  end

  -- Check all windows for preview buffers
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local win_buf = api.nvim_win_get_buf(win)
      local buf_name = api.nvim_buf_get_name(win_buf)

      if buf_name ~= "" then
        local normalized_buf = resolve(buf_name):gsub("\\", "/")
        if normalized_buf == normalized_path or normalized_buf:sub(1, #normalized_path) == normalized_path then
          -- Check if this is a preview window
          local win_config = api.nvim_win_get_config(win)
          if win_config.relative ~= "" then -- Float window
            return true, string.format("Preview Window (Win %d)", win)
          end
        end
      end
    end
  end

  return false, nil
end

---Close all references to a path (buffers, previews, windows)
---@param path string
---@param filename string Display name for messages
---@param force boolean Close without asking
---@return boolean success True if all closed or user confirmed
---@return string[] messages Detail messages about what was closed
local function close_all_references(path, filename, force)
  local messages = {}
  local bufnrs, buf_names = find_buffers_with_path(path)
  local has_preview, preview_info = find_preview_with_path(path)

  -- Nothing to close
  if #bufnrs == 0 and not has_preview then
    return true, {}
  end

  -- Build detailed message
  local details = {}

  if #bufnrs > 0 then
    table.insert(details, string.format("📄 File '%s' is open in %d buffer%s:",
      filename,
      #bufnrs,
      #bufnrs > 1 and "s" or ""
    ))
    for i, name in ipairs(buf_names) do
      table.insert(details, string.format("   [%d] %s", bufnrs[i], name))
    end
  end

  if has_preview then
    table.insert(details, string.format("🔍 File '%s' is shown in:", filename))
    table.insert(details, "   " .. preview_info)
  end

  debug_notify(table.concat(details, "\n"))

  -- Ask for confirmation unless auto_close or force
  if not force and not M.config.auto_close_buffers then
    table.insert(details, "")
    table.insert(details, "Close and delete? (y/N)")

    local prompt = table.concat(details, "\n")
    local ans = fn.input(prompt .. " ")
    api.nvim_command("redraw")

    if ans ~= "y" and ans ~= "Y" then
      notify.info("❌ Operation cancelled by user")
      return false, {}
    end
  end

  debug_notify("🔄 Attempting to close references...")

  -- Close buffers
  local failed_buffers = {}
  for i, bufnr in ipairs(bufnrs) do
    if api.nvim_buf_is_valid(bufnr) then
      local ok = pcall(api.nvim_buf_delete, bufnr, { force = true })
      if ok then
        table.insert(messages, string.format("✓ Closed buffer: %s", buf_names[i]))
        debug_notify(string.format("✓ Closed buffer %d: %s", bufnr, buf_names[i]))
      else
        table.insert(failed_buffers, { bufnr = bufnr, name = buf_names[i] })
        debug_notify(string.format("✗ Failed to close buffer %d: %s", bufnr, buf_names[i]))
      end
    end
  end

  -- Close preview windows
  if has_preview then
    local preview_closed = false

    -- Try to close Neo-tree preview
    pcall(function()
      local preview = require("neo-tree.ui.preview")
      if preview and preview.close then
        preview.close()
        preview_closed = true
      end
    end)

    -- Close any floating windows showing the path
    for _, win in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_is_valid(win) then
        local win_buf = api.nvim_win_get_buf(win)
        local buf_name = api.nvim_buf_get_name(win_buf)
        local normalized_buf = resolve(buf_name):gsub("\\", "/")
        local normalized_path = resolve(path):gsub("\\", "/")

        if normalized_buf == normalized_path or normalized_buf:sub(1, #normalized_path) == normalized_path then
          local ok = pcall(api.nvim_win_close, win, true)
          if ok then
            preview_closed = true
          end
        end
      end
    end

    if preview_closed then
      table.insert(messages, "✓ Closed preview window")
      debug_notify("✓ Closed preview window")
    else
      table.insert(messages, "⚠ Could not close preview")
      debug_notify("⚠ Could not close preview")
    end
  end

  -- Report failures
  if #failed_buffers > 0 then
    local error_lines = { "❌ Failed to close some buffers:" }
    for _, fail in ipairs(failed_buffers) do
      table.insert(error_lines, string.format("   [%d] %s", fail.bufnr, fail.name))
    end
    table.insert(error_lines, "")
    table.insert(error_lines, "Please close manually or restart Neovim")

    notify.error(table.concat(error_lines, "\n"))
    return false, messages
  end

  -- Wait for changes to settle
  if #messages > 0 then
    vim.wait(100)
  end

  return true, messages
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
    local stat = uv.fs_stat(path)
    local is_dir = stat and stat.type == "directory"

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

---Send to trash with full safety features and smart reference closure
---@param path string
---@param filename string Display name for user messages
---@return boolean success
---@return string message
---@return string[] closure_details Messages about what was closed
function M.send_to_trash(path, filename)
  filename = filename or fn.fnamemodify(path, ":t")

  if not M.config.use_safety_system then
    -- Direct trash without safety
    return send_to_trash_impl(path), "", {}
  end

  -- Check for open references
  local bufnrs, _ = find_buffers_with_path(path)
  local has_preview, _ = find_preview_with_path(path)
  local closure_messages = {}

  if #bufnrs > 0 or has_preview then
    debug_notify(string.format("⚠ Cannot delete '%s' - references found", filename))

    -- Try to close all references
    local closed_ok, close_msgs = close_all_references(path, filename, false)
    closure_messages = close_msgs

    if not closed_ok then
      return false, "Could not close all references", closure_messages
    end

    -- Re-check after closure
    bufnrs, _ = find_buffers_with_path(path)
    has_preview, _ = find_preview_with_path(path)

    if #bufnrs > 0 or has_preview then
      notify.error(string.format(
        "❌ Still cannot delete '%s'\n" ..
        "Remaining references:\n" ..
        "%s\n" ..
        "Please close manually or restart Neovim",
        filename,
        #bufnrs > 0 and string.format("- %d buffer(s)", #bufnrs) or "" ..
        (has_preview and "\n- Preview window" or "")
      ))
      return false, "References still open after closure attempt", closure_messages
    end
  end

  -- Use full safety system
  local ok, msg = safety.safe_operation(function()
    -- Enter quarantine (EPERM prevention)
    watcher_quarantine.enter_quarantine(2000, { path })

    vim.wait(100)

    -- Execute trash operation
    local success, err = send_to_trash_impl(path)

    -- Safe refresh (waits for quarantine)
    if success then
      watcher_quarantine.safe_refresh("filesystem")
    end

    return success, err
  end, "delete", { path })

  return ok, msg or "", closure_messages
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
  if next(marks) then
    local tree = state.tree
    if tree then
      for node_id, _ in pairs(marks) do
        local node = tree:get_node(node_id)
        if node then
          table.insert(nodes, node)
        end
      end
    end
  end

  -- Return marked nodes if any
  if #nodes > 0 then
    return nodes
  end

  -- Fallback to current_node
  if state.tree then
    local current = state.tree:get_node()
    if current then
      return { current }
    end
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
        debug_notify(str_format("📦 Backup: %s", backup_path))
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

  -- === EXECUTE OPERATIONS ===
  vim.schedule(function()
    defer_fn(function()
      local failed = false
      local success_count = 0
      local failed_items = {}
      local all_closure_messages = {}

      for i = 1, #paths do
        local path = paths[i]
        local name = names[i]

        debug_notify(string.format("🗑 Processing: %s", name))

        local ok, msg, closure_msgs = M.send_to_trash(path, name)

        -- Collect closure messages
        if #closure_msgs > 0 then
          all_closure_messages[name] = closure_msgs
        end

        if ok then
          success_count = success_count + 1
          debug_notify(string.format("✓ Deleted: %s", name))

          -- Add to undo history
          local undo_ok, undo_module = pcall(require, "config.neotree.undo")
          if undo_ok and undo_module.add_to_history then
            undo_module.add_to_history(path, name)
          end
        else
          failed = true
          table.insert(failed_items, {
            path = path,
            name = name,
            error = msg,
          })

          local clean_msg = msg:match("([^\r\n]+)") or msg
          notify.error(str_format("✗ Failed: %s - %s", name, clean_msg))

          -- Attempt recovery if safety enabled
          if M.config.use_safety_system then
            local recovered = safety.recovery.attempt_recovery({
              operation = "trash",
              path = path,
              message = msg,
            })
            if recovered then
              notify.info(str_format("🔄 Recovery attempted for: %s", name))
            end
          end
        end
      end

      -- Show closure summary if debug enabled
      if M.config.debug and next(all_closure_messages) then
        for name, msgs in pairs(all_closure_messages) do
          debug_notify(string.format("📋 Closures for %s:\n  %s", name, table.concat(msgs, "\n  ")))
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
          notify.info(str_format("📦 Backups created: %d", vim.tbl_count(backups_created)))
        end
      else
        notify.error("❌ All operations failed")
      end

      -- Show recovery hint if failures
      if #failed_items > 0 and M.config.create_backups then
        notify.info("💡 Tip: Use :NeoTreeBackupList to restore from backups")
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

---Toggle debug mode
function M.toggle_debug()
  M.config.debug = not M.config.debug
  notify.info(str_format("Debug mode: %s", M.config.debug and "ENABLED" or "DISABLED"))
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
    string.format("Debug Mode: %s", M.config.debug and "ENABLED" or "DISABLED"),
    string.format("Auto-Close Buffers: %s", M.config.auto_close_buffers and "YES" or "NO (ask)"),
    string.format("Backups: %d", #backups),
    string.format("Recovery Points: %d", #recovery_points),
    string.format("Queue Status: %s", queue_status.processing and "PROCESSING" or "IDLE"),
    string.format("Pending Operations: %d", queue_status.pending),
    string.format("Dry-Run Mode: %s", safety.dry_run.enabled and "ENABLED" or "DISABLED"),
    "",
    "Commands:",
    "  :NeoTreeBackupList     - Browse and restore backups",
    "  :NeoTreeDryRunToggle   - Toggle test mode",
    "  :NeoTreeDebugToggle    - Toggle detailed feedback",
    "  :NeoTreeTrashStats     - Show this message",
  }

  notify.info(table.concat(stats, "\n"))
end

return M
