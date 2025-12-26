---@module 'custom.function_index.core.cache'
---@brief Persistent cache management for function index
---@description
--- This module handles serialization, deserialization, and validation
--- of the function index cache. Uses JSON format for portability and
--- includes file modification time tracking for incremental updates.

local M = {}

local uv = vim.loop


--- Cache format version (bump on breaking changes)
local CACHE_VERSION = "1.0.0"

--- Ensure cache directory exists
---@param cache_dir string
---@return boolean # Success
---@return string|nil # Error message
local function ensure_cache_dir(cache_dir)
  local stat = uv.fs_stat(cache_dir)

  if stat then
    if stat.type ~= "directory" then
      return false, cache_dir .. " exists but is not a directory"
    end
    return true, nil
  end

  -- Create directory with parents
  local ok, err = pcall(vim.fn.mkdir, cache_dir, "p")
  if not ok then
    return false, "Failed to create cache directory: " .. tostring(err)
  end

  return true, nil
end

--- Get cache file path for current working directory
---@param cache_dir string
---@return string # Absolute path to cache file
local function get_cache_file_path(cache_dir)
  local cwd = vim.fn.getcwd()
  -- Hash CWD to create unique filename
  local hash = vim.fn.sha256(cwd):sub(1, 16)
  return cache_dir .. "/index_" .. hash .. ".json"
end

--- Get file modification time
---@param filepath string
---@return number|nil # Modification time or nil if file doesn't exist
local function get_file_mtime(filepath)
  local stat = uv.fs_stat(filepath)
  if stat then
    return stat.mtime.sec
  end
  return nil
end

--- Serialize cached index to JSON file
---@param cache_path string
---@param entries IndexEntry[]
---@return boolean # Success
---@return string|nil # Error message
local function write_cache(cache_path, entries)
  local metadata = {
    version = CACHE_VERSION,
    indexed_at = os.time(),
    cwd = vim.fn.getcwd(),
    file_count = 0,
    entry_count = #entries,
  }

  -- Count unique files
  local files = {}
  for _, entry in ipairs(entries) do
    files[entry.entry.filename] = true
  end
  for _ in pairs(files) do
    metadata.file_count = metadata.file_count + 1
  end

  local cached_index = {
    metadata = metadata,
    entries = entries,
  }

  local ok, encoded = pcall(vim.fn.json_encode, cached_index)
  if not ok then
    return false, "Failed to encode cache: " .. tostring(encoded)
  end

  local fd = uv.fs_open(cache_path, "w", 420) -- 0644 permissions
  if not fd then
    return false, "Failed to open cache file for writing"
  end

  local write_ok = uv.fs_write(fd, encoded, 0)
  uv.fs_close(fd)

  if not write_ok then
    return false, "Failed to write cache file"
  end

  return true, nil
end

--- Deserialize cached index from JSON file
---@param cache_path string
---@return CachedIndex|nil # Cached index or nil on error
---@return string|nil # Error message
local function read_cache(cache_path)
  local fd = uv.fs_open(cache_path, "r", 438)
  if not fd then
    return nil, "Cache file not found"
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil, "Failed to stat cache file"
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not data then
    return nil, "Failed to read cache file"
  end

  local ok, decoded = pcall(vim.fn.json_decode, data)
  if not ok then
    return nil, "Failed to decode cache: " .. tostring(decoded)
  end

  return decoded, nil
end

--- Validate cache metadata
---@param metadata CacheMetadata
---@param config table
---@return boolean # true if cache is valid
---@return string|nil # Reason if invalid
local function validate_cache_metadata(metadata, config)
  -- Check version
  if metadata.version ~= CACHE_VERSION then
    return false, "Cache version mismatch (expected " .. CACHE_VERSION .. ", got " .. metadata.version .. ")"
  end

  -- Check CWD
  local current_cwd = vim.fn.getcwd()
  if metadata.cwd ~= current_cwd then
    return false, "Cache was created for different working directory"
  end

  -- Check TTL
  if config.cache.ttl_seconds > 0 then
    local age = os.time() - metadata.indexed_at
    if age > config.cache.ttl_seconds then
      return false, "Cache expired (age: " .. age .. "s, TTL: " .. config.cache.ttl_seconds .. "s)"
    end
  end

  return true, nil
end

--- Check if any indexed files have been modified
---@param entries IndexEntry[]
---@return boolean # true if any file changed
---@return string[] # List of changed files
local function check_file_modifications(entries)
  local changed_files = {}

  for _, index_entry in ipairs(entries) do
    local current_mtime = get_file_mtime(index_entry.entry.filename)

    if not current_mtime then
      -- File was deleted
      changed_files[#changed_files + 1] = index_entry.entry.filename .. " (deleted)"
    elseif current_mtime > index_entry.file_mtime then
      -- File was modified
      changed_files[#changed_files + 1] = index_entry.entry.filename .. " (modified)"
    end
  end

  return #changed_files > 0, changed_files
end

--- Load cached index if valid
---@param config table
---@return table[]|nil # Entries or nil if cache invalid
---@return string|nil # Error/invalidation reason
function M.load(config)
  if not config.cache.enabled then
    return nil, "Cache disabled"
  end

  local cache_path = get_cache_file_path(config.cache.dir)
  local cached, err = read_cache(cache_path)

  if not cached then
    return nil, err
  end

  -- Validate metadata
  local valid, reason = validate_cache_metadata(cached.metadata, config)
  if not valid then
    return nil, reason
  end

  -- Check file modifications
  local files_changed, changed_list = check_file_modifications(cached.entries)
  if files_changed then
    return nil, "Files changed: " .. table.concat(changed_list, ", ")
  end

  -- Extract FunctionEntry objects
  local entries = {}
  for _, index_entry in ipairs(cached.entries) do
    entries[#entries + 1] = index_entry.entry
  end

  return entries, nil
end

--- Save entries to cache
---@param config table
---@param entries table[]
---@return boolean # Success
---@return string|nil # Error message
function M.save(config, entries)
  if not config.cache.enabled then
    return false, "Cache disabled"
  end

  -- Ensure cache directory exists
  local ok, err = ensure_cache_dir(config.cache.dir)
  if not ok then
    return false, err
  end

  -- Build IndexEntry objects with file mtimes
  local index_entries = {}
  for _, entry in ipairs(entries) do
    local mtime = get_file_mtime(entry.filename) or os.time()
    index_entries[#index_entries + 1] = {
      entry = entry,
      file_mtime = mtime,
      indexed_at = os.time(),
    }
  end

  local cache_path = get_cache_file_path(config.cache.dir)
  return write_cache(cache_path, index_entries)
end

--- Clear cache for current working directory
---@param config table
---@return boolean # Success
---@return string|nil # Error message
function M.clear(config)
  local cache_path = get_cache_file_path(config.cache.dir)

  local ok, err = pcall(uv.fs_unlink, cache_path)
  if not ok then
    return false, "Failed to delete cache: " .. tostring(err)
  end

  return true, nil
end

--- Get cache statistics
---@param config table
---@return table|nil # Stats or nil if no cache
function M.get_stats(config)
  local cache_path = get_cache_file_path(config.cache.dir)
  local cached, _ = read_cache(cache_path)

  if not cached then
    return nil
  end

  local stat = uv.fs_stat(cache_path)

  return {
    version = cached.metadata.version,
    indexed_at = cached.metadata.indexed_at,
    cwd = cached.metadata.cwd,
    file_count = cached.metadata.file_count,
    entry_count = cached.metadata.entry_count,
    cache_size_bytes = stat and stat.size or 0,
    cache_path = cache_path,
  }
end

return M
