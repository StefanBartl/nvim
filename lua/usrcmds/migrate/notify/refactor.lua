---@module 'usrcmds.migrate.notify.refactor'
---@brief Simple whole-line replacement (like working monofile)
---@description
--- No complex offset calculations - just replace complete lines.
--- This is robust and matches the working regex version.

require("usrcmds.migrate.notify.@types")

local M = {}

local api = vim.api

--------------------------------------------------------------------------------
-- Import handling
--------------------------------------------------------------------------------

---@param bufnr integer
---@return boolean
local function has_import(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, 50, false)

  for _, line in ipairs(lines) do
    if line:match('require%s*%(%s*["\']lib%.notify["\']%s*%)') then
      return true
    end
  end

  return false
end

---Inject import at top of file
---@param bufnr integer
---@return boolean added True if import was added
function M.inject_import(bufnr)
  if has_import(bufnr) then
    return false
  end

  api.nvim_buf_set_lines(
    bufnr,
    0,
    0,
    false,
    { 'local notify = require("lib.notify").create("")', "" }
  )

  return true
end

--------------------------------------------------------------------------------
-- Simple line replacement
--------------------------------------------------------------------------------

---Apply match by replacing complete line range
---@param bufnr integer
---@param match MigrateNotify.Match (line and end_line are 1-based)
---@return boolean success
function M.apply_match(bufnr, match)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Parser gives us 1-based line numbers
  -- nvim_buf_set_lines wants 0-based indices where end is exclusive
  --
  -- Example: Replace lines 5-7 (1-based, inclusive)
  -- -> nvim_buf_set_lines(bufnr, 4, 7, ...)
  --    This replaces lines [4,5,6] (0-based) = lines [5,6,7] (1-based)

  local start_idx = match.line - 1         -- 1-based -> 0-based
  local end_idx = match.end_line           -- 1-based inclusive -> 0-based exclusive

  -- Replace line range with single replacement
  local ok, err = pcall(
    api.nvim_buf_set_lines,
    bufnr,
    start_idx,
    end_idx,
    false,
    { match.replacement }
  )

  if not ok then
    vim.notify(
      string.format("Failed at lines %d-%d: %s", match.line, match.end_line, tostring(err)),
      vim.log.levels.ERROR
    )
  end

  return ok
end

return M
