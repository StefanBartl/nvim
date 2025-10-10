---@module 'custom.markdown.core.headings'
--- ATX heading navigation + level shifting. Pure logic, view preserved.
---
--- This module exposes functions to navigate and change ATX heading levels
--- in Markdown buffers. It is defensive: it skips fenced code blocks and
--- preserves window view. The implementation favors robustness of mode
--- detection and mark handling to avoid intermittent failures when invoked
--- from visual mappings or operator-pending mappings.
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

--- Shift a single line that matches an ATX heading.
--- Returns the new line and a boolean whether a change happened.
--- Non-heading lines are returned unchanged with false.
---@param line string
---@param delta integer
---@param min_level integer
---@return string, boolean
local function shift_heading_line(line, delta, min_level)
  if line == "" or line:match("^%s*$") then return line, false end
  -- Capture leading indent + hashes, require at least one space between hashes and text.
  local hashes, rest = line:match("^(%s*#+)%s+(.*)$")
  if not hashes then return line, false end
  local indent = hashes:match("^%s*") or ""
  local level = #hashes - #indent
  local new = math.max(min_level, math.min(6, level + delta))
  if new == level then return line, false end
  return string.format("%s%s %s", indent, string.rep("#", new), rest), true
end

-- ============================================================================
-- Core: shift a buffer range
-- ============================================================================

--- Shift headings within a 1-based inclusive range [srow, erow].
--- Skips fenced code blocks (``` or ~~~).
---@param bufnr integer
---@param srow integer
---@param erow integer
---@param delta integer
---@param min_level integer
---@return integer changed  -- number of lines changed
local function shift_range(bufnr, srow, erow, delta, min_level)
  -- nvim_buf_get_lines: start is 0-based inclusive, end is 0-based exclusive.
  local lines = api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  local changed = 0
  local in_fence = false
  local fence_pat = "^%s*([`~]{3,})"
  for i = 1, #lines do
    local line = lines[i]
    local fence = line:match(fence_pat)
    if fence then
      -- Toggle fence state; does not try to match exact fence length or language.
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
    -- Replace the original range only when something changed (keeps undo tidy).
    api.nvim_buf_set_lines(bufnr, srow - 1, erow, false, lines)
  end
  return changed
end

-- ============================================================================
-- Public: shift_range wrapper with guards
-- ============================================================================

--- Public: shift a given 1-based line range (operator/whole-buffer use).
--- Returns number of changed lines (0..).
---@param srow integer
---@param erow integer
---@param delta integer  -- +1 / -1
---@return integer changed
function M.shift_range(srow, erow, delta)
  if delta ~= 1 and delta ~= -1 then return 0 end
  if vim.bo.filetype ~= "markdown" then return 0 end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then return 0 end
  local min_level = cfg().protect_h1 and 2 or 1

  -- Preserve view (cursor, topline, etc.) while making buffer edits.
  local view = fn.winsaveview()
  local changed = shift_range(bufnr, srow, erow, delta, min_level)
  fn.winrestview(view)
  return changed
end

-- ============================================================================
-- Public: shift based on current mode (line or visual selection)
-- ============================================================================

--- Shift current line or visual selection by delta.
--- Visual detection uses nvim_get_mode() which is more stable than mode(1).
---@param delta integer
---@return nil
function M.shift(delta)
  if delta ~= 1 and delta ~= -1 then return end
  if vim.bo.filetype ~= "markdown" then return end
  local bufnr = api.nvim_get_current_buf()
  if not (api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_is_valid(bufnr)) then return end

  local srow, erow

  -- Use nvim_get_mode().mode which returns a simple string like 'n', 'v', 'V', or '^V'
  -- This avoids subtle variants returned by mode(1) that can break a strict pattern.
  local current_mode = (api.nvim_get_mode() or {}).mode or fn.mode()
  if tostring(current_mode):match("^[vV\022]") then
    -- Try to read visual marks '< and '>
    local ok, ms = pcall(api.nvim_buf_get_mark, 0, "<")
    local ok2, me = pcall(api.nvim_buf_get_mark, 0, ">")
    if ok and ok2 and type(ms) == "table" and type(me) == "table" and ms[1] > 0 and me[1] > 0 then
      srow = math.min(ms[1], me[1])
      erow = math.max(ms[1], me[1])
    else
      -- Fallback: if marks are not available, use current cursor line.
      local cur = api.nvim_win_get_cursor(0)
      srow, erow = cur[1], cur[1]
    end
  else
    local cur = api.nvim_win_get_cursor(0)
    srow, erow = cur[1], cur[1]
  end

  M.shift_range(srow, erow, delta)
end

function M.increase() M.shift(1) end
function M.decrease() M.shift(-1) end

-- ============================================================================
-- Operator-pending helpers (use with g@); these remain unchanged except for
-- defensive guards.
-- ============================================================================

--- Operator-pending increase helper; simple and kept small for operatorfunc.
---@param _ string
function M._op_increase(_)
  local srow = api.nvim_buf_get_mark(0, "[")[1]
  local erow = api.nvim_buf_get_mark(0, "]")[1]
  if srow and erow and srow > 0 and erow > 0 then
    M.shift_range(math.min(srow, erow), math.max(srow, erow), 1)
  end
end

--- Operator-pending decrease helper; simple and kept small for operatorfunc.
---@param _ string
function M._op_decrease(_)
  local srow = api.nvim_buf_get_mark(0, "[")[1]
  local erow = api.nvim_buf_get_mark(0, "]")[1]
  if srow and erow and srow > 0 and erow > 0 then
    M.shift_range(math.min(srow, erow), math.max(srow, erow), -1)
  end
end

return M
