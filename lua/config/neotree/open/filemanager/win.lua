---@module 'config.neotree.open.filemanager.win'
--- Windows-specific "open in file manager" for Neo-tree.
--- Hardened: checks for executables, handles WSL detection, ensures proper quoting
--- and provides improved diagnostics and deterministic fallbacks.

local notify = require("lib.notify").create("[config.neotree.open.filemanager.win]")

local node_utils = require("config.neotree.utils.node")

local M = {}

---@private
---@param p string
---@return string
local function to_winpath(p)
  -- Expand to absolute path, strip wrapping quotes, normalize slashes (keeps Windows style)
  p = vim.fn.fnamemodify(p, ":p")
  p = p:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
  p = p:gsub("/", "\\")
  return p
end

---@private
---@return boolean
local function is_wsl()
  -- Detect WSL via uname or env var. Returns true if running under WSL.
  local uname = (vim.loop and vim.loop.os_uname and vim.loop.os_uname().version) or ""
  if uname:match("Microsoft") or uname:match("microsoft") then
    return true
  end
  if vim.env and vim.env.WSL_DISTRO_NAME then
    return true
  end
  return false
end

---@private
---@param argv string[]  -- argument vector to spawn
---@param opts table|nil  -- options passed to vim.system or jobstart
---@param cb fun(success:boolean, code: integer|nil, stderr: string|nil)
local function spawn_detached(argv, opts, cb)
  opts = opts or {}
  if vim.system then
    -- Use vim.system; ensure detach if requested
    local system_opts = { text = true }
    if opts.detach then system_opts.detach = true end
    -- Pass argv as array: safe against quoting issues
    vim.system(argv, system_opts, function(res)
      if not res then
        cb(false, nil, "no response from vim.system")
        return
      end
      if res.code == 0 then
        cb(true, res.code, res.stderr)
      else
        cb(false, res.code, res.stderr)
      end
    end)
  else
    -- Fallback to jobstart. jobstart wants a list; `detach=true` avoids waiting.
    local jid = vim.fn.jobstart(argv, { detach = true })
    if jid > 0 then
      -- No reliable exit code available; assume success for spawn
      cb(true, nil, nil)
    else
      cb(false, nil, "jobstart failed or returned non-positive jid")
    end
  end
end

--- Attempt to open path in Explorer. Includes diagnostics and robust fallbacks.
--- Returns boolean: true if an attempt was made (successful spawn or fallback), false on early fatal checks.
---@param state Cfg.NeoTree.State
---@return boolean
function M.open(state)
  -- quick platform guard: allow only native Windows or WSL cases that can call explorer
  local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  local wsl = is_wsl()
  if not (is_win or wsl) then
    notify.warn("Open in Explorer: Windows/WSL only")
    return false
  end

  -- Get the currently focused node
  local node = state and state.current_node or nil

  -- Use refactored get_path from node_utils
  local raw, _ = node_utils.get_path(node)
  if raw == "" then
    notify.warn("Open in Explorer: no path under cursor")
    return false
  end

  -- Convert to Windows path
  local abs = to_winpath(raw)
  local is_dir = (vim.fn.isdirectory(abs) == 1)
  local dir = is_dir and abs or to_winpath(vim.fn.fnamemodify(abs, ":h"))

  -- If running under WSL, try to convert to Windows path via wslpath -w
  if wsl then
    -- try to get windows path using wslpath -w; fallback to original
    local ok, winpath = pcall(function()
      return vim.fn.systemlist({"wslpath", "-w", abs})[1] or ""
    end)
    if ok and winpath ~= "" then
      abs = winpath
      dir = is_dir and abs or vim.fn.systemlist({"wslpath", "-w", vim.fn.fnamemodify(abs, ":h")})[1] or dir
    end
  end

  -- check that explorer/cmd are available when needed
  if vim.fn.executable("explorer.exe") == 0 then
    notify.warn("explorer.exe not found in PATH")
  end
  if vim.fn.executable("cmd.exe") == 0 then
    notify.warn("cmd.exe not found in PATH")
  end

  -- Primary: use explorer.exe. For files use /select,<path>. Keep this as single argv element.
  local primary
  if is_dir then
    primary = { "explorer.exe", abs }
  else
    -- /select,<path> must be one argument so shell doesn't split on comma/space
    primary = { "explorer.exe", "/select," .. abs }
  end

  -- Fallback: use cmd.exe /C start "" "dir"
  -- make sure dir is a single argument (quoted if needed by system API)
  local fallback = { "cmd.exe", "/C", "start", "", dir }

  spawn_detached(primary, { detach = true }, function(success, code, stderr)
    if success then return end

    -- primary failed: try fallback and report diagnostics
    local msg = ("explorer primary failed (code=%s, stderr=%s). Trying cmd start fallback"):format(tostring(code), tostring(stderr))
    notify.warn(msg)
    spawn_detached(fallback, { detach = true }, function(s2, c2, e2)
      if not s2 then
        local err = ("Fallback also failed (code=%s, stderr=%s)").format(tostring(c2), tostring(e2))
        notify.error(err)
      end
    end)
  end)

  -- If vim.system is async, spawn_detached returns immediately; indicate attempt made
  return true
end

return M
