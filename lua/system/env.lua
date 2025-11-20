---@module 'system.env'

--ADD: SytemEnv type
-- Compute_env return type = -@return SystemEnv

local M = {}

local ENV
local fn, g = vim.fn, vim.g
local lib = require("lib")

local function Compute_env()
  local is_win = (fn.has("win32") == 1) or (fn.has("win64") == 1)
  local is_mac = fn.has("mac") == 1 or fn.has("macunix") == 1
  local is_wsl = not is_win and lib.is_wsl()
  local is_linux = not is_win and not is_mac
  local is_pwsh = fn.executable("pwsh") == 1

  local home = vim.fn.expand("~")
  local pathsep = is_win and "\\" or "/"
  local repo_base = vim.env.REPOS_DIR

  g.is_windows = is_win
  g.is_wsl = is_wsl
  g.is_linux = is_linux
  g.is_macos = is_mac
  g.is_pwsh = is_pwsh
  g.repo_base = repo_base

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

-- Compute once and cache -> This function has sideffect: 'ENV' will be computed!
---@return nil
function M.compute_env()
  ENV = Compute_env()
end

---@return SystemEnv
function M.get()
  return ENV
end

return M
