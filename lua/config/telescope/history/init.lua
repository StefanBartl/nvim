---@module 'config.telescope.history'
--- Manages Telescope picker history with automatic backend selection.
--- Prefers SQLite-backed history (smart_history) if available,
--- otherwise falls back to a file-based history.

local M = {}

local levels = vim.log.levels
local notify = vim.notify

---@type HistoryState
local state = {
  backend = "none",
  path = "",
  limit = 3000,
  extensions = {},
}

---Ensure a directory exists
---@param dir_path string
---@return boolean
local function ensure_dir(dir_path)
  if vim.fn.isdirectory(dir_path) == 0 then
    local ok, err = pcall(vim.fn.mkdir, dir_path, "p")
    if not ok then
      notify(string.format("Failed to create directory: %s (%s)", dir_path, err), levels.WARN)
      return false
    end
  end
  return true
end

---Setup SQLite backend if possible
---@return boolean success
local function setup_sqlite()
  local ok_sqlite = pcall(require, "sqlite")
  local ok_smart = pcall(require, "telescope-smart-history")
  if not (ok_sqlite and ok_smart) then
    return false
  end

  local dir = vim.fn.stdpath("data") .. "/databases"
  if not ensure_dir(dir) then
    return false
  end

  state.backend = "sqlite"
  state.path = dir .. "/telescope_history.sqlite3"
  state.extensions = { "smart_history" }
  return true
end

---Setup file-based fallback backend
---@return boolean success
local function setup_file()
  local dir = vim.fn.stdpath("data") .. "/picker-history"
  if not ensure_dir(dir) then
    return false
  end

  state.backend = "file"
  state.path = dir .. "/_global.txt"
  state.extensions = {}
  return true
end

---Setup history backend (SQLite preferred)
function M.setup()
  if not setup_sqlite() then
    setup_file()
  end

  -- notify(
  --   string.format("Telescope history: Using %s backend at %s", state.backend, state.path),
  --   levels.INFO
  -- )

  return {
    path = state.path,
    limit = state.limit,
  }
end

--- Returns backend-specific extension configuration
---@return table config Extension-specific configuration
function M.get_extension_config()
  if state.backend == "sqlite" then
    return {
      smart_history = {
        limit = state.limit,
      },
    }
  end
  return {}
end

---Get backend-specific extensions to load
---@return string[]
function M.get_extensions()
  return state.extensions
end

--- Returns whether history functionality is available
---@return boolean available
function M.is_available()
  return state.backend ~= "none"
end

return M
