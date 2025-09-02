---@module 'system.env'

local M = {}

local lib = require("lib")

---@return SystemEnv
local function compute_env()
	local is_win = (vim.fn.has("win32") == 1) or (vim.fn.has("win64") == 1)
	local is_mac = vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1
	local is_wsl = not is_win and lib.is_wsl()
	local is_linux = not is_win and not is_mac
	local is_pwsh = vim.fn.executable("pwsh") == 1

	local home = vim.fn.expand("~")
	local pathsep = is_win and "\\" or "/"
	local repo_base = vim.env.REPOS_DIR

	vim.g.is_windows = is_win
	vim.g.is_wsl = is_wsl
	vim.g.is_linux = is_linux
	vim.g.is_macos = is_mac
	vim.g.is_pwsh = is_pwsh
	vim.g.repo_base = repo_base

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


return M
