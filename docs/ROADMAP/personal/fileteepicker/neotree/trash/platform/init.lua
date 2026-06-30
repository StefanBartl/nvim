---@module 'config.neotree.trash.platform'
---@brief Cross-platform trash implementation

local M = {}

local uv = vim.loop
local fn = vim.fn
local str_format = string.format

---Escape shell argument
---@param path string
---@return string
local function escape_arg(path)
  if uv.os_uname().sysname == "Windows_NT" then
    return "'" .. path:gsub("'", "''") .. "'"
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

---Send to trash on Windows
---@param path string
---@return boolean success
---@return string message
local function windows_trash(path)
  local esc = escape_arg(path)
  local stat = uv.fs_stat(path)
  local is_dir = stat and stat.type == "directory"

  local ps_script
  if is_dir then
    ps_script = str_format(
      "$ErrorActionPreference='Stop'; "
        .. "Add-Type -AssemblyName Microsoft.VisualBasic; "
        .. "try { "
        .. "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(%s,'OnlyErrorDialogs','SendToRecycleBin') "
        .. "} catch { Write-Error $_.Exception.Message; exit 1 }",
      esc
    )
  else
    ps_script = str_format(
      "$ErrorActionPreference='Stop'; "
        .. "Add-Type -AssemblyName Microsoft.VisualBasic; "
        .. "try { "
        .. "[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(%s,'OnlyErrorDialogs','SendToRecycleBin') "
        .. "} catch { Write-Error $_.Exception.Message; exit 1 }",
      esc
    )
  end

  local out = fn.system({ "powershell", "-NoProfile", "-Command", ps_script })
  local ok = vim.v.shell_error == 0

  if not ok and is_dir then
    -- Fallback
    local fallback = str_format(
      "$path = %s; "
        .. "if (Test-Path $path) { "
        .. "Get-ChildItem -Path $path -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; "
        .. "Remove-Item -Path $path -Force -Recurse -ErrorAction Stop }",
      esc
    )
    local _ = fn.system({ "powershell", "-NoProfile", "-Command", fallback })
    ok = vim.v.shell_error == 0
    if ok then
      return true, "moved via fallback"
    end
  end

  return ok, out
end

---Send to trash on Unix (Linux/macOS)
---@param path string
---@return boolean success
---@return string message
local function unix_trash(path)
  local sys = uv.os_uname().sysname
  local esc = escape_arg(path)

  local function has(cmd)
    return fn.executable(cmd) == 1
  end

  if has("gio") then
    local out = fn.system({ "gio", "trash", path })
    return vim.v.shell_error == 0, out
  elseif has("trash") then
    local out = fn.system({ "trash", path })
    return vim.v.shell_error == 0, out
  elseif has("trash-put") then
    local out = fn.system({ "trash-put", path })
    return vim.v.shell_error == 0, out
  elseif has("kioclient5") then
    local out = fn.system({ "kioclient5", "move", path, "trash:/" })
    return vim.v.shell_error == 0, out
  elseif sys == "Darwin" and has("osascript") then
    local script = str_format('tell application "Finder" to delete POSIX file %s', esc)
    local out = fn.system({ "osascript", "-e", script })
    return vim.v.shell_error == 0, out
  else
    -- Manual trash
    local home = uv.os_homedir()
    local trashdir = home .. "/.local/share/Trash/files"
    if not uv.fs_stat(trashdir) then
      local ok, err = pcall(fn.mkdir, trashdir, "p")
      if not ok then
        return false, "failed to create trash dir: " .. tostring(err)
      end
    end
    local dest = trashdir .. "/" .. fn.fnamemodify(path, ":t")
    local ok, err = os.rename(path, dest)
    return ok == true, ok and ("moved to " .. dest) or tostring(err)
  end
end

---Send file/directory to system trash
---@param path string
---@return boolean success
---@return string message
function M.send_to_trash(path)
  local sys = uv.os_uname().sysname

  if sys == "Windows_NT" then
    return windows_trash(path)
  else
    return unix_trash(path)
  end
end

return M
