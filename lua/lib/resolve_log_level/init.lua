---@module 'lib.resolve_log_level'

---@alias LogLevelString
---| "TRACE" # Trace level (0)
---| "DEBUG" # Debug level (1)
---| "INFO" # Info level (2)
---| "WARN" # Warning level (3)
---| "ERROR" # Error level (4)
---| "OFF" # Off level (5)

---@alias LogLevelNumber
---| 0 # TRACE
---| 1 # DEBUG
---| 2 # INFO
---| 3 # WARN
---| 4 # ERROR
---| 5 # OFF

---@alias LogLevel LogLevelNumber|LogLevelString

--- Resolves a log level parameter to a valid vim.log.levels integer value.
--- Handles numeric levels (0-5), string level names, and vim.log.levels table values.
---@param level? LogLevel User-provided log level (number or string level name)
---@param default? LogLevelNumber Default level to use if resolution fails (defaults to vim.log.levels.WARN)
---@return integer resolved_level A valid vim.log.levels integer value
return function(level, default)
  local default_level = default or vim.log.levels.WARN

  -- Handle nil case
  if level == nil then
    return default_level
  end

  -- Handle numeric level (0-5)
  if type(level) == "number" then
    if level >= 0 and level <= 5 then
      return level
    else
      return default_level
    end
  end

  -- Handle string level names (case-insensitive)
  if type(level) == "string" then
    local level_upper = level:upper()
    local level_map = {
      TRACE = vim.log.levels.TRACE,
      DEBUG = vim.log.levels.DEBUG,
      INFO = vim.log.levels.INFO,
      WARN = vim.log.levels.WARN,
      ERROR = vim.log.levels.ERROR,
      OFF = vim.log.levels.OFF,
    }

    if level_map[level_upper] then
      return level_map[level_upper]
    else
      return default_level
    end
  end

  -- Fallback for any other type (including tables)
  return default_level
end
