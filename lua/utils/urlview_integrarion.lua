---@module 'urlview_integration'
--- Cross-platform integration for urlview.nvim to open selected URLs
--- in the system default browser. Supports Windows (native), WSL, Linux, and macOS.
--- Provides a custom urlview action "open_in_browser" that can be set as default_action.

--- Note:
---   * Requires urlview.nvim installed and loaded
---   * For WSL, "wslview" (from package "wslu") is recommended
---   * Uses `vim.system` if available (Neovim 0.10+), else falls back to `vim.fn.jobstart`

---@class UrlviewIntegration
---@field uses_system_opener boolean

local M = {}

---@class ProcResult
---@field code integer
---@field signal integer|nil

--- Check if current Neovim runs inside WSL
---@return boolean
local function is_wsl()
  -- `has('wsl')` is not universal. We detect via uname string heuristics.
  local uname = vim.loop.os_uname().release or ""
  return uname:lower():find("microsoft") ~= nil or uname:lower():find("wsl") ~= nil
end

--- Check if current Neovim runs on Windows (native)
---@return boolean
local function is_windows()
  -- `has('win32')` is true for Windows
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

--- Portable system-call wrapper: prefer vim.system, fallback to jobstart
---@param cmd string[]  -- command and arguments
---@param cb fun(ok:boolean, code:integer|nil, stdout:string|nil, stderr:string|nil)  -- completion callback
local function run_async(cmd, cb)
  -- Neovim >= 0.10 has vim.system
  if vim.system then
    vim.system(cmd, { text = true }, function(obj)
      local ok = (obj.code == 0)
      cb(ok, obj.code, obj.stdout, obj.stderr)
    end)
    return
  end

  -- Fallback: jobstart (Neovim < 0.10)
  local stdout_chunks = {} ---@type string[]
  local stderr_chunks = {} ---@type string[]

  local job = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      if data and #data > 0 then
        table.insert(stdout_chunks, table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data, _)
      if data and #data > 0 then
        table.insert(stderr_chunks, table.concat(data, "\n"))
      end
    end,
    on_exit = function(_, code, _)
      local ok = (code == 0)
      cb(ok, code, table.concat(stdout_chunks, "\n"), table.concat(stderr_chunks, "\n"))
    end,
  })

  if job <= 0 then
    cb(false, nil, nil, "Failed to start job")
  end
end

--- Build the platform-appropriate launcher command for a URL
---@param url string
---@return string[] cmd  -- command array suitable for run_async
local function build_open_cmd(url)
  -- We deliberately avoid quoting within a shell string; instead pass argv array,
  -- so spaces/special chars in URL are handled safely.

  if is_windows() and not is_wsl() then
    -- Windows native Neovim:
    -- Use `cmd.exe /c start "" <url>`
    -- The empty string "" is the window title placeholder required by start.
    return { "cmd.exe", "/c", "start", "", url }
  end

  if is_wsl() then
    -- Prefer wslview if available; else fallback to Windows opener via cmd.exe
    if vim.fn.executable("wslview") == 1 then
      return { "wslview", url }
    end
    return { "cmd.exe", "/c", "start", "", url }
  end

  -- POSIX platforms
  if vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
    -- macOS
    return { "open", url }
  end

  -- Linux/BSD
  if vim.fn.executable("xdg-open") == 1 then
    return { "xdg-open", url }
  end

  -- As a last resort on POSIX, try `open` (some BSDs), else error
  if vim.fn.executable("open") == 1 then
    return { "open", url }
  end

  return {} -- signals unsupported
end

--- Normalize/validate URL before opening
---@param raw_url string
---@return string|nil url  -- returns nil if not openable
local function sanitize_url(raw_url)
  local url = vim.trim(raw_url or "")
  if url == "" then
    return nil
  end
  -- urlview already gives real URLs; still allow mailto:, http(s), file:, etc.
  -- Basic heuristic: if scheme missing, try to prepend "http://"
  if not url:match("^%a[%w+.-]*:") then
    url = "http://" .. url
  end
  return url
end

--- Open URL via appropriate system opener; notifies on failure
---@param raw_url string
---@return nil
local function open_url(raw_url)
  local url = sanitize_url(raw_url)
  if not url then
    vim.notify("[urlview] Invalid or empty URL", vim.log.levels.WARN)
    return
  end

  local cmd = build_open_cmd(url)
  if #cmd == 0 then
    vim.notify("[urlview] No suitable system opener found", vim.log.levels.ERROR)
    return
  end

  ---@diagnostic disable-next-line
  run_async(cmd, function(ok, code, _stdout, stderr)
    if not ok then
      local msg = string.format("[urlview] Failed to open URL (exit=%s): %s", tostring(code), tostring(stderr or ""))
      vim.notify(msg, vim.log.levels.ERROR)
    end
  end)
end

--- Register custom action with urlview
---@return nil
function M.register_action()
  local ok, actions = pcall(require, "urlview.actions")
  if not ok then
    vim.notify("[urlview] Could not load urlview.actions", vim.log.levels.ERROR)
    return
  end

  ---@param raw_url string
  actions["open_in_browser"] = function(raw_url)
    -- By design, the "system" opener usually opens in a new tab/window,
    -- depending on the platform/browser defaults.
    open_url(raw_url)
  end
end

--- Optional: configure urlview with this custom action as default
---@param opts table|nil  -- merges into urlview.setup
---@return nil
function M.setup(opts)
  M.register_action()

  local ok, urlview = pcall(require, "urlview")
  if not ok then
    vim.notify("[urlview] urlview.nvim is not installed/loaded", vim.log.levels.ERROR)
    return
  end

  -- Merge defaults with user opts
  opts = opts or {}
  if opts.default_action == nil then
    -- Use our cross-platform action as default
    opts.default_action = "open_in_browser"
  end
  -- Optional: set Telescope as default picker if available
  if opts.default_picker == nil and pcall(require, "telescope") then
    opts.default_picker = "telescope"
  end

  urlview.setup(opts)
end

return M

