---@module 'usrcmds.migrate.notify.refactor'
---@brief Apply notify migrations with proper line/multiline handling
---@description
--- Based on working monofile regex implementation.
--- Key principles:
---   - Single-line: replace inline portion
---   - Multi-line: combine to single line with proper indent
---   - Use string operations (like the working version)

require("usrcmds.migrate.notify.@types")

local M = {}

local api = vim.api

--------------------------------------------------------------------------------
-- Import handling
--------------------------------------------------------------------------------

---Check if buffer has notify import
---@param bufnr integer
---@return boolean has_simple, boolean has_create
local function check_import(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, 50, false)

  local has_simple = false
  local has_create = false

  for _, line in ipairs(lines) do
    -- Check for simple: require("lib.notify")
    if line:match('require%s*%(%s*["\']lib%.notify["\']%s*%)') then
      has_simple = true
    end
    -- Check for create: require("lib.notify").create(...)
    if line:match('require%s*%(%s*["\']lib%.notify["\']%s*%)%.create%s*%(') then
      has_create = true
    end
  end

  return has_simple, has_create
end

---Find first non-comment line
---@param bufnr integer
---@return integer line_idx 0-based index
local function find_first_code_line(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    -- Skip empty lines and comments
    if trimmed ~= "" and not trimmed:match("^%-%-") then
      return i - 1  -- Return 0-based index
    end
  end

  return 0  -- Default to top
end

---Inject import at appropriate position
---@param bufnr integer
---@param use_create boolean If true, use .create("") syntax
---@return boolean added True if import was added
function M.inject_import(bufnr, use_create)
  local has_simple, has_create = check_import(bufnr)

  -- If .create() is required but only simple import exists, upgrade it
  if use_create then
    if has_create then
      return false  -- Already has .create()
    end

    -- Find first non-comment line
    local insert_pos = find_first_code_line(bufnr)

    api.nvim_buf_set_lines(
      bufnr,
      insert_pos,
      insert_pos,
      false,
      { 'local notify = require("lib.notify").create("")', "" }
    )

    return true
  else
    -- Simple import
    if has_simple then
      return false  -- Already has import
    end

    api.nvim_buf_set_lines(
      bufnr,
      0,
      0,
      false,
      { 'local notify = require("lib.notify")', "" }
    )

    return true
  end
end


--------------------------------------------------------------------------------
-- Application (based on working monofile logic)
--------------------------------------------------------------------------------

---Apply single match replacement
---@param bufnr integer
---@param match MigrateNotify.Match
---@return boolean success
function M.apply_match(bufnr, match)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local start_line = match.line - 1      -- Convert to 0-based
  local end_line = match.end_line - 1    -- Convert to 0-based
  local start_col = match.col            -- Already 0-based
  local end_col = match.end_col          -- Already 0-based (exclusive from TS)

  -- Get all affected lines
  local lines = api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

  if #lines == 0 then
    return false
  end

  if start_line == end_line then
    -- Single line replacement (like the working version)
    local line = lines[1]
    local before = line:sub(1, start_col)
    local after = line:sub(end_col + 1)  -- +1 because Lua strings are 1-based
    local new_line = before .. match.replacement .. after

    api.nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, { new_line })
  else
    -- Multiline: collapse to single line (like working refactor_multiline)
    local first_line = lines[1]
    local last_line = lines[#lines]

    -- Extract indent from first line
    local indent = first_line:match("^(%s*)")

    -- Get content before and after the match
    local before = first_line:sub(1, start_col)
    local after = last_line:sub(end_col + 1)

    -- Build single replacement line with proper indent
    local new_line = before .. match.replacement .. after

    -- Replace entire multiline range with single line
    api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, { new_line })
  end

  return true
end

return M
