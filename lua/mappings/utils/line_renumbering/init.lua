---@module "mappings.utils.line_renumbering"
--- Renumber ordered lists around the cursor.
---
--- Supports nested lists (indent-based grouping).
--- Only "N. " style (dot) is handled; "N)" is left unchanged.
---
--- API:
---   M.renumber_list_at_cursor()   – main entry point, call after move/indent ops
---   M.is_in_ordered_list()        – returns true if cursor is on/near a numbered item

local M = {}

-- Pattern: optional leading spaces, a number, a dot, a space.
local ITEM_PAT   = "^(%s*)(%d+)(%.)(%s+)"
-- Pattern for any list item (ordered or unordered) — used for boundary detection.
local LIST_PAT   = "^%s*[%d%-*+]"
-- Pattern for a continuation line (non-empty, no list marker) that belongs to an item.
local CONT_PAT   = "^%s+%S"

--- Count leading spaces in a string.
---@param s string
---@return integer
local function indent_of(s)
  local spaces = s:match("^(%s*)")
  return #spaces
end

--- Return true if the line looks like part of a list (item or continuation).
---@param line string
---@return boolean
local function is_list_line(line)
  if line:match("^%s*$") then return false end
  return line:match(LIST_PAT) ~= nil or line:match(CONT_PAT) ~= nil
end

--- Find the 1-based start and end lines of the list block containing `lnum`.
---@param bufnr integer
---@param lnum integer   1-based
---@return integer start_lnum, integer end_lnum
local function find_list_bounds(bufnr, lnum)
  local total = vim.api.nvim_buf_line_count(bufnr)

  local start_ln = lnum
  while start_ln > 1 do
    local prev = vim.api.nvim_buf_get_lines(bufnr, start_ln - 2, start_ln - 1, false)[1] or ""
    if not is_list_line(prev) then break end
    start_ln = start_ln - 1
  end

  local end_ln = lnum
  while end_ln < total do
    local next = vim.api.nvim_buf_get_lines(bufnr, end_ln, end_ln + 1, false)[1] or ""
    if not is_list_line(next) then break end
    end_ln = end_ln + 1
  end

  return start_ln, end_ln
end

--- Renumber all ordered items in `lines` in-place.
--- Per-indent-level counters are maintained; a counter resets when a shallower
--- indent level is seen again (i.e. we started a fresh sub-list).
---@param lines string[]
---@return string[]  modified lines (same table, mutated)
local function renumber_lines(lines)
  -- counters[indent_spaces] = next_number
  local counters = {}
  -- Track the deepest indent level seen so far at each level for reset logic.
  local last_indent = -1

  for i, line in ipairs(lines) do
    local indent, _, dot, space = line:match(ITEM_PAT)
    if indent and dot then
      local lvl = #indent

      -- If we've gone back to a shallower level, reset all deeper counters.
      if lvl < last_indent then
        for k in pairs(counters) do
          if k > lvl then counters[k] = nil end
        end
      end
      last_indent = lvl

      counters[lvl] = (counters[lvl] or 0) + 1
      local rest = line:match("^%s*%d+%.%s+(.*)")  or ""
      lines[i] = indent .. tostring(counters[lvl]) .. dot .. space .. rest
    end
    -- Continuation lines and unordered items are left untouched.
  end
  return lines
end

--- Main entry: renumber the ordered list that contains the cursor line.
--- No-op if the cursor is not inside a numbered list.
function M.renumber_list_at_cursor()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum   = cursor[1]   -- 1-based
  local col    = cursor[2]   -- 0-based

  local cur_line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""

  -- Bail if this line is not part of a list at all.
  if not is_list_line(cur_line) then return end

  local start_ln, end_ln = find_list_bounds(bufnr, lnum)

  -- Get lines (0-based indexing for nvim API).
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_ln - 1, end_ln, false)

  -- Check there is at least one ordered item — skip purely unordered lists.
  local has_ordered = false
  for _, l in ipairs(lines) do
    if l:match(ITEM_PAT) then has_ordered = true; break end
  end
  if not has_ordered then return end

  local new_lines = renumber_lines(vim.deepcopy(lines))

  -- Only write back if something changed (avoid spurious undo entries).
  local changed = false
  for i = 1, #lines do
    if lines[i] ~= new_lines[i] then changed = true; break end
  end

  if changed then
    vim.api.nvim_buf_set_lines(bufnr, start_ln - 1, end_ln, false, new_lines)
    -- Restore cursor (buf_set_lines may shift it).
    vim.api.nvim_win_set_cursor(0, { lnum, col })
  end
end

--- Returns true if the cursor line (or adjacent lines) is part of an ordered list.
---@return boolean
function M.is_in_ordered_list()
  local bufnr  = vim.api.nvim_get_current_buf()
  local lnum   = vim.api.nvim_win_get_cursor(0)[1]
  local line   = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  return line:match(ITEM_PAT) ~= nil
end

return M
