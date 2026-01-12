---@module 'usrcmds.migrate.notify.parser.migrator'
---@brief Convert notify calls to new format

local extractor = require("usrcmds.migrate.notify.parser.extractor")

local M = {}

---@type table<string, string>
local LEVEL_MAP = {
  TRACE = "trace",
  DEBUG = "debug",
  INFO  = "info",
  WARN  = "warn",
  ERROR = "error",
}

---Migrate vim.notify single line
---@param line string
---@return string|nil migrated, string|nil level
function M.migrate_vim_notify_line(line)
  local call_text, start_col, end_col = extractor.extract_vim_notify(line)

  if not call_text then
    return nil, nil
  end

  local msg, level, opts = call_text:match(
    "vim%.notify%s*%(%s*(.-)%s*,%s*vim%.log%.levels%.(%u+)%s*(.*)%)"
  )

  if not msg or not level or not LEVEL_MAP[level] then
    return nil, nil
  end

  local has_opts = opts and opts:match("^%s*,%s*(.+)")
  local opts_arg = has_opts or nil

  local method = LEVEL_MAP[level]
  local replacement_call

  if opts_arg then
    replacement_call = string.format("notify.%s(%s, %s)", method, msg, opts_arg)
  else
    replacement_call = string.format("notify.%s(%s)", method, msg)
  end

  local before = line:sub(1, start_col)
  local after = line:sub(end_col + 1)

  local migrated = before .. replacement_call .. after

  return migrated, level
end

---Migrate aliased notify single line
---@param line string
---@param notify_alias string
---@param levels_alias string|nil
---@return string|nil migrated, string|nil level
function M.migrate_aliased_line(line, notify_alias, levels_alias)
  local call_text, start_col, end_col = extractor.extract_aliased(line, notify_alias)

  if not call_text then
    return nil, nil
  end

  -- Escape special pattern characters in alias names
  local escaped_notify = notify_alias:gsub("([%.%-%+%*%?%[%]%^%$%(%)%%])", "%%%1")
  local escaped_levels = levels_alias and levels_alias:gsub("([%.%-%+%*%?%[%]%^%$%(%)%%])", "%%%1")

  -- Pattern 1: notify("msg", levels.LEVEL)
  if escaped_levels then
    local pattern = escaped_notify .. "%s*%(%s*(.-)%s*,%s*" .. escaped_levels .. "%.(%u+)%s*(.*)%)"
    local msg, level, opts = call_text:match(pattern)

    if msg and level and LEVEL_MAP[level] then
      local has_opts = opts and opts:match("^%s*,%s*(.+)")
      local opts_arg = has_opts or nil

      local method = LEVEL_MAP[level]
      local replacement_call

      if opts_arg then
        replacement_call = string.format("notify.%s(%s, %s)", method, msg, opts_arg)
      else
        replacement_call = string.format("notify.%s(%s)", method, msg)
      end

      local before = line:sub(1, start_col)
      local after = line:sub(end_col + 1)

      return before .. replacement_call .. after, level
    end
  end

  -- Pattern 2: notify("msg", vim.log.levels.LEVEL) (mixed)
  local pattern = escaped_notify .. "%s*%(%s*(.-)%s*,%s*vim%.log%.levels%.(%u+)%s*(.*)%)"
  local msg, level, opts = call_text:match(pattern)

  if msg and level and LEVEL_MAP[level] then
    local has_opts = opts and opts:match("^%s*,%s*(.+)")
    local opts_arg = has_opts or nil

    local method = LEVEL_MAP[level]
    local replacement_call

    if opts_arg then
      replacement_call = string.format("notify.%s(%s, %s)", method, msg, opts_arg)
    else
      replacement_call = string.format("notify.%s(%s)", method, msg)
    end

    local before = line:sub(1, start_col)
    local after = line:sub(end_col + 1)

    return before .. replacement_call .. after, level
  end

  return nil, nil
end

---Migrate multiline vim.notify
---@param lines string[]
---@return string|nil migrated, string|nil level
function M.migrate_multiline(lines)
  local combined = table.concat(lines, " ")
  local indent = lines[1]:match("^(%s*)") or ""

  local call_start = combined:find("vim%.notify%s*%(")
  if not call_start then
    return nil, nil
  end

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

  local msg, level, opts = call_text:match(
    "vim%.notify%s*%(%s*(.-)%s*,%s*vim%.log%.levels%.(%u+)%s*(.*)%)"
  )

  if not msg or not level or not LEVEL_MAP[level] then
    return nil, nil
  end

  local has_opts = opts and opts:match("^%s*,%s*(.+)")
  local opts_arg = has_opts or nil

  msg = msg:gsub("%s+", " "):match("^%s*(.-)%s*$")

  local method = LEVEL_MAP[level]
  local migrated

  if opts_arg then
    opts_arg = opts_arg:gsub("%s+", " "):match("^%s*(.-)%s*$")
    migrated = string.format('%snotify.%s(%s, %s)', indent, method, msg, opts_arg)
  else
    migrated = string.format('%snotify.%s(%s)', indent, method, msg)
  end

  return migrated, level
end

return M
