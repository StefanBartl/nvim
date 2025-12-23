---@module 'config.neotree.trash'
--- Neo-tree integration: move selected file/folder to system Trash and refresh neo-tree view.
--- Provides send_to_trash(path) and neotree_send_node_to_trash(state) exported functions.

local M = {}

local uv = vim.loop

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
  local normalized_path = vim.fn.resolve(path):gsub("\\", "/")

  -- Schließe alle betroffenen Buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name ~= "" then
        local normalized_buf = vim.fn.resolve(buf_name):gsub("\\", "/")
        -- Prüfe ob Buffer innerhalb des zu löschenden Pfads liegt
        if normalized_buf:sub(1, #normalized_path) == normalized_path or normalized_buf == normalized_path then
          pcall(vim.api.nvim_buf_delete, buf, { force = true, unload = true })
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
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local win_buf = vim.api.nvim_win_get_buf(win)
      local buf_name = vim.api.nvim_buf_get_name(win_buf)
      if buf_name ~= "" then
        local normalized_buf = vim.fn.resolve(buf_name):gsub("\\", "/")
        if normalized_buf:sub(1, #normalized_path) == normalized_path then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end
  end
end

--- Cleanup Neo-tree interne Watchers und State für einen Pfad
---@param path string
local function cleanup_neotree_watchers(path)
  pcall(function()
    -- Stoppe alle File Watchers
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    if watcher and watcher.stop then
      watcher.stop(path)
    end
  end)

  pcall(function()
    -- Clear Neo-tree's internal cache
    local manager = require("neo-tree.sources.manager")
    if manager and manager.close_all_nodes then
      manager.close_all_nodes()
    end
  end)
end

--- Send given file/directory path to system Trash using available backend.
---@param path string
---@return boolean, string
local function send_to_trash(path)
  local sys = uv.os_uname().sysname
  local esc = escape_shell_arg(path)

  local function has_exe(name)
    return vim.fn.executable(name) == 1
  end

  local ok = false
  local msg = "no supported trash command found"

  if sys ~= "Windows_NT" then
    if has_exe("gio") then
      local out = vim.fn.system({ "gio", "trash", path })
      ok, msg = vim.v.shell_error == 0, out
    elseif has_exe("trash") then
      local out = vim.fn.system({ "trash", path })
      ok, msg = vim.v.shell_error == 0, out
    elseif has_exe("trash-put") then
      local out = vim.fn.system({ "trash-put", path })
      ok, msg = vim.v.shell_error == 0, out
    elseif has_exe("kioclient5") then
      local out = vim.fn.system({ "kioclient5", "move", path, "trash:/" })
      ok, msg = vim.v.shell_error == 0, out
    elseif sys == "Darwin" and has_exe("osascript") then
      local applescript = string.format('tell application "Finder" to delete POSIX file %s', esc)
      local out = vim.fn.system({ "osascript", "-e", applescript })
      ok, msg = vim.v.shell_error == 0, out
    else
      local home = uv.os_homedir()
      local trashdir = home .. "/.local/share/Trash/files"
      if not uv.fs_stat(trashdir) then
        local okc, errc = pcall(vim.fn.mkdir, trashdir, "p")
        if not okc then
          return false, "failed to create trash dir: " .. tostring(errc)
        end
      end
      local dest = trashdir .. "/" .. vim.fn.fnamemodify(path, ":t")
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
      ps_script = string.format(
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
      ps_script = string.format(
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

    local out = vim.fn.system({ "powershell", "-NoProfile", "-Command", ps_script })
    ok, msg = vim.v.shell_error == 0, out

    -- Fallback: Bei Fehler versuche es mit robustem PowerShell Script
    if not ok and is_dir then
      local fallback_script = string.format(
        "$path = %s; "
          .. "if (Test-Path $path) { "
          .. "Get-ChildItem -Path $path -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; "
          .. "Remove-Item -Path $path -Force -Recurse -ErrorAction Stop "
          .. "}",
        esc
      )
      local _ = vim.fn.system({ "powershell", "-NoProfile", "-Command", fallback_script })
      if vim.v.shell_error == 0 then
        ok, msg = true, "moved via fallback method"
      end
    end
  end

  return ok, msg
end

--- Safely refresh Neo-tree after file operations
---@param state_name string
local function safe_refresh(state_name)
  -- Führe Refresh in mehreren Schritten aus um Blockierung zu vermeiden
  vim.schedule(function()
    local manager_ok, manager = pcall(require, "neo-tree.sources.manager")
    if not manager_ok then
      return
    end

    -- Schritt 1: Close all und reset
    pcall(function()
      if manager.close_all_nodes then
        manager.close_all_nodes()
      end
    end)

    -- Schritt 2: Nach kurzem Wait refreshen
    vim.defer_fn(function()
      -- Versuche zuerst den aktuellen State zu refreshen
      local state_ok, state = pcall(manager.get_state, state_name)
      if state_ok and state then
        local commands_ok, commands = pcall(require, "neo-tree.sources." .. state_name .. ".commands")
        if commands_ok and commands and type(commands.refresh) == "function" then
          pcall(commands.refresh, state)
          return
        end
      end

      -- Fallback: Refresh über Manager
      pcall(manager.refresh, state_name)

      -- Zusätzlicher Fallback für filesystem
      if state_name ~= "filesystem" then
        pcall(manager.refresh, "filesystem")
      end
    end, 100)
  end)
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

  local marked = tree.get_marked_nodes and tree:get_marked_nodes() or {}

  if marked and #marked > 0 then
    return marked
  end

  local node = tree:get_node()
  if node then
    return { node }
  end

  return {}
end

--- Neo-tree mapping callback: move selected node to Trash and refresh the Neo-tree view.
---@param state table
---@return nil
local function neotree_send_node_to_trash(state)
  local nodes = get_nodes_to_trash(state)

  if #nodes == 0 then
    vim.notify("No nodes selected", vim.log.levels.WARN)
    return
  end

  -- Sammle Pfade
  ---@type string[]
  local paths = {}
  for i = 1, #nodes do
    local node = nodes[i]
    local path = node.path or node.uri or node:get_id()
    if path then
      paths[#paths + 1] = path
    end
  end

  if #paths == 0 then
    vim.notify("No valid paths found", vim.log.levels.ERROR)
    return
  end

  -- Bestätigungsdialog (Batch-aware)
  local prompt
  if #paths == 1 then
    prompt = string.format("Move to Trash: %s ? (y/N) ", paths[1])
  else
    prompt = string.format("Move %d items to Trash? (y/N) ", #paths)
  end

  local ans = vim.fn.input(prompt)
  vim.api.nvim_command("redraw")

  if ans ~= "y" and ans ~= "Y" then
    vim.notify("Cancelled", vim.log.levels.INFO)
    return
  end

  vim.notify("Moving to Trash...", vim.log.levels.INFO)

  -- Cleanup vorab
  for i = 1, #paths do
    local path = paths[i]
    cleanup_neotree_watchers(path)
    close_related_buffers_and_previews(path)
  end

  -- Asynchron batchweise löschen
  vim.schedule(function()
    vim.defer_fn(function()
      local failed = false

      for i = 1, #paths do
        local path = paths[i]
        local ok, msg = send_to_trash(path)
        if not ok then
          failed = true
          local clean_msg = msg:match("([^\r\n]+)") or msg
          vim.notify("✗ Failed: " .. clean_msg, vim.log.levels.ERROR)
        end
      end

      vim.defer_fn(function()
        safe_refresh(state.name or "filesystem")
      end, 200)

      if not failed then
        vim.notify("✓ Moved to Trash (" .. #paths .. " items)", vim.log.levels.INFO)
      end
    end, 150)
  end)
end

M.send_to_trash = send_to_trash
M.neotree_send_node_to_trash = neotree_send_node_to_trash

---@package
---@return NeoTreeTrash
return M
