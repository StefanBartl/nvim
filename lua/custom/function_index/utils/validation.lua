---@module 'custom.function_index.utils.validation'
---@brief Input validation and sanitization utilities
---@description
--- This module provides safe validation functions for user inputs,
--- configuration values, and API parameters. All functions return
--- success/failure status with detailed error messages.
require("@types.safe")

local M = {}

--- Validate a string parameter
---@param value any # Value to validate
---@param param_name string # Parameter name (for error messages)
---@param allow_empty boolean|nil # Whether empty strings are allowed
---@return boolean # true if valid
---@return string|nil # Error message if invalid
function M.validate_string(value, param_name, allow_empty)
  if type(value) ~= "string" then
    return false, param_name .. " must be a string, got " .. type(value)
  end

  if not allow_empty and value == "" then
    return false, param_name .. " cannot be empty"
  end

  return true, nil
end

--- Validate an integer parameter
---@param value any # Value to validate
---@param param_name string # Parameter name
---@param min integer|nil # Minimum value (inclusive)
---@param max integer|nil # Maximum value (inclusive)
---@return boolean # true if valid
---@return string|nil # Error message if invalid
function M.validate_integer(value, param_name, min, max)
  if type(value) ~= "number" then
    return false, param_name .. " must be a number, got " .. type(value)
  end

  if value ~= math.floor(value) then
    return false, param_name .. " must be an integer, got " .. tostring(value)
  end

  if min and value < min then
    return false, param_name .. " must be >= " .. min .. ", got " .. tostring(value)
  end

  if max and value > max then
    return false, param_name .. " must be <= " .. max .. ", got " .. tostring(value)
  end

  return true, nil
end

--- Validate a boolean parameter
---@param value any # Value to validate
---@param param_name string # Parameter name
---@return boolean # true if valid
---@return string|nil # Error message if invalid
function M.validate_boolean(value, param_name)
  if type(value) ~= "boolean" then
    return false, param_name .. " must be a boolean, got " .. type(value)
  end

  return true, nil
end

--- Validate a table parameter
---@param value any # Value to validate
---@param param_name string # Parameter name
---@param allow_empty boolean|nil # Whether empty tables are allowed
---@return boolean # true if valid
---@return string|nil # Error message if invalid
function M.validate_table(value, param_name, allow_empty)
  if type(value) ~= "table" then
    return false, param_name .. " must be a table, got " .. type(value)
  end

  if not allow_empty then
    local is_empty = true
    for _ in pairs(value) do
      is_empty = false
      break
    end

    if is_empty then
      return false, param_name .. " cannot be empty"
    end
  end

  return true, nil
end

--- Validate a file path exists
---@param path string # File path to validate
---@param param_name string # Parameter name
---@return boolean # true if file exists
---@return string|nil # Error message if invalid
function M.validate_file_exists(path, param_name)
  local ok, err = M.validate_string(path, param_name, false)
  if not ok then
    return false, err
  end

  local stat = vim.loop.fs_stat(path)
  if not stat then
    return false, param_name .. " does not exist: " .. path
  end

  if stat.type ~= "file" then
    return false, param_name .. " is not a file: " .. path
  end

  return true, nil
end

--- Validate a directory path exists
---@param path string # Directory path to validate
---@param param_name string # Parameter name
---@return boolean # true if directory exists
---@return string|nil # Error message if invalid
function M.validate_directory_exists(path, param_name)
  local ok, err = M.validate_string(path, param_name, false)
  if not ok then
    return false, err
  end

  local stat = vim.loop.fs_stat(path)
  if not stat then
    return false, param_name .. " does not exist: " .. path
  end

  if stat.type ~= "directory" then
    return false, param_name .. " is not a directory: " .. path
  end

  return true, nil
end

--- Validate enum value (one of allowed values)
---@param value any # Value to validate
---@param param_name string # Parameter name
---@param allowed_values any[] # List of allowed values
---@return boolean # true if valid
---@return string|nil # Error message if invalid
function M.validate_enum(value, param_name, allowed_values)
  for _, allowed in ipairs(allowed_values) do
    if value == allowed then
      return true, nil
    end
  end

  local allowed_str = table.concat(
    vim.tbl_map(function(v)
      return '"' .. tostring(v) .. '"'
    end, allowed_values),
    ", "
  )

  return false, param_name .. " must be one of: " .. allowed_str .. ", got " .. tostring(value)
end

--- Safe call wrapper with structured error handling
---@param fn function # Function to call
---@param ... any # Arguments
---@return SafeCallResult # Result with ok, result, err fields
function M.safe_call(fn, ...)
  local ok, result = pcall(fn, ...)

  if ok then
    return {
      ok = true,
      result = result,
      err = nil,
    }
  else
    return {
      ok = false,
      result = nil,
      err = tostring(result),
    }
  end
end

--- Validate FunctionEntry structure
---@param entry any # Entry to validate
---@return boolean # true if valid
---@return string|nil # Error message if invalid
function M.validate_function_entry(entry)
  local ok, err = M.validate_table(entry, "entry", false)
  if not ok then
    return false, err
  end

  ok, err = M.validate_string(entry.filename, "entry.filename", false)
  if not ok then
    return false, err
  end

  ok, err = M.validate_integer(entry.lnum, "entry.lnum", 1, nil)
  if not ok then
    return false, err
  end

  ok, err = M.validate_integer(entry.col, "entry.col", 1, nil)
  if not ok then
    return false, err
  end

  ok, err = M.validate_string(entry.func_name, "entry.func_name", false)
  if not ok then
    return false, err
  end

  ok, err = M.validate_string(entry.language, "entry.language", false)
  if not ok then
    return false, err
  end

  return true, nil
end

return M
