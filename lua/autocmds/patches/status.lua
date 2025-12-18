---@module 'autocmds.patches.status'
---@brief Persistent status tracking for patches.
---@description
--- Manages patch application status in a JSON file.
--- Tracks: last status, timestamps, checksums, attempt counts.

local M = {}

local utils = require("autocmds.patches.utils")
local logger = require("autocmds.patches.logger")

local uv = vim.loop

-- Status file location
local STATUS_DIR = vim.fn.stdpath("cache") .. "/patches"
local STATUS_FILE = STATUS_DIR .. "/status.json"

-- In-memory cache
---@type table<string, StatusEntry>
local status_cache = {}

-- Dirty flag for batch writes
local cache_dirty = false

--- Ensure status directory exists
---@return boolean success
local function ensure_status_dir()
  return utils.ensure_dir(STATUS_DIR)
end

--- Load status from disk into cache
---@return boolean success
local function load_status()
  if not utils.file_exists(STATUS_FILE) then
    status_cache = {}
    return true
  end

  local content, err = utils.read_file(STATUS_FILE)
  if not content then
    logger.error("Failed to read status file", { error = err })
    return false
  end

  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    logger.error("Failed to parse status file", { error = data })
    status_cache = {}
    return false
  end

  status_cache = data
  cache_dirty = false
  return true
end

--- Save status from cache to disk
---@return boolean success
local function save_status()
  if not cache_dirty then
    return true
  end

  local ok, err = ensure_status_dir()
  if not ok then
    logger.error("Failed to create status directory", { error = err })
    return false
  end

  local json_ok, json_str = pcall(vim.json.encode, status_cache)
  if not json_ok then
    logger.error("Failed to serialize status", { error = json_str })
    return false
  end

  local write_ok, write_err = utils.write_file(STATUS_FILE, json_str)
  if not write_ok then
    logger.error("Failed to write status file", { error = write_err })
    return false
  end

  cache_dirty = false
  logger.debug("Status saved to disk")
  return true
end

--- Initialize status management
---@return nil
function M.init()
  load_status()

  -- Schedule periodic saves
  local timer = uv.new_timer()
  ---@cast timer uv.uv_timer_t
  if timer then
    timer:start(5000, 5000, function()
      if cache_dirty then
        vim.schedule(function()
          save_status()
        end)
      end
    end)
  end
end

--- Get status entry for a patch key
---@param key string
---@return StatusEntry|nil
function M.get(key)
  if type(key) ~= "string" or key == "" then
    return nil
  end
  return status_cache[key]
end

--- Update status entry for a patch
---@param result PatchResult
---@return nil
function M.update(result)
  if type(result) ~= "table" or not result.key then
    logger.warn("Invalid result passed to status.update")
    return
  end

  local existing = status_cache[result.key] or {
    key = result.key,
    repo = result.repo,
    attempt_count = 0,
  }

  ---@type StatusEntry
  local entry = {
    key = result.key,
    repo = result.repo,
    status = result.status,
    message = result.message,
    last_updated = result.timestamp,
    attempt_count = existing.attempt_count + 1,
    checksum = existing.checksum, -- Preserve checksum
  }

  status_cache[result.key] = entry
  cache_dirty = true

  logger.debug("Status updated", { key = result.key, status = result.status })
end

--- Update checksum for a patch
---@param key string
---@param checksum string
---@return nil
function M.update_checksum(key, checksum)
  if type(key) ~= "string" or type(checksum) ~= "string" then
    return
  end

  local entry = status_cache[key]
  if not entry then
    return
  end

  entry.checksum = checksum
  cache_dirty = true
end

--- Query status entries with filters
---@param query? StatusQuery
---@return StatusEntry[]
function M.query(query)
  query = query or {}

  local repo_set = utils.to_set(query.repos)
  local key_set = utils.to_set(query.keys)
  local status_set = utils.to_set(query.status_filter)

  local results = {}

  for _, entry in pairs(status_cache) do
    -- Apply filters
    if repo_set and not repo_set[entry.repo] then
      goto continue
    end

    if key_set and not key_set[entry.key] then
      goto continue
    end

    if status_set and not status_set[entry.status] then
      goto continue
    end

    table.insert(results, entry)

    ::continue::
  end

  -- Sort by last_updated descending
  table.sort(results, function(a, b)
    return (a.last_updated or "") > (b.last_updated or "")
  end)

  return results
end

--- Get all status entries
---@return StatusEntry[]
function M.get_all()
  local results = {}
  for _, entry in pairs(status_cache) do
    table.insert(results, entry)
  end
  return results
end

--- Clear all status entries
---@return boolean success
function M.clear()
  status_cache = {}
  cache_dirty = true
  return save_status()
end

--- Force save status to disk
---@return boolean success
function M.flush()
  return save_status()
end

return M
