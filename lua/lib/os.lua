---@module 'lib.os'
--- Cross-platform OS utilities for Neovim.
--- This module provides a unified abstraction layer for:
---   • OS detection (Windows, WSL, Linux, macOS)
---   • Default state directory selection
---   • Shell selection and async run helpers (vim.system / jobstart fallback)
---   • Clipboard copy with platform-specific backends
---   • Path helpers (join/normalize, WSL <-> Windows conversion hooks)
---
--- It builds on your existing 'lib.is_wsl' single-function module.
--- Target: Linux/macOS first; adds robust Windows + WSL support.

---@version 1.0.0
---@diagnostic disable: unused-local, assign-type-mismatch

local uv = (vim and (vim.uv or vim.loop)) or nil

---@alias OSName "windows"|"wsl"|"linux"|"macos"

---@class OsShell
---@field prog string        -- executable to spawn (e.g. "sh" or "powershell")
---@field args string[]      -- arguments vector (no command yet)
---@field is_powershell boolean

---@class OsRunResult
---@field code integer
---@field signal integer
---@field stdout string
---@field stderr string

---@class OsModule
---@field is_windows fun(): boolean
---@field is_wsl fun(): boolean
---@field is_macos fun(): boolean
---@field is_linux fun(): boolean   -- true for Linux and WSL
---@field name fun(): OSName
---@field default_state_dir fun(appname: string): string
---@field shell fun(): OsShell
---@field run fun(cmd: string, cb: fun(ok:boolean, res:OsRunResult))  -- async; uses vim.system if available
---@field run_blocking fun(cmd: string): OsRunResult                 -- blocking fallback (rarely needed)
---@field copy_to_clipboard fun(text: string): boolean
---@field path_join fun(...: string): string
---@field to_unix_sep fun(path: string): string
---@field to_win_sep fun(path: string): string
---@field wsl_to_win fun(path: string): string                       -- no-op on non-WSL
---@field win_to_wsl fun(path: string): string                       -- no-op on non-WSL

local M ---@class OsModule
M = {}

-- Reuse your existing single-function detector.
-- Note: requiring the function directly avoids cyclic deps via 'lib.init'.
local detect_wsl = require("lib.is_wsl") -- returns function() -> boolean  :contentReference[oaicite:2]{index=2}

-- OS detection ---------------------------------------------------------------

--- Returns true if running on any Windows build (including from within Neovim-Qt).
function M.is_windows()
  -- Fast path: Vim feature flag
  if vim and vim.fn and (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1) then
    return true
  end
  -- Fallback: directory separator heuristic
  local cfg = package and package.config or nil
  return (type(cfg) == "string" and cfg:sub(1, 1) == "\\")
end

--- Returns true if running inside Windows Subsystem for Linux (WSL).
function M.is_wsl()
  return detect_wsl()
end

--- Returns true for macOS (Darwin).
function M.is_macos()
  if vim and vim.fn and vim.fn.has("mac") == 1 then
    return true
  end
  if uv and uv.os_uname then
    local ok, u = pcall(uv.os_uname)
    if ok and type(u) == "table" and (u.sysname == "Darwin") then
      return true
    end
  end
  return false
end

--- Returns true for Linux kernels (includes WSL).
function M.is_linux()
  if M.is_macos() or M.is_windows() then
    return false
  end
  if uv and uv.os_uname then
    local ok, u = pcall(uv.os_uname)
    if ok and type(u) == "table" and (u.sysname == "Linux") then
      return true
    end
  end
  -- Conservative default: treat unknown non-Windows/non-macOS as Linux-ish
  return true
end

--- Return canonical OS name.
---@return OSName
function M.name()
  if M.is_wsl() then return "wsl" end
  if M.is_windows() then return "windows" end
  if M.is_macos() then return "macos" end
  return "linux"
end

-- Paths ----------------------------------------------------------------------

--- Join path segments with the platform's native separator.
---@vararg string
---@return string
function M.path_join(...)
  local sep = M.is_windows() and "\\" or "/"
  local out = table.concat({ ... }, sep)
  -- De-duplicate accidental double separators (but keep UNC \\ on Windows)
  out = out:gsub(sep .. "+", sep)
  if M.is_windows() and out:match("^\\\\") then
    -- Preserve UNC prefix
    return "\\" .. out
  end
  return out
end

--- Normalize to Unix-style separators (useful for displaying paths).
---@param p string
---@return string
function M.to_unix_sep(p)
  return (p:gsub("\\", "/"))
end

--- Normalize to Windows-style separators.
---@param p string
---@return string
function M.to_win_sep(p)
  return (p:gsub("/", "\\"))
end

--- WSL → Windows path conversion using `wslpath -w`, if available.
---@param p string
---@return string
function M.wsl_to_win(p)
  if not M.is_wsl() then return p end
  local res = M.run_blocking("wslpath -w " .. vim.fn.shellescape(p))
  if res.code == 0 and res.stdout and #res.stdout > 0 then
    return (res.stdout:gsub("%s+$", ""))
  end
  return p
end

--- Windows → WSL path conversion using `wslpath -u`, if available.
---@param p string
---@return string
function M.win_to_wsl(p)
  if not M.is_wsl() then return p end
  local res = M.run_blocking("wslpath -u " .. vim.fn.shellescape(p))
  if res.code == 0 and res.stdout and #res.stdout > 0 then
    return (res.stdout:gsub("%s+$", ""))
  end
  return p
end

--- Compute a robust default state directory for an app.
---@param appname string
---@return string
function M.default_state_dir(appname)
  if M.is_windows() and not M.is_wsl() then
    local localapp = os.getenv("LOCALAPPDATA")
    if localapp and #localapp > 0 then
      return M.path_join(localapp, "nvim", appname)
    end
    local userprof = os.getenv("USERPROFILE")
    if userprof and #userprof > 0 then
      return M.path_join(userprof, "AppData", "Local", "nvim", appname)
    end
    return "C:\\Temp\\nvim\\" .. appname
  end

  -- Linux / macOS / WSL → XDG_STATE_HOME fallback HOME/.local/state
  local xdg = os.getenv("XDG_STATE_HOME")
  if xdg and #xdg > 0 then
    return M.path_join(xdg, "nvim", appname)
  end
  local home = os.getenv("HOME")
  if home and #home > 0 then
    return M.path_join(home, ".local", "state", "nvim", appname)
  end
  -- Very last resort:
  return "/tmp/nvim-" .. appname
end

-- Shell selection and runners -------------------------------------------------

--- Pick a shell suitable for the platform.
---@return OsShell
function M.shell()
  if M.is_windows() and not M.is_wsl() then
    return { prog = "powershell", args = { "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command" }, is_powershell = true }
  end
  return { prog = "sh", args = { "-lc" }, is_powershell = false }
end

--- Async run using vim.system when available; falls back to jobstart.
---@param cmd string
---@param cb fun(ok:boolean, res:OsRunResult)
function M.run(cmd, cb)
  local sh = M.shell()
  local function pack(code, signal, stdout, stderr)
    return { code = code or 0, signal = signal or 0, stdout = stdout or "", stderr = stderr or "" }
  end

  if vim.system then
    vim.system({ sh.prog, sh.args[1], sh.args[2], sh.args[3], cmd }, { text = true }, function(obj)
      cb(obj.code == 0, pack(obj.code, obj.signal, obj.stdout, obj.stderr))
    end)
    return
  end

  -- Legacy fallback
  local full = sh.prog .. " " .. table.concat(sh.args, " ") .. " " .. cmd
  local stdout, stderr = {}, {}
  local jid = vim.fn.jobstart(full, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data) if data then stdout = data end end,
    on_stderr = function(_, data) if data then stderr = data end end,
    on_exit = function(_, code, signal)
      cb(code == 0, pack(code, signal, table.concat(stdout, "\n"), table.concat(stderr, "\n")))
    end,
  })
  if jid <= 0 then
    cb(false, pack(1, 0, "", "jobstart failed"))
  end
end

--- Blocking run (utility for quick conversions / probing).
---@param cmd string
---@return OsRunResult
function M.run_blocking(cmd)
  local sh = M.shell()
  if vim.system then
    local obj = vim.system({ sh.prog, sh.args[1], sh.args[2], sh.args[3], cmd }, { text = true }):wait()
    return { code = obj.code or 1, signal = obj.signal or 0, stdout = obj.stdout or "", stderr = obj.stderr or "" }
  end
  -- Minimal blocking fallback via systemlist()
  local full = sh.prog .. " " .. table.concat(sh.args, " ") .. " " .. cmd
  local ok, out = pcall(vim.fn.systemlist, full)
  local code = vim.v.shell_error or 1
  return {
    code = code,
    signal = 0,
    stdout = ok and table.concat(out, "\n") or "",
    stderr = ok and "" or
        "systemlist failed"
  }
end

-- Clipboard ------------------------------------------------------------------

--- Copy text to system clipboard using platform-appropriate backend.
---@param text string
---@return boolean
function M.copy_to_clipboard(text)
  -- 1) Try Neovim register (+)
  local ok = pcall(vim.fn.setreg, "+", text)
  if ok then return true end

  -- 2) macOS pbcopy
  if M.is_macos() then
    local res = M.run_blocking("pbcopy")
    if res.code == 0 then return true end
  end

  -- 3) Linux: xclip / wl-copy (best effort)
  if M.is_linux() and not M.is_wsl() then
    local r1 = M.run_blocking("xclip -selection clipboard", text)
    if r1.code == 0 then return true end
    local r2 = M.run_blocking("wl-copy", text)
    if r2.code == 0 then return true end
  end

  -- 4) Windows native PowerShell
  if M.is_windows() and not M.is_wsl() then
    local cmd = "$input | Set-Clipboard"
    local sh = M.shell()
    local obj = vim.system and vim.system({ sh.prog, sh.args[1], sh.args[2], sh.args[3], cmd }, { stdin = text }):wait()
    return (obj and obj.code == 0)
  end

  -- 5) WSL → clip.exe (Windows clipboard)
  if M.is_wsl() then
    local obj = vim.system and vim.system({ "clip.exe" }, { stdin = text }):wait()
    return (obj and obj.code == 0)
  end

  return false
end

return M
