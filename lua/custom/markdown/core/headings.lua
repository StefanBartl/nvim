---@module 'custom.markdown.core.headings'
--- ATX heading navigation + level shifting. Pure logic, view preserved.
--- FIXED: Visual mode only modifies existing headings
---@class MarkdownHeadings
local M = {}

local api, fn, cmd = vim.api, vim.fn, vim.cmd
local cfg = require("custom.markdown.config").get

-- ============================================================================
-- Helper: navigate to previous / next heading (H2+) with optional count for level
-- ============================================================================
---Navigate to previous heading. With count, jumps to heading of that level.
---@return nil
function M.goto_prev_heading()
  local count = vim.v.count
  local pattern

  if count > 0 then
    -- With count: jump to heading of specific level (e.g., 2<C-p> -> ## heading)
    local hashes = string.rep("#", count)
    pattern = "^" .. hashes .. "\\s\\+.*$"
  else
    -- Without count: jump to any H2+ heading
    pattern = "^##\\+\\s\\+.*$"
  end

  vim.fn.search(pattern, "bWs")
  vim.cmd("nohlsearch")
end

---Navigate to next heading. With count, jumps to heading of that level.
---@return nil
function M.goto_next_heading()
  local count = vim.v.count
  local pattern

  if count > 0 then
    -- With count: jump to heading of specific level (e.g., 2<C-f> -> ## heading)
    local hashes = string.rep("#", count)
    pattern = "^" .. hashes .. "\\s\\+.*$"
  else
    -- Without count: jump to any H2+ heading
    pattern = "^##\\+\\s\\+.*$"
  end

  vim.fn.search(pattern, "Ws")
  vim.cmd("nohlsearch")
end

-- ============================================================================
-- Helper: Check if line is a heading
-- ============================================================================

---@param line string
---@return boolean
---@diagnostic disable-next-line: unused-local, unused-function
local function is_heading(line)
  return line:match("^%s*#+%s+") ~= nil
end

-- ============================================================================
-- Core: shift a single heading line WITH context awareness
-- ============================================================================

--- Shift a single line with context-aware semantics:
--- - In multi-line context (visual mode): ONLY process existing headings
--- - In single-line context (normal mode): allow creating new headings
---
--- Parameters:
--- @param line string The line to process
--- @param delta integer Positive = increase level, negative = decrease level
--- @param min_level integer Minimum allowed heading level (usually 1 or 2)
--- @param allow_creation boolean If true, non-headings can become headings (normal mode)
---
--- Returns:
--- @return string new_line The modified line
--- @return boolean changed Whether the line was actually modified
local function shift_heading_line(line, delta, min_level, allow_creation)
  -- Ignore empty or whitespace-only lines
  if line == "" or line:match("^%s*$") then
    return line, false
  end

  -- Try to match an ATX heading: indent + hashes + space + text
  local hashes, rest = line:match("^(%s*#+)%s+(.*)$")

  -- Case 1: no heading exists
  if not hashes then
    -- CRITICAL FIX: Only create new headings in single-line context
    if delta > 0 and allow_creation then
      -- Prepend a level-1 heading
      return "# " .. line, true
    end
    -- In multi-line context (visual mode), skip non-headings
    return line, false
  end

  -- Extract indent and current level
  local indent = hashes:match("^%s*") or ""
  local level = #hashes - #indent

  -- Case 2: level-1 heading and decrease => remove heading entirely
  if level == 1 and delta < 0 then
    return rest, true
  end

  -- Case 3: normal level shift
  local new_level = math.max(min_level, math.min(6, level + delta))
  if new_level == level then
    return line, false
  end

  return string.format(
    "%s%s %s",
    indent,
    string.rep("#", new_level),
    rest
  ), true
end

-- ============================================================================
-- Core buffer range shifter with context awareness
-- ============================================================================

--- Internal implementation with allow_creation parameter
--- @param bufnr integer Buffer number
--- @param srow integer Start row (1-based)
--- @param erow integer End row (1-based)
--- @param delta integer Shift amount
--- @param min_level integer Minimum heading level
--- @param allow_creation boolean Allow creating headings from non-headings
--- @return integer changed Number of lines changed
local function shift_range_internal(bufnr, srow, erow, delta, min_level, allow_creation)
  -- nvim_buf_get_lines: start is 0-based inclusive, end is 0-based exclusive
  local lines = api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  local changed = 0
  local in_fence = false
  local fence_pat = "^%s*([`~]{3,})"

  for i = 1, #lines do
    local line = lines[i]
    local fence = line:match(fence_pat)
    if fence then
      in_fence = not in_fence
    end
    if not in_fence then
      local out, did = shift_heading_line(line, delta, min_level, allow_creation)
      if did then
        lines[i] = out
        changed = changed + 1
      end
    end
  end

  if changed > 0 then
    api.nvim_buf_set_lines(bufnr, srow - 1, erow, false, lines)
  end

  return changed
end

-- ============================================================================
-- Public API: shift_range (for operator/programmatic use)
-- ============================================================================

--- Shift a given 1-based line range
--- Automatically determines context: single-line allows creation, multi-line doesn't
--- @param srow integer Start row (1-based)
--- @param erow integer End row (1-based)
--- @param delta integer Shift amount (positive = increase, negative = decrease)
--- @return integer changed Number of lines changed
function M.shift_range(srow, erow, delta)
  -- Validate args
  if type(srow) ~= "number" or type(erow) ~= "number" then
    return 0
  end
  if srow < 1 or erow < srow then
    return 0
  end
  if type(delta) ~= "number" or delta == 0 then
    return 0
  end

  -- Guard filetype and buffer validity
  if vim.bo.filetype ~= "markdown" then
    return 0
  end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    return 0
  end

  -- Determine minimal allowed heading level (H1 protection)
  local min_level = cfg().protect_h1 and 2 or 1

  -- CRITICAL: Determine if we should allow creating new headings
  -- Only in single-line context (normal mode on one line)
  local is_single_line = (srow == erow)
  local allow_creation = is_single_line

  -- Preserve view only if something changes
  local view = fn.winsaveview()
  local changed = shift_range_internal(bufnr, srow, erow, delta, min_level, allow_creation)

  if changed > 0 then
    fn.winrestview(view)
  end

  return changed
end

-- ============================================================================
-- Visual Mode specific function (explicit multi-line context)
-- ============================================================================

--- Process current visual selection
--- NEVER creates new headings, only processes existing ones
--- @param delta integer Shift amount
--- @return nil
function M.shift_visual_selection(delta)
  if type(delta) ~= "number" or delta == 0 then
    return
  end
  if vim.bo.filetype ~= "markdown" then
    return
  end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    return
  end

  -- Capture selection BEFORE exiting visual mode
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  local srow = math.min(start_line, end_line)
  local erow = math.max(start_line, end_line)

  -- Exit visual mode
  vim.cmd('normal! \\<Esc>')

  -- Process the captured range
  -- Use shift_range which now automatically handles multi-line context
  if srow > 0 and erow > 0 then
    M.shift_range(srow, erow, delta)
  end
end

-- ============================================================================
-- Wrapper for selection (DEPRECATED - use shift_range or shift_visual_selection)
-- ============================================================================

--- Shift current selection or line
--- @param delta integer
function M.shift_selection(delta)
  if type(delta) ~= "number" or delta == 0 then
    return
  end
  if vim.bo.filetype ~= "markdown" then
    return
  end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    return
  end

  local srow, erow
  local mode = (vim.api.nvim_get_mode() or {}).mode or "n"

  if mode:match("^[vV\022]") then
    local ok_s, start_mark = pcall(vim.api.nvim_buf_get_mark, bufnr, "<")
    local ok_e, end_mark = pcall(vim.api.nvim_buf_get_mark, bufnr, ">")
    if ok_s and ok_e and start_mark and end_mark then
      srow = start_mark[1]
      erow = end_mark[1]
    end
  end

  srow = srow or api.nvim_win_get_cursor(0)[1]
  erow = erow or srow

  -- Use unified export with automatic context detection
  M.shift_range(srow, erow, delta)
end

-- ============================================================================
-- Operator helpers (UNCHANGED)
-- ============================================================================

local function op_get_repeat()
  local n = vim.b._markdown_heading_op_count
  if type(n) ~= "number" or n < 1 then
    return 1
  end
  vim.b._markdown_heading_op_count = nil
  return n
end

---@param _ string
function M._op_increase(_)
  local n = op_get_repeat()
  local srow = api.nvim_buf_get_mark(0, "[")[1]
  local erow = api.nvim_buf_get_mark(0, "]")[1]
  if srow and erow and srow > 0 and erow > 0 then
    M.shift_range(math.min(srow, erow), math.max(srow, erow), n)
  end
end

---@param _ string
function M._op_decrease(_)
  local n = op_get_repeat()
  local srow = api.nvim_buf_get_mark(0, "[")[1]
  local erow = api.nvim_buf_get_mark(0, "]")[1]
  if srow and erow and srow > 0 and erow > 0 then
    M.shift_range(math.min(srow, erow), math.max(srow, erow), -n)
  end
end

-- ============================================================================
-- ALTERNATIVE: Noch explizitere Trennung
-- ============================================================================

-- Noch deutlichere Unterscheidung zwischen Single-Line und Multi-Line bezüglich "wer darf 0 headline zu level 1 headline aufwerten"

-- --- Shift single line (normal mode) - allows creating headings
-- --- @param row integer Line number (1-based)
-- --- @param delta integer
-- --- @return integer changed
-- function M.shift_single_line(row, delta)
  -- if type(row) ~= "number" or row < 1 then
    -- return 0
  -- end
  -- if type(delta) ~= "number" or delta == 0 then
    -- return 0
  -- end
  -- if vim.bo.filetype ~= "markdown" then
    -- return 0
  -- end

  -- local bufnr = api.nvim_get_current_buf()
  -- if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    -- return 0
  -- end

  -- local min_level = cfg().protect_h1 and 2 or 1
  -- local view = fn.winsaveview()

  -- EXPLICITLY allow creation in single-line mode
  -- local changed = shift_range_internal(bufnr, row, row, delta, min_level, true)

  -- if changed > 0 then
    -- fn.winrestview(view)
  -- end

  -- return changed
-- end

-- --- Shift multiple lines (visual mode) - NEVER creates headings
-- --- @param srow integer Start row (1-based)
-- --- @param erow integer End row (1-based)
-- --- @param delta integer
-- --- @return integer changed
-- function M.shift_multi_line(srow, erow, delta)
  -- if type(srow) ~= "number" or type(erow) ~= "number" then
    -- return 0
  -- end
  -- if srow < 1 or erow < srow then
    -- return 0
  -- end
  -- if type(delta) ~= "number" or delta == 0 then
    -- return 0
  -- end
  -- if vim.bo.filetype ~= "markdown" then
    -- return 0
  -- end

  -- local bufnr = api.nvim_get_current_buf()
  -- if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    -- return 0
  -- end

  -- local min_level = cfg().protect_h1 and 2 or 1
  -- local view = fn.winsaveview()

--  EXPLICITLY disallow creation in multi-line mode
  -- local changed = shift_range_internal(bufnr, srow, erow, delta, min_level, false)

  -- if changed > 0 then
    -- fn.winrestview(view)
  -- end

  -- return changed
-- end

return M
