---@module 'config.neotree.utils.platform'
---@brief Platform detection utilities

local M = {}

---@type boolean|nil
local _is_windows = nil

---@type boolean|nil
local _is_wsl = nil

---Check if running on Windows
---@return boolean
function M.is_windows()
  if _is_windows ~= nil then
    return _is_windows
  end

  _is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  return _is_windows
end

---Check if running on WSL
---@return boolean
function M.is_wsl()
  if _is_wsl ~= nil then
    return _is_wsl
  end

  -- Try user helper first
  local ok, mod = pcall(require, "lib.cross.plattform.is_wsl")
  if ok and type(mod) == "function" then
    local ok2, ans = pcall(mod)
    if ok2 and type(ans) == "boolean" then
      _is_wsl = ans
      return _is_wsl
    end
  end

  -- Fallback: kernel release check
  local uv = vim.uv or vim.loop
  local uname = uv.os_uname().release:lower()
  _is_wsl = vim.fn.has("wsl") == 1 or uname:find("microsoft", 1, true) ~= nil

  return _is_wsl
end

---Check if running on macOS
---@return boolean
function M.is_macos()
  return vim.fn.has("mac") == 1
end

---Check if running on Unix (Linux/macOS)
---@return boolean
function M.is_unix()
  return vim.fn.has("unix") == 1
end

---Check if executable exists in PATH
---@param name string
---@return boolean
function M.has_executable(name)
  return vim.fn.executable(name) == 1
end

---Get safe CWD (never nil)
---@return string
function M.get_cwd()
  local uv = vim.uv or vim.loop
  return uv.cwd() or vim.fn.getcwd()
end

return M
