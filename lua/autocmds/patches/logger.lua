---@module 'autocmds.patches.logger'
---@brief Structured logging system for patch operations.
---@description
--- Provides thread-safe, rotating log file with JSON-structured entries.
--- Supports multiple log levels and automatic log rotation.

local M = {}

-- Cache vim.loop for performance
local uv = vim.loop

-- Log file configuration
local LOG_DIR = vim.fn.stdpath("cache") .. "/patches"
local LOG_FILE = LOG_DIR .. "/patches.log"
local MAX_LOG_SIZE = 100 * 1024 -- 100 KB

-- Current configuration
local config = {
  verbose = false,
  enable_file_logging = true,
}

---@type LogLevel
local MIN_LEVEL = "INFO"

local LEVEL_PRIORITY = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

-- Ensure log directory exists
---@return boolean success
---@return string|nil error
local function ensure_log_dir()
  local stat = uv.fs_stat(LOG_DIR)
  if stat then
    return true
  end

  local ok, err = uv.fs_mkdir(LOG_DIR, 493) -- 0755
  if not ok then
    return false, err
  end
  return true
end

--- Get current timestamp in ISO 8601 format
---@return string|osdate
local function get_timestamp()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

--- Check if log rotation is needed
---@return boolean
local function needs_rotation()
  if not config.enable_file_logging then
    return false
  end

  local stat = uv.fs_stat(LOG_FILE)
  if not stat then
    return false
  end

  return stat.size > MAX_LOG_SIZE
end

--- Rotate log file (rename to .old)
---@return boolean success
local function rotate_log()
  local old_file = LOG_FILE .. ".old"

  -- Remove existing .old file
  pcall(uv.fs_unlink, old_file)

  -- Rename current log to .old
  local ok = pcall(uv.fs_rename, LOG_FILE, old_file)
  return ok == true
end

--- Write log entry to file
---@param entry LogEntry
---@return boolean success
local function write_to_file(entry)
  if not config.enable_file_logging then
    return true
  end

  local ok, _ = ensure_log_dir()
  if not ok then
    return false
  end

  -- Check rotation
  if needs_rotation() then
    rotate_log()
  end

  -- Serialize entry to JSON
  local json_ok, json_str = pcall(vim.json.encode, entry)
  if not json_ok then
    return false
  end

  -- Append to log file
  local fd = uv.fs_open(LOG_FILE, "a", 420) -- 0644
  if not fd then
    return false
  end

  uv.fs_write(fd, json_str .. "\n", -1)
  uv.fs_close(fd)

  return true
end

--- Log a message at the specified level
---@param level LogLevel
---@param message string
---@param context? table
---@return nil
local function log(level, message, context)
  -- Check if level is enabled
  if LEVEL_PRIORITY[level] < LEVEL_PRIORITY[MIN_LEVEL] then
    return
  end

  ---@type LogEntry
  local entry = {
    level = level,
    message = message,
    timestamp = tostring(get_timestamp()),
    context = context,
  }

  -- Write to file
  write_to_file(entry)

  -- Console output for WARN/ERROR
  if level == "WARN" or level == "ERROR" then
    local log_level = level == "WARN" and vim.log.levels.WARN or vim.log.levels.ERROR
    local ctx_str = context and vim.inspect(context) or ""
    vim.schedule(function()
      vim.notify(
        string.format("[patches] %s: %s%s", level, message, ctx_str),
        log_level
      )
    end)
  elseif config.verbose and level == "DEBUG" then
    vim.schedule(function()
      print(string.format("[patches] %s: %s", level, message))
    end)
  end
end

--- Set configuration
---@param opts PatchConfig
---@return nil
function M.setup(opts)
  config.verbose = opts.verbose or false
  config.enable_file_logging = true -- Always enable file logging
  MIN_LEVEL = config.verbose and "DEBUG" or "INFO"
end

--- Log a DEBUG message
---@param message string
---@param context? table
---@return nil
function M.debug(message, context)
  log("DEBUG", message, context)
end

--- Log an INFO message
---@param message string
---@param context? table
---@return nil
function M.info(message, context)
  log("INFO", message, context)
end

--- Log a WARN message
---@param message string
---@param context? table
---@return nil
function M.warn(message, context)
  log("WARN", message, context)
end

--- Log an ERROR message
---@param message string
---@param context? table
---@return nil
function M.error(message, context)
  log("ERROR", message, context)
end

--- Read recent log entries
---@param opts? { level?: LogLevel, limit?: integer }
---@return LogEntry[]
function M.get_recent(opts)
  opts = opts or {}
  local limit = opts.limit or 50
  local level_filter = opts.level

  local fd = uv.fs_open(LOG_FILE, "r", 420)
  if not fd then
    return {}
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return {}
  end

  local content = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not content then
    return {}
  end

  local entries = {}
  for line in content:gmatch("[^\n]+") do
    local ok, entry = pcall(vim.json.decode, line)
    if ok and type(entry) == "table" then
      if not level_filter or entry.level == level_filter then
        table.insert(entries, entry)
      end
    end
  end

  -- Return last N entries
  local start = math.max(1, #entries - limit + 1)
  local result = {}
  for i = start, #entries do
    table.insert(result, entries[i])
  end

  return result
end

--- Clear log file
---@return boolean success
function M.clear()
  local ok = pcall(uv.fs_unlink, LOG_FILE)
  return ok == true
end

--- Get log file path
---@return string
function M.get_log_path()
  return LOG_FILE
end

return M
