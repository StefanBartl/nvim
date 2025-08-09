---@module 'system.env'

local M = {}

-- Detect WSL reliably
---@return boolean
local function detect_wsl()
  -- uname.release contains "Microsoft" on WSL
  local ok, u = pcall(vim.loop.os_uname)
  if ok and type(u) == "table" then
    local rel = tostring(u.release or "")
    if rel:match("Microsoft") or rel:match("WSL") then
      return true
    end
  end
  -- Fallback: /proc/version hint
  local f = io.open("/proc/version", "r")
  if f then
    local s = f:read("*l") or ""
    f:close()
    if s:match("microsoft") then return true end
  end
  return false
end

---@return SystemEnv
local function compute_env()
  local is_win = (vim.fn.has("win32") == 1) or (vim.fn.has("win64") == 1)
  local is_mac = vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
  local is_wsl = not is_win and detect_wsl()
  local is_linux = not is_win and not is_mac
  local is_pwsh = vim.fn.executable("pwsh") == 1

  local home = vim.fn.expand("~")
  local pathsep = is_win and "\\" or "/"

  local repo_base
  if is_win then
    repo_base = "E:\\MyGithub"
  elseif is_wsl then
    repo_base = "/mnt/e/MyGithub"
  else
    repo_base = home .. "/MyGithub"
  end

  return {
    is_windows = is_win,
    is_wsl = is_wsl,
    is_linux = is_linux,
    is_macos = is_mac,
    is_pwsh = is_pwsh,
    repo_base = repo_base,
    pathsep = pathsep,
    home = home,
  }
end

-- compute once and cache
local ENV = compute_env()

---@return SystemEnv
function M.get()
  return ENV
end

-- Optional: mirror into vim.g for easy access without require()
vim.g.is_windows = ENV.is_windows
vim.g.is_wsl = ENV.is_wsl
vim.g.is_linux = ENV.is_linux
vim.g.is_macos = ENV.is_macos
vim.g.is_pwsh = ENV.is_pwsh
vim.g.repo_base = ENV.repo_base

return M
