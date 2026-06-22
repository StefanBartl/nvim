---@module 'wkdoptions.config.core.parser'
--- Pure functions for parsing configuration values.
--- All functions are memoized for performance.

local lazy = require("lib.lua.lazy")
local trim = lazy.require("lib.lua.strings.core").trim
local memo = lazy.require("lib.lua.memo")

local M = {}

--- Parse boolean-like strings with extensive support.
---@nodiscard
---@param s string
---@return boolean|nil
local function parse_bool(s)
  local lower = s:lower()

  -- True variants
  if lower == "true" or lower == "on" or lower == "yes" or lower == "1" then
    return true
  end

  -- False variants
  if lower == "false" or lower == "off" or lower == "no" or lower == "0" then
    return false
  end

  return nil
end

--- Parse number with validation.
---@nodiscard
---@param s string
---@return number|nil
local function parse_number(s)
  local num = tonumber(s)
  if num and num == num then -- NaN check
    return num
  end
  return nil
end

--- Remove surrounding quotes from string.
---@nodiscard
---@param s string
---@return string|nil
local function unquote(s)
  return s:match('^"(.*)"$') or s:match("^'(.*)'$")
end

--- Parse a string token to boolean/number/string.
--- Memoized for performance with frequently used values.
---@nodiscard
---@param s string|nil
---@return boolean|number|string
M.parse = memo.fn(function(s)
  if s == nil then
    return ""
  end

  local trimmed = trim(s)

  -- Try unquoting first
  local unq = unquote(trimmed)
  if unq then
    return unq
  end

  -- Try boolean
  local bool = parse_bool(trimmed)
  if bool ~= nil then
    return bool
  end

  -- Try number
  local num = parse_number(trimmed)
  if num then
    return num
  end

  -- Return as string
  return trimmed
end, { weak = "kv", size = 64 })

return M
