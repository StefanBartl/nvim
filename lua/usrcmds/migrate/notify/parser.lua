---@module 'usrcmds.migrate.notify.parser'
---@brief Simple regex-based detection (like working monofile)
---@description
--- Uses string patterns instead of treesitter for simplicity and reliability.
--- Matches complete vim.notify statements via balanced parentheses.

require("usrcmds.migrate.notify.@types")

local M = {}

local api = vim.api

---@type table<string, string>
local LEVEL_MAP = {
  TRACE = "trace",
  DEBUG = "debug",
  INFO  = "info",
  WARN  = "warn",
  ERROR = "error",
}

--------------------------------------------------------------------------------
-- Pattern matching helpers
--------------------------------------------------------------------------------

---Check if line contains vim.notify start
---@param line string
---@return boolean
local function is_notify_line(line)
  -- Match vim.notify( but NOT notify.level(
  return line:match("vim%.notify%s*%(") ~= nil
    and not line:match("notify%.[a-z]+%s*%(")
end

---Find closing parenthesis for multiline call
---@param lines string[]
---@param start_idx integer
---@return integer|nil end_idx
local function find_call_end(lines, start_idx)
  local paren_count = 0
  local start_line = lines[start_idx]

  -- Count parentheses in first line
  for char in start_line:gmatch(".") do
    if char == "(" then
      paren_count = paren_count + 1
    elseif char == ")" then
      paren_count = paren_count - 1
      if paren_count == 0 then
        return start_idx  -- Single line
      end
    end
  end

  -- Search following lines
  for i = start_idx + 1, #lines do
    local line = lines[i]
    for char in line:gmatch(".") do
      if char == "(" then
        paren_count = paren_count + 1
      elseif char == ")" then
        paren_count = paren_count - 1
        if paren_count == 0 then
          return i
        end
      end
    end
  end

  return nil
end

--------------------------------------------------------------------------------
-- Single line migration
--------------------------------------------------------------------------------

---Migrate single line vim.notify
---@param line string
---@return string|nil migrated, string|nil level
local function migrate_single_line(line)
  -- Pattern: vim.notify( content , vim.log.levels.LEVEL )
  -- Use greedy match to get everything up to the last vim.log.levels
  local indent, content, level, rest = line:match(
    "^(%s*)vim%.notify%s*%((.-),%s*vim%.log%.levels%.(%u+)%s*%)(.*)$"
  )

  if not content or not level or not LEVEL_MAP[level] then
    return nil, nil
  end

  -- Clean content (trim whitespace)
  content = content:match("^%s*(.-)%s*$")

  -- Build replacement
  local method = LEVEL_MAP[level]
  local migrated = string.format('%snotify.%s(%s)%s', indent, method, content, rest)

  return migrated, level
end

--------------------------------------------------------------------------------
-- Multiline migration
--------------------------------------------------------------------------------

---Migrate multiline vim.notify
---@param lines string[]
---@return string|nil migrated, string|nil level
local function migrate_multiline(lines)
  -- Combine lines
  local combined = table.concat(lines, "\n")

  -- Extract indent from first line
  local indent = lines[1]:match("^(%s*)") or ""

  -- Normalize whitespace for pattern matching (but keep structure)
  -- Replace all whitespace sequences (including newlines) with single space
  local normalized = combined:gsub("%s+", " "):gsub("^%s+", "")

  -- Pattern: vim.notify( content , vim.log.levels.LEVEL )
  -- Match and capture everything, then verify it ends with )
  local prefix, content, level, suffix = normalized:match(
    "^(vim%.notify%s*%()(.-),%s*(vim%.log%.levels%.%u+)%s*(%)).*$"
  )

  if not content or not level then
    return nil, nil
  end

  -- Extract just the level name
  local level_name = level:match("vim%.log%.levels%.(%u+)")
  if not level_name or not LEVEL_MAP[level_name] then
    return nil, nil
  end

  -- Clean content (trim)
  content = content:match("^%s*(.-)%s*$")

  -- Build replacement (single line with original indent)
  local method = LEVEL_MAP[level_name]
  local migrated = string.format('%snotify.%s(%s)', indent, method, content)

  return migrated, level_name
end

--------------------------------------------------------------------------------
-- Scanner
--------------------------------------------------------------------------------

---Scan buffer and return all matches
---@param bufnr integer
---@return MigrateNotify.Match[]
function M.scan_buffer(bufnr)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  if vim.bo[bufnr].filetype ~= "lua" then
    return {}
  end

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local matches = {}
  local i = 1

  while i <= #lines do
    local line = lines[i]

    if is_notify_line(line) then
      local end_idx = find_call_end(lines, i)

      if end_idx then
        if end_idx == i then
          -- Single line
          local migrated, level = migrate_single_line(line)
          if migrated then
            table.insert(matches, {
              line = i,
              end_line = i,
              original = line,
              replacement = migrated,
              log_level = level,
            })
          end
        else
          -- Multiline
          local call_lines = {}
          for j = i, end_idx do
            table.insert(call_lines, lines[j])
          end

          local migrated, level = migrate_multiline(call_lines)
          if migrated then
            table.insert(matches, {
              line = i,
              end_line = end_idx,
              original = table.concat(call_lines, "\n"),
              replacement = migrated,
              log_level = level,
            })
          end

          i = end_idx  -- Skip processed lines
        end
      end
    end

    i = i + 1
  end

  return matches
end

return M
