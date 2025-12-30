---@module 'usrcmds.migrate.notify.refactor'
---@brief Atomic buffer modification with undo points.
---@description
--- Applies detected notify patterns to buffer text.
--- Ensures:
---   - Single undo point per buffer
---   - Backward iteration (prevents offset corruption)
---   - Import injection at module top
---   - Safe handling of invalid buffers

require("usrcmds.migrate.notify.@types")

local M = {}

local api, cmd = vim.api, vim.cmd
local nvim_buf_get_lines, nvim_buf_set_lines = api.nvim_buf_get_lines, api.nvim_buf_set_lines
local tbl_insert = table.insert
local str_fmt = string.format

--- Check if buffer already imports lib.notify
---@param bufnr integer
---@return boolean has_import
local function has_notify_import(bufnr)
  local lines = nvim_buf_get_lines(bufnr, 0, 50, false)

  for _, line in ipairs(lines) do
    if line:match('require%s*%(?%s*["\']lib%.notify["\']%s*%)') then
      return true
    end
  end

  return false
end

--- Inject lib.notify import at module top (public API)
---@param bufnr integer
function M.inject_import(bufnr)
  if has_notify_import(bufnr) then
    return
  end

  local lines = nvim_buf_get_lines(bufnr, 0, -1, false)
  local insert_line = 0

  -- Find first non-comment, non-blank line after module header
  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= "" and not trimmed:match("^%-%-") and not trimmed:match("^%-%-%[%[") then
      insert_line = i - 1
      break
    end
  end

  local import = 'local notify = require("lib.notify")'
  nvim_buf_set_lines(bufnr, insert_line, insert_line, false, { import, "" })
end

--- Apply single match replacement (public API)
---@param bufnr integer
---@param match MigrateNotify.Match
---@return boolean success
function M.apply_match(bufnr, match)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local start_line = match.line - 1
  local end_line = match.end_line - 1

  -- Handle multiline: replace entire range
  if start_line ~= end_line then
    local lines = nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

    if #lines == 0 then
      return false
    end

    -- Build replacement: preserve indent from first line
    local first_line = lines[1]
    -- local indent = first_line:match("^%s*")
    local before = first_line:sub(1, match.col)
    local new_line = before .. match.replacement

    nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, { new_line })
    return true
  end

  -- Single line: standard replacement
  local lines = api.nvim_buf_get_lines(bufnr, start_line, start_line + 1, false)

  if #lines == 0 then
    return false
  end

  local original_line = lines[1]
  local before = original_line:sub(1, match.col)
  local after = original_line:sub(match.end_col + 1)
  local new_line = before .. match.replacement .. after

  nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, { new_line })

  return true
end

--- Refactor current line
---@param bufnr integer
---@return MigrateNotify.RefactorResult
function M.refactor_line(bufnr)
  local parser = require("usrcmds.migrate_notify.parser")
  local matches = parser.scan_buffer(bufnr)

  local cursor = api.nvim_win_get_cursor(0)
  local current_line = cursor[1]

  -- Filter matches to current line only
  local line_matches = {}
  for _, match in ipairs(matches) do
    if match.line == current_line then
      tbl_insert(line_matches, match)
    end
  end

  if #line_matches == 0 then
    return {
      success = false,
      modified_lines = 0,
      errors = { "No vim.notify pattern found on current line" },
    }
  end

  -- Create undo point
  cmd("undojoin")

  M.inject_import(bufnr)

  local modified = 0
  local errors = {}

  for _, match in ipairs(line_matches) do
    if M.apply_match(bufnr, match) then
      modified = modified + 1
    else
      tbl_insert(errors, str_fmt("Failed to apply match at line %d", match.line))
    end
  end

  return {
    success = modified > 0,
    modified_lines = modified,
    errors = errors,
  }
end

--- Refactor entire buffer
---@param bufnr integer
---@return MigrateNotify.RefactorResult
function M.refactor_buffer(bufnr)
  local parser = require("usrcmds.migrate_notify.parser")
  local matches = parser.scan_buffer(bufnr)

  if #matches == 0 then
    return {
      success = false,
      modified_lines = 0,
      errors = { "No vim.notify patterns found in buffer" },
    }
  end

  -- Create undo point
  cmd("undojoin")

  M.inject_import(bufnr)

  -- Sort matches by line (descending) to prevent offset corruption
  -- For multiline matches, use end_line as primary sort key
  table.sort(matches, function(a, b)
    return a.end_line > b.end_line
  end)

  local modified = 0
  local errors = {}

  for _, match in ipairs(matches) do
    if M.apply_match(bufnr, match) then
      modified = modified + 1
    else
      tbl_insert(errors, str_fmt("Failed at line %d", match.line))
    end
  end

  return {
    success = modified > 0,
    modified_lines = modified,
    errors = errors,
  }
end

--- Refactor selected matches (from Telescope)
---@param selections MigrateNotify.FileMatches[]
---@return table<string, MigrateNotify.RefactorResult>
function M.refactor_selections(selections)
  local results = {}

  for _, file_match in ipairs(selections) do
    local bufnr = vim.fn.bufadd(file_match.path)
    vim.fn.bufload(bufnr)

    -- Create undo point per file
    api.nvim_buf_call(bufnr, function()
      cmd("undojoin")
    end)

    M.inject_import(bufnr)

    -- Sort matches descending
    table.sort(file_match.matches, function(a, b)
      return a.line > b.line
    end)

    local modified = 0
    local errors = {}

    for _, match in ipairs(file_match.matches) do
      if M.apply_match(bufnr, match) then
        modified = modified + 1
      else
        tbl_insert(errors, str_fmt("Line %d", match.line))
      end
    end

    results[file_match.path] = {
      success = modified > 0,
      modified_lines = modified,
      errors = errors,
    }
  end

  return results
end

return M
