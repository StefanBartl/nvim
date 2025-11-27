---@module 'custom.pathfinder.extractor.find'
-- 'find'-algorithms for the pathfinder extractor module

local M = {}

local helpers = require("custom.pathfinder.extractor.helpers")

-- List of file extensions to prioritize when expanding from an extension
---@type string[]
local COMMON_EXTS = require("custom.pathfinder.extractor.common_extensions")

-- sanitize: strip surrounding quotes or parentheses from a candidate raw string
---@param raw string
---@return string
local function strip_wrappers(raw)
  if not raw or raw == "" then
    return raw
  end
  local first = raw:sub(1, 1)
  local last = raw:sub(-1, -1)
  if (first == '"' and last == '"') or (first == "'" and last == "'") then
    return raw:sub(2, -2)
  end
  if (first == "(" and last == ")") or (first == "<" and last == ">") then
    return raw:sub(2, -2)
  end
  return raw
end

-- try stacktrace-style matches first (path:line:col or path:line)
---@param line string
---@return candidates
function M.stack_patterns(line)
  local out = {}
  if not line or line == "" then
    return out
  end

  -- pattern for path:line:col
  for raw, ln, col in line:gmatch("([%w%p]+[%/\\][%w%p%%+~@:_%-%.,]+):(%d+):(%d+)") do
    raw = strip_wrappers(raw)
    table.insert(out, { raw = raw .. ":" .. ln .. ":" .. col, path = raw, lineno = tonumber(ln), col = tonumber(col) })
  end

  -- pattern for path:line (avoid capturing things captured above)
  for raw, ln in line:gmatch("([%w%p]+[%/\\][%w%p%%+~@:_%-%.,]+):(%d+)") do
    raw = strip_wrappers(raw)
    -- ensure this isn't already inserted (simple check)
    local already = false
    for _, v in ipairs(out) do
      if v.path == raw and v.lineno == tonumber(ln) then
        already = true
        break
      end
    end
    if not already then
      table.insert(out, { raw = raw .. ":" .. ln, path = raw, lineno = tonumber(ln), col = nil })
    end
  end

  return out
end

-- extension-driven extraction: find an occurrence of a known extension and expand around it
---@param line string
---@return candidates
function M.by_extension(line)
  local out = {}
  if not line or line == "" then
    return out
  end

  for _, ext in ipairs(COMMON_EXTS) do
    local start_pos = 1
    while true do
      local found_at = line:find(ext, start_pos, true)
      if not found_at then
        break
      end
      local ext_end = found_at + #ext - 1
      local left = helpers.expand_left(line, found_at)
      local right = helpers.expand_right(line, ext_end + 1)
      local raw = line:sub(left, right)
      raw = strip_wrappers(raw)
      if raw:match("[/\\]") or raw:match("^~") or raw:match("^[A-Za-z]:\\") or raw:match("^%.%.") then
        table.insert(out, { raw = raw, path = raw, lineno = nil, col = nil })
      end
      start_pos = ext_end + 1
    end
  end

  return out
end

-- absolute path patterns (simple)
---@param line string
---@return candidates
function M.absolute_paths(line)
  local out = {}
  if not line or line == "" then
    return out
  end

  -- unix absolute
  for raw in line:gmatch("(/[%w%p%%+~@:_%-%.,]+)") do
    raw = strip_wrappers(raw)
    table.insert(out, { raw = raw, path = raw, lineno = nil, col = nil })
  end

  -- windows drive letter
  for raw in line:gmatch("([A-Za-z]:\\[%w%p%%+~@:_%-%.,\\]+)") do
    raw = strip_wrappers(raw)
    table.insert(out, { raw = raw, path = raw, lineno = nil, col = nil })
  end

  -- UNC paths
  for raw in line:gmatch("(\\\\[%w%p%%+~@:_%-%.,\\]+)") do
    raw = strip_wrappers(raw)
    table.insert(out, { raw = raw, path = raw, lineno = nil, col = nil })
  end

  return out
end

return M
