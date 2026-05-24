---@module 'config.neotree.open.filemanager.win'
---@brief Windows-specific file manager integration for Neo-tree.
---@description
--- Opens the currently focused Neo-tree node (file or directory) in Windows
--- Explorer. Supports both native Win32 and WSL environments.
---
--- Hardened against:
---   - missing nodes / empty paths
---   - WSL path translation failures
---   - unavailable executables (explorer.exe, cmd.exe)
---   - async spawn failures with deterministic fallback chain

local notify     = require("lib.notify").create("[config.neotree.open.filemanager.win]")
local node_utils = require("config.neotree.utils.node")

local M = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

---Convert a POSIX-style path to a Windows-style path.
---Expands to absolute, strips surrounding quotes, replaces forward slashes.
---@private
---@param p string
---@return string
local function to_winpath(p)
  p = vim.fn.fnamemodify(p, ":p")
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  p = p:gsub("/", "\\")
  return p
end

---Detect whether the current process runs inside WSL.
---Checks the uname version string and the WSL_DISTRO_NAME environment variable.
---@private
---@return boolean
local function is_wsl()
  local uv    = vim.uv or vim.loop
  local uname = (uv and uv.os_uname and uv.os_uname().version) or ""
  if uname:match("[Mm]icrosoft") then
    return true
  end
  if vim.env and vim.env.WSL_DISTRO_NAME then
    return true
  end
  return false
end

---Spawn an external command without blocking the editor.
---Prefers vim.system (Neovim >= 0.10); falls back to vim.fn.jobstart.
---@private
---@param argv    string[]                                         Argument vector; argv[1] is the executable.
---@param cb      fun(success: boolean, code: integer|nil, stderr: string|nil)
local function spawn_detached(argv, cb)
  if vim.system then
    vim.system(argv, { text = true, detach = true }, function(res)
      if not res then
        cb(false, nil, "no response from vim.system")
        return
      end
      cb(res.code == 0, res.code, res.stderr)
    end)
  else
    local jid = vim.fn.jobstart(argv, { detach = true })
    -- jobstart does not expose an exit code synchronously; treat positive jid as success
    cb(jid > 0, nil, jid <= 0 and "jobstart returned non-positive jid" or nil)
  end
end

---Translate a Linux absolute path to its Windows counterpart inside WSL.
---Returns the original path unchanged when wslpath is unavailable or fails.
---@private
---@param path string
---@return string
local function wsl_to_win(path)
  if vim.fn.executable("wslpath") == 0 then
    return path
  end
  local ok, lines = pcall(vim.fn.systemlist, { "wslpath", "-w", path })
  if ok and lines and lines[1] and lines[1] ~= "" then
    return lines[1]
  end
  return path
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Open the Neo-tree node under the cursor in Windows Explorer.
---
---For file nodes, Explorer is invoked with `/select,<path>` so the file is
---highlighted inside its parent directory.
---For directory nodes, Explorer opens the directory directly.
---
---Falls back to `cmd.exe /C start "" "<dir>"` when the primary invocation fails.
---
---@param state Cfg.NeoTree.State
---@return boolean success False when no path could be resolved or the platform guard fires.
function M.open(state)
  -- Platform guard: only meaningful on Windows or WSL
  local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  local wsl    = is_wsl()
  if not (is_win or wsl) then
    notify.warn("Open in Explorer: Windows or WSL required")
    return false
  end

  -- Resolve the focused node via the tree, not via state.current_node which
  -- is not a stable Neo-tree API field and is typically nil.
  local node = node_utils.get_current(state)
  if not node then
    notify.warn("Open in Explorer: no node under cursor")
    return false
  end

  local raw, _ = node_utils.get_path(node)
  if raw == "" then
    notify.warn("Open in Explorer: no path under cursor")
    return false
  end

  -- Convert to Windows-style path; apply WSL translation when needed
  local abs = wsl and wsl_to_win(raw) or to_winpath(raw)
  if abs == "" then
    notify.warn("Open in Explorer: path translation failed")
    return false
  end

  local is_dir = vim.fn.isdirectory(abs) == 1
  local dir    = is_dir and abs
    or (wsl and wsl_to_win(vim.fn.fnamemodify(raw, ":h")) or to_winpath(vim.fn.fnamemodify(raw, ":h")))

  -- Warn early when executables are missing (non-fatal; spawn may still work via PATH)
  if vim.fn.executable("explorer.exe") == 0 then
    notify.warn("Open in Explorer: explorer.exe not found in PATH")
  end

  -- Build the primary argument vector.
  -- /select,<path> must be passed as a single element; the Windows API handles
  -- the comma separator internally — no shell quoting issue when using argv arrays.
  local primary = is_dir
    and { "explorer.exe", abs }
    or  { "explorer.exe", "/select," .. abs }

  -- Fallback: cmd.exe /C start opens the directory in the default file manager
  local fallback = { "cmd.exe", "/C", "start", "", dir }

  spawn_detached(primary, function(ok, code, stderr)
    if ok then
      return
    end

    -- Primary failed; log diagnostics and attempt fallback
    notify.warn(("explorer.exe failed (code=%s, stderr=%s) — trying cmd fallback"):format(
      tostring(code),
      tostring(stderr)
    ))

    spawn_detached(fallback, function(ok2, code2, stderr2)
      if not ok2 then
        notify.error(("cmd fallback also failed (code=%s, stderr=%s)"):format(
          tostring(code2),
          tostring(stderr2)
        ))
      end
    end)
  end)

  -- spawn_detached is async; returning true signals that an attempt was initiated
  return true
end

return M
