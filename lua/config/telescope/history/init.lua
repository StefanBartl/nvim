---@module 'config.telescope.history'
---@brief Manages Telescope picker history with automatic backend selection.
---@description
--- Provides a unified interface for Telescope history management with automatic fallback:
--- 1. Prefers sqlite-based smart_history if available
--- 2. Falls back to file-based text history if sqlite is unavailable
--- 3. Provides consistent API regardless of backend
---
--- Backend selection happens automatically during setup based on:
--- - sqlite.lua loadability (hard check via pcall)
--- - telescope-smart-history.nvim availability
--- - File system permissions for fallback storage
---
--- All paths are created automatically if missing.

local M = {}

local levels = vim.log.levels

--- Internal state tracking the active backend
---@type HistoryState
local state = {
  backend = "none",
  path = nil,
  limit = 250,
}

--- Checks if sqlite.lua module is actually loadable (not just installed)
---@return boolean available True if sqlite module can be required
---@private
local function is_sqlite_available()
  local ok = pcall(require, "sqlite")
  return ok
end

--- Checks if telescope-smart-history extension can be loaded
---@return boolean available True if extension is loadable
---@private
local function is_smart_history_available()
  local ok = pcall(require, "telescope-smart-history")
  return ok
end

--- Ensures directory exists, creates it if missing
---@param dir_path string Absolute directory path
---@return boolean success True if directory exists or was created
---@private
local function ensure_directory(dir_path)
  if vim.fn.isdirectory(dir_path) == 0 then
    local ok = pcall(vim.fn.mkdir, dir_path, "p")
    if not ok then
      vim.notify(
        string.format("Failed to create directory: %s", dir_path),
        levels.WARN
      )
      return false
    end
  end
  return true
end

--- Initializes SQLite-based history backend
---@return table|nil config Configuration table for sqlite backend, nil on failure
---@private
local function setup_sqlite_backend()
  if not (is_sqlite_available() and is_smart_history_available()) then
    return nil
  end

  local dir = vim.fn.stdpath("state") .. "/telescope"
  if not ensure_directory(dir) then
    return nil
  end

  local db_path = dir .. "/history.sqlite3"
  state.backend = "sqlite"
  state.path = db_path

  return {
    path = db_path,
    limit = state.limit,
  }
end

--- Initializes file-based fallback history backend
---@return table|nil config Configuration table for file backend, nil on failure
---@private
local function setup_file_backend()
  local dir = vim.fn.stdpath("data") .. "/picker-history"
  if not ensure_directory(dir) then
    return nil
  end

  local file_path = dir .. "/_global.txt"
  state.backend = "file"
  state.path = file_path

  return {
    path = file_path,
    limit = state.limit,
  }
end

--- Determines and configures the best available history backend
---@return table config History configuration for telescope defaults
function M.setup()
  -- Try SQLite first
  local config = setup_sqlite_backend()

  -- Fallback to file-based history
  if not config then
    config = setup_file_backend()
  end

  -- No backend available
  if not config then
    state.backend = "none"
    vim.notify(
      "Telescope history: No backend available. History disabled.",
      levels.WARN
    )
    return {}
  end

  vim.notify(
    string.format(
      "Telescope history: Using %s backend at %s",
      state.backend,
      state.path
    ),
    levels.INFO
  )

  return config
end

--- Returns list of extension names to load based on available backend
---@return string[] extensions List of extension names (e.g., {"smart_history"})
function M.get_extensions()
  if state.backend == "sqlite" then
    return { "smart_history" }
  end
  return {}
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

--- Returns the currently active backend type
---@return "sqlite"|"file"|"none" backend
function M.get_backend()
  return state.backend
end

--- Returns the storage path for the active backend
---@return string|nil path Absolute path to history storage, nil if no backend
function M.get_path()
  return state.path
end

--- Returns whether history functionality is available
---@return boolean available True if any backend is active
function M.is_available()
  return state.backend ~= "none"
end

return M
