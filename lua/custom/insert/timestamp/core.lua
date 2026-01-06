---@module 'custom.insert.timestamp.core'
---@brief Core implementation for timestamp insertion
---@description
--- Provides functions to insert timestamps and dates in various formats.

local M = {}

local api = vim.api

---@alias Custom.Insert.Timestamp.Format
---| "iso"       -- 2025-01-07T14:30:45Z
---| "iso-date"  -- 2025-01-07
---| "iso-time"  -- 14:30:45
---| "unix"      -- 1704636645
---| "human"     -- January 07, 2025
---| "short"     -- 2025-01-07 14:30
---| "log"       -- [2025-01-07 14:30:45]
---| "filename"  -- 20250107_143045

---@class Custom.Insert.Timestamp.Options
---@field format Custom.Insert.Timestamp.Format
---@field utc boolean Use UTC instead of local time

---Insert text at cursor
---@param text string
local function insert_at_cursor(text)
  local win = api.nvim_get_current_win()
  local cursor = api.nvim_win_get_cursor(win)
  local row, col = cursor[1], cursor[2]

  local line = api.nvim_get_current_line()
  if col > #line then
    col = #line
  end

  local new_line = line:sub(1, col) .. text .. line:sub(col + 1)
  api.nvim_set_current_line(new_line)
  api.nvim_win_set_cursor(win, { row, col + #text })
end

---Format timestamp according to specification
---@param timestamp number Unix timestamp
---@param format Custom.Insert.Timestamp.Format
---@param utc boolean
---@return string formatted
local function format_timestamp(timestamp, format, utc)
  local date_fn = utc and os.date or function(fmt, time)
    return os.date(fmt, time)
  end

  if format == "iso" then
    local suffix = utc and "Z" or ""
    return tostring(date_fn("%Y-%m-%dT%H:%M:%S", timestamp) .. suffix)
  elseif format == "iso-date" then
    return tostring(date_fn("%Y-%m-%d", timestamp))
  elseif format == "iso-time" then
    return tostring(date_fn("%H:%M:%S", timestamp))
  elseif format == "unix" then
    return tostring(timestamp)
  elseif format == "human" then
    return tostring(date_fn("%B %d, %Y", timestamp))
  elseif format == "short" then
    return tostring(date_fn("%Y-%m-%d %H:%M", timestamp))
  elseif format == "log" then
    return "[" .. tostring(date_fn("%Y-%m-%d %H:%M:%S", timestamp) .. "]")
  elseif format == "filename" then
    return tostring(date_fn("%Y%m%d_%H%M%S", timestamp))
  end

  return tostring(date_fn("%Y-%m-%d %H:%M:%S", timestamp))
end

---Insert timestamp at cursor
---@param opts Custom.Insert.Timestamp.Options
---@return boolean success
function M.insert_timestamp(opts)
  local timestamp = os.time()
  local formatted = format_timestamp(timestamp, opts.format, opts.utc)
  insert_at_cursor(formatted)
  return true
end

---Parse arguments into options
---@param args string[]
---@return Custom.Insert.Timestamp.Options
function M.parse_args(args)
  local opts = {
    format = "iso",
    utc = false,
  }

  for _, arg in ipairs(args) do
    if arg == "--utc" or arg == "-u" then
      opts.utc = true
    else
      -- Treat as format
      opts.format = arg
    end
  end

  return opts
end

return M
