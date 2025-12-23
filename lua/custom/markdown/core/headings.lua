---@module 'custom.markdown.core.headings'
--- ATX heading navigation + level shifting. Pure logic, view preserved.
--- Provides a single exported `M.shift_range` that accepts arbitrary integer
--- deltas (positive => increase, negative => decrease).
---@class MarkdownHeadings
local M = {}

local api, fn, cmd = vim.api, vim.fn, vim.cmd
local cfg = require("custom.markdown.config").get

-- ============================================================================
-- Helper: navigate to previous / next heading (H2+)
-- ============================================================================

---@return nil
function M.goto_prev_heading()
  -- Search backward for a heading starting with at least "## ".
  fn.search("^##\\+\\s\\+.*$", "bWs")
  cmd("nohlsearch")
end

---@return nil
function M.goto_next_heading()
  -- Search forward for a heading starting with at least "## ".
  fn.search("^##\\+\\s\\+.*$", "Ws")
  cmd("nohlsearch")
end

-- ============================================================================
-- Core: shift a single heading line
-- ============================================================================

--- Shift a single line with extended semantics:
--- - If no heading exists and delta > 0: insert "# " in front of the line
--- - If heading level == 1 and delta < 0: remove heading completely
--- - Otherwise: increase/decrease heading level within bounds
---
--- Returns the new line and a boolean indicating whether a change happened.
---@param line string
---@param delta integer
---@param min_level integer
---@return string, boolean
local function shift_heading_line(line, delta, min_level)
  -- Ignore empty or whitespace-only lines
  if line == "" or line:match("^%s*$") then
    return line, false
  end

  -- Try to match an ATX heading: indent + hashes + space + text
  local hashes, rest = line:match("^(%s*#+)%s+(.*)$")

  -- Case 1: no heading exists
  if not hashes then
    -- Only react to positive delta (increase)
    if delta > 0 then
      -- Prepend a level-1 heading
      return "# " .. line, true
    end
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

-- Core buffer range shifter: internal implementation (unchanged)
local function shift_range_internal(bufnr, srow, erow, delta, min_level)
  -- nvim_buf_get_lines: start is 0-based inclusive, end is 0-based exclusive.
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
      local out, did = shift_heading_line(line, delta, min_level)
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

--- Public: shift a given 1-based line range (operator/whole-buffer use).
--- Accepts any integer `delta` (positive => increase, negative => decrease).
--- Returns number of changed lines (0..).
---@param srow integer
---@param erow integer
---@param delta integer
---@return integer changed
function M.shift_range(srow, erow, delta)
  -- validate args
  if type(srow) ~= "number" or type(erow) ~= "number" then
    return 0
  end
  if srow < 1 or erow < srow then
    return 0
  end
  if type(delta) ~= "number" or delta == 0 then
    return 0
  end

  -- guard filetype and buffer validity
  if vim.bo.filetype ~= "markdown" then
    return 0
  end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then
    return 0
  end

  -- determine minimal allowed heading level (H1 protection)
  local min_level = cfg().protect_h1 and 2 or 1

  -- preserve view only if something changes
  local view = fn.winsaveview()
  local changed = shift_range_internal(bufnr, srow, erow, delta, min_level)

  if changed > 0 then
    fn.winrestview(view)
  end

  return changed
end

-- Wrapper für Whole-Buffer oder aktuelle Auswahl (fix save/restore order + accept arbitrary delta)
---@param delta integer
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

  -- use unified export
  local changed = M.shift_range(srow, erow, delta)

  if changed > 0 then
    -- nothing additional required: M.shift_range already restored view when changed
  end
end

-- Operator helpers: read optional repeat count from buffer-local var
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

return M
