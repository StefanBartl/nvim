---@module 'custom.pdfport.platform'
---@brief OS detection and external tool availability for pdfport.
---@description
--- Provides cached runtime checks for OS type and the presence of
--- external binaries required by the various backends and renderers.
--- All checks are memoized after first evaluation to avoid repeated
--- filesystem or process-spawn overhead during startup.

local M = {}

local uv = vim.uv or vim.loop

-- #############################################################################
-- Internal cache
-- #############################################################################

---@type table<string, boolean>
local _exe_cache = {}

---@type string|nil
local _os_cache = nil

-- #############################################################################
-- OS detection
-- #############################################################################

--- Returns the current operating system identifier.
---@return "windows"|"macos"|"linux"|"unknown"
function M.os()
  if _os_cache then
    return _os_cache
  end

  local sysname = (uv.os_uname() or {}).sysname or ""

  if sysname:match("Windows") then
    _os_cache = "windows"
  elseif sysname:match("Darwin") then
    _os_cache = "macos"
  elseif sysname:match("Linux") then
    _os_cache = "linux"
  else
    _os_cache = "unknown"
  end

  return _os_cache
end

--- Returns true when running inside WSL.
---@return boolean
function M.is_wsl()
  if M.os() ~= "linux" then
    return false
  end

  local f = io.open("/proc/version", "r")
  if not f then
    return false
  end

  local content = f:read("*a")
  f:close()
  return content:lower():find("microsoft") ~= nil
end

-- #############################################################################
-- Executable detection
-- #############################################################################

--- Returns true when the given binary is reachable on PATH.
---@param exe string  Binary name (e.g. "pdftotext", "python3")
---@return boolean
function M.has(exe)
  if _exe_cache[exe] ~= nil then
    return _exe_cache[exe]
  end

  local result = vim.fn.executable(exe) == 1
  _exe_cache[exe] = result
  return result
end

--- Returns the first executable from the provided list, or nil.
---@param executables string[]
---@return string|nil
function M.first_available(executables)
  for i = 1, #executables do
    if M.has(executables[i]) then
      return executables[i]
    end
  end
  return nil
end

-- #############################################################################
-- Python module detection
-- #############################################################################

--- Returns true when the given Python module can be imported.
--- Uses the system python3 binary; result is cached.
---@param module string  Python module name (e.g. "pdfplumber", "marker")
---@return boolean
function M.has_python_module(module)
  local cache_key = "pymod:" .. module
  if _exe_cache[cache_key] ~= nil then
    return _exe_cache[cache_key]
  end

  if not M.has("python3") then
    _exe_cache[cache_key] = false
    return false
  end

  -- Spawn python3 -c "import <module>" synchronously via vim.fn.system
  local cmd = string.format("python3 -c 'import %s' 2>/dev/null", module)
  local exit = os.execute(cmd)
  local result = (exit == 0)
  _exe_cache[cache_key] = result
  return result
end

-- #############################################################################
-- System open command
-- #############################################################################

--- Returns the system command used to open files with their default application.
---@return string|nil  Command string or nil if none found
function M.open_cmd()
  local os = M.os()

  if os == "macos" then
    return "open"
  elseif os == "linux" or os == "unknown" then
    -- xdg-open is standard; wsl-open is available in some WSL setups
    return M.first_available({ "xdg-open", "wsl-open" })
  elseif os == "windows" then
    return "start"
  end

  return nil
end

-- #############################################################################
-- Terminal image renderer detection
-- #############################################################################

--- Returns the best available terminal image renderer.
---@return "ueberzug"|"chafa"|"kitty"|"imgcat"|nil
function M.best_terminal_renderer()
  -- ueberzug++ is the most capable on X11/Wayland
  if M.has("ueberzugpp") or M.has("ueberzug") then
    return "ueberzug"
  end

  -- kitty icat protocol (only works inside kitty terminal)
  local term = vim.env.TERM or ""
  local term_prog = vim.env.TERM_PROGRAM or ""
  if term == "xterm-kitty" or term_prog == "kitty" then
    if M.has("kitten") or M.has("kitty") then
      return "kitty"
    end
  end

  -- imgcat (iTerm2, some other terminals)
  if M.has("imgcat") then
    return "imgcat"
  end

  -- chafa: universal fallback, works in any terminal (ASCII art mode)
  if M.has("chafa") then
    return "chafa"
  end

  return nil
end

-- #############################################################################
-- Cache invalidation (for tests / hot-reload)
-- #############################################################################

--- Clears all cached detection results.
function M.reset_cache()
  _exe_cache = {}
  _os_cache = nil
end

return M
