---@module 'config.neotree.trash'
--- Neo-tree integration: move selected file/folder to system Trash and refresh neo-tree view.
--- Provides send_to_trash(path) and neotree_send_node_to_trash(state) exported functions.

local notify = require("lib.notify").create("[neotree.trash]")
local watcher_quarantine = require("config.neotree.watcher_quarantine")
-- local safety = require("config.neotree.safety")

local M = {}

local api, uv = vim.api, vim.loop
local fn = vim.fn
local resolve, system = fn.resolve, fn.system
local defer_fn = vim.defer_fn
local sh_error = vim.v.shell_error
local str_format = string.format

--- Escape shell argument in a platform-appropriate way.
---@param path string
---@return string
local function escape_shell_arg(path)
  if uv.os_uname().sysname == "Windows_NT" then
    return "'" .. path:gsub("'", "''") .. "'"
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

--- Schließe alle Buffers und Preview die diesen Pfad betreffen
---@param path string
local function close_related_buffers_and_previews(path)
  -- Normalisiere Pfad für Vergleich
  local normalized_path = resolve(path):gsub("\\", "/")

  -- Schließe alle betroffenen Buffers
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) then
      local buf_name = api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local normalized_buf = resolve(buf_name):gsub("\\", "/")
        -- Prüfe ob Buffer innerhalb des zu löschenden Pfads liegt
        if normalized_buf:sub(1, #normalized_path) == normalized_path or normalized_buf == normalized_path then
          pcall(api.nvim_buf_delete, buf, { force = true, unload = true })
        end
      end
    end
  end

  -- Schließe Neo-tree Preview falls offen
  pcall(function()
    local preview = require("neo-tree.ui.preview")
    if preview and preview.close then
      preview.close()
    end
  end)

  -- Schließe alle Float-Windows die den Pfad betreffen könnten
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

--- Send given file/directory path to system Trash using available backend.
---@param path string
---@return boolean, string
local function send_to_trash(path)
  local sys = uv.os_uname().sysname
  local esc = escape_shell_arg(path)

  local function has_exe(name)
    return fn.executable(name) == 1
  end

  local ok = false
  local msg = "no supported trash command found"

  if sys ~= "Windows_NT" then
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
    -- Windows: Schließe zuerst alle Buffers
    close_related_buffers_and_previews(path)

    local stat = uv.fs_stat(path)
    local is_dir = stat and stat.type == "directory"

    -- Warte damit Buffers geschlossen werden
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

    -- Fallback: Bei Fehler versuche es mit robustem PowerShell Script
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

---Safely refresh Neo-tree after file operations
---Uses quarantine-aware refresh to avoid EPERM
---@param state_name string
local function safe_refresh(state_name)
  -- Use quarantine-aware refresh (waits for quarantine to end)
  watcher_quarantine.safe_refresh(state_name)
end

--- Collect nodes to trash:
--- - marked nodes if present
--- - otherwise the node under cursor
---@param state table
---@return table[] nodes
local function get_nodes_to_trash(state)
  local tree = state.tree
  if not tree then
    return {}
  end

  -- Get marked nodes from state
  local marks = state.explicitly_marked_node_ids or {}
  local marked_nodes = {}

  -- Collect all marked nodes
  for node_id, _ in pairs(marks) do
    local node = tree:get_node(node_id)
    if node then
      table.insert(marked_nodes, node)
    end
  end

  if #marked_nodes > 0 then
    return marked_nodes
  end

  -- Fallback to current node
  local node = tree:get_node()
  if node then
    return { node }
  end

  return {}
end

---Neo-tree mapping callback: move selected node to Trash and refresh the Neo-tree view.
---@param state table
---@return nil
local function neotree_send_node_to_trash(state)
  local nodes = get_nodes_to_trash(state)

  if #nodes == 0 then
    notify.warn("No nodes selected")
    return
  end

  -- Collect paths
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
    notify.info("No valid paths found")
    return
  end

  -- Confirmation dialog
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

  -- ENTER QUARANTINE FIRST
  -- This stops watchers AND suppresses EPERM for 2 seconds
  watcher_quarantine.enter_quarantine(2000, paths)

  -- Cleanup: close buffers and previews
  for i = 1, #paths do
    local path = paths[i]
    close_related_buffers_and_previews(path)
  end

  -- Wait for buffers to close
  vim.wait(100)

  -- Asynchronous batch delete
  vim.schedule(function()
    defer_fn(function()
      local failed = false
      local success_count = 0

      for i = 1, #paths do
        local path = paths[i]
        local ok, msg = send_to_trash(path)
        if ok then
          success_count = success_count + 1

          -- Add to undo history
          local undo_ok, undo_module = pcall(require, "config.neotree.undo")
          if undo_ok and undo_module.add_to_history then
            undo_module.add_to_history(path, names[i])
          end
        else
          failed = true
          local clean_msg = msg:match("([^\r\n]+)") or msg
          notify.error("✗ Failed: " .. clean_msg)
        end
      end

      -- Clear marks after successful trash
      if success_count > 0 and state.explicitly_marked_node_ids then
        state.explicitly_marked_node_ids = {}
        pcall(function()
          local renderer = require("neo-tree.ui.renderer")
          renderer.redraw(state)
        end)
      end

      -- SAFE REFRESH (waits for quarantine to end automatically)
      defer_fn(function()
        safe_refresh(state.name or "filesystem")
      end, 200)

      if success_count > 0 then
        local msg = str_format("✓ Moved to Trash (%d items)", success_count)
        if failed then
          msg = msg .. " - some items failed"
        end
        notify.info(msg)
      end

      -- Quarantine expires automatically after 2s
    end, 150)
  end)
end

M.send_to_trash = send_to_trash
M.neotree_send_node_to_trash = neotree_send_node_to_trash

---@package
---@return NeoTreeTrash
return M
