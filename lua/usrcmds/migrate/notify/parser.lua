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
-- Extract vim.notify call from line
--------------------------------------------------------------------------------

---Extract the complete vim.notify(...) call from a line
---@param line string
---@return string|nil call_text, integer|nil start_col, integer|nil end_col
local function extract_notify_call(line)
  -- Find start position
  local start_pos = line:find("vim%.notify%s*%(")
  if not start_pos then
    return nil, nil, nil
  end

  -- Count parentheses to find matching closing paren
  local paren_count = 0
  local in_call = false
  local end_pos = nil

  for i = start_pos, #line do
    local char = line:sub(i, i)

    if char == "(" then
      paren_count = paren_count + 1
      in_call = true
    elseif char == ")" then
      paren_count = paren_count - 1

      if in_call and paren_count == 0 then
        end_pos = i
        break
      end
    end
  end

  if not end_pos then
    return nil, nil, nil
  end

  -- Extract the call text
  local call_text = line:sub(start_pos, end_pos)
  return call_text, start_pos - 1, end_pos  -- Return 0-based start, 1-based end
end

--------------------------------------------------------------------------------
-- Single line migration
--------------------------------------------------------------------------------

---Migrate single line vim.notify
---@param line string
---@return string|nil migrated, string|nil level
local function migrate_single_line(line)
  -- Extract the vim.notify call
  local call_text, start_col, end_col = extract_notify_call(line)

  if not call_text then
    return nil, nil
  end

  -- Pattern to extract message and level from call
  -- Match: vim.notify( <message> , vim.log.levels.<LEVEL> [, <opts>] )
  local msg, level, opts = call_text:match(
    "vim%.notify%s*%(%s*(.-)%s*,%s*vim%.log%.levels%.(%u+)%s*(.*)%)"
  )

  if not msg or not level or not LEVEL_MAP[level] then
    return nil, nil
  end

  -- Check if there are optional opts (starts with comma)
  local has_opts = opts and opts:match("^%s*,%s*(.+)")
  local opts_arg = has_opts or nil

  -- Build replacement call
  local method = LEVEL_MAP[level]
  local replacement_call

  if opts_arg then
    replacement_call = string.format("notify.%s(%s, %s)", method, msg, opts_arg)
  else
    replacement_call = string.format("notify.%s(%s)", method, msg)
  end

  -- Get parts before and after the call
  local before = line:sub(1, start_col)
  local after = line:sub(end_col + 1)

  -- Build complete migrated line
  local migrated = before .. replacement_call .. after

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
  local combined = table.concat(lines, " ")

  -- Extract indent from first line
  local indent = lines[1]:match("^(%s*)") or ""

  -- Extract the complete call (everything from vim.notify to its closing paren)
  local call_start = combined:find("vim%.notify%s*%(")
  if not call_start then
    return nil, nil
  end

  -- Find matching closing parenthesis
  local paren_count = 0
  local call_end = nil
  local in_call = false

  for i = call_start, #combined do
    local char = combined:sub(i, i)

    if char == "(" then
      paren_count = paren_count + 1
      in_call = true
    elseif char == ")" then
      paren_count = paren_count - 1

      if in_call and paren_count == 0 then
        call_end = i
        break
      end
    end
  end

  if not call_end then
    return nil, nil
  end

  local call_text = combined:sub(call_start, call_end)

  -- Extract message, level, and optional opts
  local msg, level, opts = call_text:match(
    "vim%.notify%s*%(%s*(.-)%s*,%s*vim%.log%.levels%.(%u+)%s*(.*)%)"
  )

  if not msg or not level or not LEVEL_MAP[level] then
    return nil, nil
  end

  -- Check for optional opts
  local has_opts = opts and opts:match("^%s*,%s*(.+)")
  local opts_arg = has_opts or nil

  -- Clean message (remove extra whitespace but keep structure)
  msg = msg:gsub("%s+", " "):match("^%s*(.-)%s*$")

  -- Build replacement
  local method = LEVEL_MAP[level]
  local migrated

  if opts_arg then
    -- Clean opts too
    opts_arg = opts_arg:gsub("%s+", " "):match("^%s*(.-)%s*$")
    migrated = string.format('%snotify.%s(%s, %s)', indent, method, msg, opts_arg)
  else
    migrated = string.format('%snotify.%s(%s)', indent, method, msg)
  end

  return migrated, level
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
              col = 0,           -- We do whole-line replacement, so col doesn't matter
              end_col = #line,   -- But we provide it anyway for compatibility
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
              col = 0,                      -- Whole-line replacement
              end_col = #lines[end_idx],    -- Provide for compatibility
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
