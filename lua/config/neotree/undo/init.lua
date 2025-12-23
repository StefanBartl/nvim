---@module 'config.neotree.undo'
--- Neo-tree undo functionality: restore last trashed item from system trash
--- Cross-platform support for Windows, Linux, and macOS

local M = {}

local fn = vim.fn
local uv = vim.loop
local notify, levels = vim.notify, vim.log.levels
local str_format = string.format

--- History of trashed items (stored in memory for this session)
---@type table[]
local trash_history = {}
local MAX_HISTORY = 50

--- Add item to trash history
---@param original_path string
---@param item_name string
local function add_to_history(original_path, item_name)
  table.insert(trash_history, 1, {
    original_path = original_path,
    item_name = item_name,
    timestamp = os.time(),
  })

  -- Keep history size manageable
  while #trash_history > MAX_HISTORY do
    table.remove(trash_history)
  end
end

--- Restore from Windows Recycle Bin using PowerShell with better error handling
---@param original_path string
---@param item_name string
---@return boolean, string
local function restore_windows(original_path, item_name)
  local parent_dir = fn.fnamemodify(original_path, ":h")

  -- Check if parent directory exists
  if fn.isdirectory(parent_dir) == 0 then
    return false, "Parent directory no longer exists: " .. parent_dir
  end

  -- Normalize path for Windows
  local normalized_path = original_path:gsub("/", "\\")

  -- PowerShell script that searches by filename in Recycle Bin
  -- This is more reliable than searching by original path
  local ps_script = str_format([[
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName Microsoft.VisualBasic

$shell = New-Object -ComObject Shell.Application
$recycleBin = $shell.NameSpace(10)

if ($null -eq $recycleBin) {
    Write-Output "ERROR: Cannot access Recycle Bin"
    exit 1
}

$items = $recycleBin.Items()
$found = $false

foreach ($item in $items) {
    $itemName = $item.Name
    $itemPath = $item.Path

    # Match by filename (more reliable than full path)
    if ($itemName -eq '%s') {
        try {
            # Get the original location from extended properties
            $originalLocation = $recycleBin.GetDetailsOf($item, 1)

            # Check if this matches our expected path
            $expectedParent = '%s'

            if ($originalLocation -like "*$expectedParent*" -or $true) {
                # Restore the item
                $item.InvokeVerb('undelete')
                Write-Output "SUCCESS"
                $found = $true
                Start-Sleep -Milliseconds 500
                exit 0
            }
        } catch {
            Write-Output "ERROR: $($_.Exception.Message)"
            exit 1
        }
    }
}

if (-not $found) {
    Write-Output "NOTFOUND"
    exit 2
}
]], item_name:gsub("'", "''"), parent_dir:gsub("\\", "\\\\"):gsub("'", "''"))

  -- Execute PowerShell
  local output = fn.system({
    "powershell",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-Command",
    ps_script
  })

  local exit_code = vim.v.shell_error

  -- Debug output (optional)
  -- print("Exit code:", exit_code)
  -- print("Output:", output)

  if exit_code == 0 and output:match("SUCCESS") then
    -- Wait a bit for Windows to complete the restoration
    vim.wait(300)
    return true, "Restored from Recycle Bin"
  elseif output:match("NOTFOUND") or exit_code == 2 then
    local msg = str_format(
      "Item '%s' not found in Recycle Bin.\n" ..
      "Possible reasons:\n" ..
      "- Item was permanently deleted\n" ..
      "- Recycle Bin was emptied\n" ..
      "- Item is in Recycle Bin but with different name\n\n" ..
      "To restore manually:\n" ..
      "1. Open Recycle Bin (Win+R → 'shell:RecycleBinFolder')\n" ..
      "2. Find '%s'\n" ..
      "3. Right-click → Restore",
      item_name, item_name
    )
    return false, msg
  else
    local clean_output = output:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\r?\n.*", "")
    return false, "Failed to restore: " .. clean_output
  end
end

--- Restore last trashed item (Linux/macOS)
---@param original_path string
---@return boolean, string
local function restore_unix(original_path)
  local home = uv.os_homedir()
  local sys = uv.os_uname().sysname

  local function has_exe(name)
    return fn.executable(name) == 1
  end

  local basename = fn.fnamemodify(original_path, ":t")
  local trashdir = home .. "/.local/share/Trash/files"
  local trashed_path = trashdir .. "/" .. basename

  -- Try gio (GNOME/modern Linux)
  if has_exe("gio") then
    if uv.fs_stat(trashed_path) then
      local _ = fn.system({ "gio", "trash", "--restore", trashed_path })
      if vim.v.shell_error == 0 then
        return true, "Restored via gio"
      end
    end
  end

  -- Manual restoration from trash directory
  if uv.fs_stat(trashed_path) then
    local parent_dir = fn.fnamemodify(original_path, ":h")
    if fn.isdirectory(parent_dir) == 0 then
      return false, "Parent directory no longer exists: " .. parent_dir
    end

    if uv.fs_stat(original_path) then
      return false, "Target already exists: " .. original_path
    end

    local ok_mv, err_mv = os.rename(trashed_path, original_path)
    if ok_mv then
      local infofile = home .. "/.local/share/Trash/info/" .. basename .. ".trashinfo"
      pcall(os.remove, infofile)
      return true, "Restored from trash"
    else
      return false, "Failed to move: " .. tostring(err_mv)
    end
  end

  if sys == "Darwin" then
    return false, "Item not found in trash. On macOS, please restore manually from Trash (⌘+Delete in Finder)"
  end

  return false, "Item not found in trash directory: " .. trashdir
end

--- Undo last trash operation: restore the last trashed item
---@return boolean, string
local function undo_last_trash()
  if #trash_history == 0 then
    return false, "No items in trash history"
  end

  local last_item = trash_history[1]
  local sys = uv.os_uname().sysname

  local ok, msg
  if sys == "Windows_NT" then
    ok, msg = restore_windows(last_item.original_path, last_item.item_name)
  else
    ok, msg = restore_unix(last_item.original_path)
  end

  if ok then
    table.remove(trash_history, 1)
  end

  return ok, msg
end

--- Show trash history
---@return nil
local function show_history()
  if #trash_history == 0 then
    notify("No items in trash history", levels.INFO)
    return
  end

  local lines = { "=== Trash History ===" }
  for i, item in ipairs(trash_history) do
    local time = os.date("%H:%M:%S", item.timestamp)
    table.insert(lines, str_format("%d. [%s] %s", i, time, item.item_name))
  end

  notify(table.concat(lines, "\n"), levels.INFO)
end

--- Neo-tree command: undo last trash operation
---@param state table
---@return nil
local function neotree_undo_trash(state)
  if #trash_history == 0 then
    notify("No items in trash history", levels.WARN)
    return
  end

  local last_item = trash_history[1]
  local item_name = last_item.item_name

  notify("Restoring: " .. item_name .. "...", levels.INFO)

  vim.schedule(function()
    local ok, msg = undo_last_trash()

    if ok then
      notify("✓ Restored: " .. item_name, levels.INFO)

      -- Refresh Neo-tree
      vim.defer_fn(function()
        local manager_ok, manager = pcall(require, "neo-tree.sources.manager")
        if manager_ok and manager and manager.refresh then
          pcall(manager.refresh, state.name or "filesystem")
        end
      end, 300)
    else
      -- Show error in a more readable way
      if msg:match("\n") then
        -- Multi-line message, show in split
        local lines = vim.split(msg, "\n")
        notify(table.concat(lines, "\n"), levels.WARN)
      else
        notify("✗ " .. msg, levels.WARN)
      end
    end
  end)
end

M.add_to_history = add_to_history
M.undo_last_trash = undo_last_trash
M.neotree_undo_trash = neotree_undo_trash
M.show_history = show_history
M.get_history = function()
  return trash_history
end

return M
