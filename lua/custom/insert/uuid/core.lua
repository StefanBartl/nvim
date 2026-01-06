---@module 'custom.insert.uuid.core'
---@brief Core implementation for UUID generation and insertion
---@description
--- Provides functions to generate and insert UUIDs/GUIDs.

local M = {}

local api = vim.api

---@alias Custom.Insert.UUID.Format
---| "standard"  -- 550e8400-e29b-41d4-a716-446655440000
---| "compact"   -- 550e8400e29b41d4a716446655440000
---| "upper"     -- 550E8400-E29B-41D4-A716-446655440000
---| "braced"    -- {550e8400-e29b-41d4-a716-446655440000}

---@class Custom.Insert.UUID.Options
---@field format Custom.Insert.UUID.Format
---@field version integer UUID version (4 = random, 1 = time-based)

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

---Generate random hex string
---@param length integer
---@return string
---@diagnostic disable-next-line: unused-function, unused-local
local function random_hex(length)
  local chars = "0123456789abcdef"
  local result = {}

  -- Seed random generator
  math.randomseed(os.time() * os.clock())

  for _ = 1, length do
    local idx = math.random(1, #chars)
    table.insert(result, chars:sub(idx, idx))
  end

  return table.concat(result)
end

---Generate UUID v4 (random)
---@return string uuid
local function generate_uuid_v4()
  -- UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  -- y is one of [8, 9, a, b]

  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

  local uuid = template:gsub("[xy]", function(c)
    local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
    return string.format("%x", v)
  end)

  return uuid
end

---Format UUID according to specification
---@param uuid string Standard UUID string
---@param format Custom.Insert.UUID.Format
---@return string formatted
local function format_uuid(uuid, format)
  if format == "compact" then
    return (uuid:gsub("-", ""))
  elseif format == "upper" then
    return uuid:upper()
  elseif format == "braced" then
    return "{" .. uuid .. "}"
  end
  return uuid
end

---Insert UUID at cursor
---@param opts Custom.Insert.UUID.Options
---@return boolean success
function M.insert_uuid(opts)
  -- For now, only support v4 (random)
  local uuid = generate_uuid_v4()
  local formatted = format_uuid(uuid, opts.format)
  insert_at_cursor(formatted)
  return true
end

---Parse arguments into options
---@param args string[]
---@return Custom.Insert.UUID.Options
function M.parse_args(args)
  local opts = {
    format = "standard",
    version = 4,
  }

  for _, arg in ipairs(args) do
    if arg == "compact" or arg == "upper" or arg == "braced" then
      opts.format = arg
    elseif arg == "v1" then
      opts.version = 1
    elseif arg == "v4" then
      opts.version = 4
    end
  end

  return opts
end

return M
