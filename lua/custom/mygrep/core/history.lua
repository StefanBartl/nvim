---@module 'custom.mygrep.core.history'
---@class HistoryManager
---@brief Manages per-tool persistent history, favorites, and in-memory undo stack.
---@description
--- This module provides a structured way to load, store, and manage session-based
--- and persistent data for grep-like tools. Each tool has its own isolated set of
--- history entries, favorites, and undo actions. This design supports extendability
--- and modular behavior for tools like live_grep, multigrep, etc.
---
--- Files are stored under `stdpath("cache")/mygrep/<tool>_<type>.json`
--- History is stored persistently, undo stack is session-local only.
---@field load fun(tool: string): ToolState Loads state for a given tool (history, favorites, undo)
---@field save fun(tool: string, state: ToolState): boolean Persists history and favorites to disk

local M = {}


local uv = vim.uv or vim.loop
local fs = vim.fn
local json_encode = fs.json_encode
local json_decode = fs.json_decode
local cache_dir = fs.stdpath("cache") .. "/mygrep"

--- Returns the full path for a file storing given tool's data type.
---@param tool string
---@param kind '"history"'|'"favorites"'
---@return string
local function get_path(tool, kind)
  assert(type(tool) == "string" and tool ~= "", "tool must be non-empty string")
  assert(kind == "history" or kind == "favorites", "invalid kind")
  return ("%s/%s_%s.json"):format(cache_dir, tool, kind)
end

--- Reads a JSON file and decodes it to Lua table.
---@param path string
---@return table
local function read_json(path)
  local ok, data = pcall(fs.readfile, path)
  if not ok or not data or type(data) ~= "table" then
    return {}
  end

  local decoded = nil
  local success = pcall(function()
    decoded = json_decode(table.concat(data, "\n"))
  end)

  if not success or type(decoded) ~= "table" then
    return {}
  end

  return decoded
end

--- Writes a Lua table to a JSON file.
---@param path string
---@param tbl table
---@return boolean
local function write_json(path, tbl)
  local ok, encoded = pcall(json_encode, tbl)
  if not ok or type(encoded) ~= "string" then
    return false
  end

  local f_ok, err = pcall(fs.writefile, path, { encoded }, "w")
  return f_ok and true or false
end

--- Loads a tool's state (history, favorites, and undo stack)
---@param tool string
---@return ToolState
function M.load(tool)
  assert(type(tool) == "string" and tool ~= "", "tool must be non-empty string")

  -- ensure directory exists
  local ok = pcall(fs.mkdir, cache_dir, "p")
  if not ok then
    vim.notify("[mygrep] Could not create cache dir: " .. cache_dir, vim.log.levels.WARN)
  end

  return {
    history = read_json(get_path(tool, "history")),
    favorites = read_json(get_path(tool, "favorites")),
    undo = {},
  }
end

--- Saves history and favorites of a given tool to disk.
---@param tool string
---@param state ToolState
---@return boolean success
function M.save(tool, state)
  assert(type(tool) == "string" and tool ~= "", "tool must be non-empty string")
  assert(type(state) == "table", "state must be a table")
  assert(type(state.history) == "table", "state.history must be a table")
  assert(type(state.favorites) == "table", "state.favorites must be a table")

  local ok_hist = write_json(get_path(tool, "history"), state.history)
  local ok_favs = write_json(get_path(tool, "favorites"), state.favorites)

  return ok_hist and ok_favs
end

return M
