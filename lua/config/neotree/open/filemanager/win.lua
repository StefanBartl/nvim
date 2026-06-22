---@module 'config.neotree.open.filemanager.win'
---@brief Windows Explorer integration for Neo-tree (Win32 and WSL).
---@description
--- Opens the focused Neo-tree node in Windows Explorer.
--- File nodes are opened with /select so the file is pre-selected.
--- Directory nodes open the directory directly.
---
--- WSL-specific behaviour:
---   - Path translation is handled via wslpath(1).
---   - Spawning uses cmd.exe /C start via vim.fn.jobstart (detach=true),
---     because vim.system with detach=true blocks the Neovim UI briefly
---     when crossing the WSL/Win32 interop boundary.
---   - isdirectory() is always called on the raw Linux path, not the
---     translated Windows path, because Neovim in WSL only sees the Linux VFS.

local notify     = require("lib.nvim.notify").create("[config.neotree.open.filemanager.win]")
local node_utils = require("config.neotree.utils.node")

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Detect whether Neovim is running inside a WSL environment.
---Checks both the kernel version string (covers WSL1 and WSL2) and the
---WSL_DISTRO_NAME environment variable (set by WSL2 user-space init).
---@private
---@return boolean
local function is_wsl()
  local uv    = vim.uv or vim.loop
  local uname = (uv and uv.os_uname and uv.os_uname().version) or ""
  if uname:match("[Mm]icrosoft") then
    return true
  end
  if vim.env and vim.env.WSL_DISTRO_NAME and vim.env.WSL_DISTRO_NAME ~= "" then
    return true
  end
  return false
end

---Convert a POSIX-style path to an absolute Windows-style path.
---Only used on native Win32, not in WSL (wsl_to_win handles WSL).
---@private
---@param p string  POSIX or mixed-style absolute path.
---@return string   Absolute Windows path with backslash separators.
local function to_winpath(p)
  p = vim.fn.fnamemodify(p, ":p")
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  p = p:gsub("/", "\\")
  -- Strip trailing backslash on non-root paths (e.g. C:\foo\ -> C:\foo)
  if #p > 3 then
    p = p:gsub("\\+$", "")
  end
  return p
end

---Translate a Linux absolute path to its Windows drive-letter path via wslpath.
---Returns the original path unchanged when wslpath is absent or fails, so
---callers never receive nil or an empty string from this function alone.
---@private
---@param path string  Absolute Linux path inside the WSL mount namespace.
---@return string      Windows path (e.g. C:\Users\...), or original on failure.
local function wsl_to_win(path)
  if vim.fn.executable("wslpath") == 0 then
    notify.warn("wslpath not found; cannot translate path to Windows format")
    return path
  end
  local ok, lines = pcall(vim.fn.systemlist, { "wslpath", "-w", path })
  if ok and lines and lines[1] and lines[1] ~= "" then
    return lines[1]
  end
  notify.warn(("wslpath failed for path: %s"):format(path))
  return path
end

---Spawn a detached Windows GUI process from WSL using cmd.exe /C start.
---
---Rationale for this approach:
---  vim.system({ detach=true }) crosses the WSL/Win32 interop boundary
---  synchronously for the duration of process creation, which freezes the
---  Neovim UI until the Windows process manager acknowledges the request.
---  vim.fn.jobstart with detach=true avoids this by handing the child to
---  Neovim's libuv job layer, which does not block the main loop.
---
---  cmd.exe /C start /B launches the target as a fully detached Windows
---  process, so neither cmd.exe nor the target block the WSL side.
---@private
---@param winpath string  Absolute Windows path to open (backslash-separated).
---@param select  boolean When true, open with /select (file pre-selection).
---@return boolean        True when jobstart accepted the command (jid > 0).
local function wsl_open(winpath, select)
  -- /B suppresses cmd from opening a new console window.
  -- The empty string after "start" is the window title (required positional arg).
  -- /select,<path> must be a single token; no additional quoting needed in argv.
  local target = select
    and ("explorer.exe /select," .. winpath)
    or  ("explorer.exe " .. winpath)

  local argv = { "cmd.exe", "/C", "start", "/B", "", target }

  local jid = vim.fn.jobstart(argv, { detach = true })
  if jid <= 0 then
    notify.error(("cmd.exe /C start failed (jid=%d) for: %s"):format(jid, winpath))
    return false
  end
  return true
end

---Spawn a detached GUI process on native Win32 using vim.system.
---On native Windows, vim.system with detach=true does not block the UI because
---Neovim runs as a full Win32 process and CreateProcess returns immediately.
---@private
---@param argv string[]  Full argument vector; argv[1] is the executable.
---@return boolean       True when the OS accepted the spawn request.
local function win32_open(argv)
  -- vim.system with detach=true is unreliable for GUI processes on Win32
  -- (explorer.exe may be killed when Neovim drops the process handle).
  -- Use the same cmd.exe /C start /B approach as WSL for consistency.
  local target = table.concat(argv, " ")
  local jid = vim.fn.jobstart(
    { "cmd.exe", "/C", "start", "/B", "", target },
    { detach = true }
  )
  if jid <= 0 then
    notify.error(("cmd.exe /C start failed (jid=%d) for: %s"):format(jid, target))
    return false
  end
  return true
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Open the focused Neo-tree node in Windows Explorer.
---
---On WSL: spawns via cmd.exe /C start /B using vim.fn.jobstart to avoid
---blocking the Neovim UI across the WSL/Win32 interop boundary.
---On native Win32: spawns explorer.exe directly via vim.system (detach=true).
---
---@param state Cfg.NeoTree.State
---@return boolean  False when the platform guard fires or path resolution fails.
function M.open(state)
  local wsl    = is_wsl()
  local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

  if not (is_win or wsl) then
    notify.warn("Open in Explorer: requires Windows or WSL environment")
    return false
  end

  local node = node_utils.get_current(state)
  if not node then
    notify.warn("Open in Explorer: no node under cursor")
    return false
  end

  -- raw is the Linux/POSIX path; always valid for Neovim VFS operations
  local raw = node_utils.get_path(node)
  if not raw or raw == "" then
    notify.warn("Open in Explorer: node has no resolvable path")
    return false
  end

  -- isdirectory() must be called on the raw Linux path in WSL because Neovim
  -- only has visibility into the Linux VFS, not the Windows filesystem.
  local is_dir = vim.fn.isdirectory(raw) == 1

  if wsl then
    -- Translate the target path (and parent dir for files) to Windows format
    local winpath = wsl_to_win(raw)
    if winpath == "" then
      notify.warn("Open in Explorer: WSL path translation returned empty result")
      return false
    end

    return wsl_open(winpath, not is_dir)
  end

  -- Native Win32: translate to backslash path and spawn explorer.exe directly
  local abs = to_winpath(raw)
  if abs == "" then
    notify.warn("Open in Explorer: path conversion returned empty result")
    return false
  end

  if vim.fn.executable("explorer.exe") == 0 then
    notify.warn("explorer.exe not found in PATH")
  end

  local argv = is_dir
    and { "explorer.exe", abs }
    or  { "explorer.exe", "/select," .. abs }

  return win32_open(argv)
end

return M
