---@module 'custom.markdown.core.wrap'
--- Visual wrap helpers (e.g., bold via **). Uses set_text for minimal edits.

---@class MarkdownWrap
local M = {}

local api = vim.api
local fn = vim.fn
local cfg = require("custom.markdown.config").get

--- Get visual selection boundaries (works in visual mode and after visual mode)
---@return integer|nil row 0-based row
---@return integer|nil scol 0-based start column (leftmost)
---@return integer|nil ecol 0-based end column (rightmost, inclusive)
local function get_visual_selection()
  -- Get current mode to check if we're still in visual mode
  local mode = fn.mode()
  local is_visual = mode:match('[vV\22]') ~= nil

  if is_visual then
    -- In visual mode: use current cursor and v_start
    local cursor = api.nvim_win_get_cursor(0)
    local vstart_ok, vstart = pcall(fn.getpos, 'v')

    if not (vstart_ok and vstart) then
      return nil, nil, nil
    end

    local row1 = cursor[1] - 1  -- 0-based
    local col1 = cursor[2]      -- Already 0-based from nvim_win_get_cursor
    local row2 = vstart[2] - 1  -- 0-based
    local col2 = vstart[3] - 1  -- 0-based

    -- Only handle single-line
    if row1 ~= row2 then
      return nil, nil, nil
    end

    -- Ensure left-to-right
    local scol = math.min(col1, col2)
    local ecol = math.max(col1, col2)

    return row1, scol, ecol
  else
    -- After visual mode: use marks '< and '>
    local ok_start, start_pos = pcall(fn.getpos, "'<")
    local ok_end, end_pos = pcall(fn.getpos, "'>")

    if not (ok_start and ok_end and start_pos and end_pos) then
      return nil, nil, nil
    end

    local start_row = start_pos[2] - 1  -- 0-based
    local start_col = start_pos[3] - 1  -- 0-based
    local end_row = end_pos[2] - 1      -- 0-based
    local end_col = end_pos[3] - 1      -- 0-based

    -- Only handle single-line
    if start_row ~= end_row then
      return nil, nil, nil
    end

    -- Marks should already be in correct order, but ensure it
    local scol = math.min(start_col, end_col)
    local ecol = math.max(start_col, end_col)

    return start_row, scol, ecol
  end
end

--- Reselect text in visual mode
---@param row integer 0-based row
---@param scol integer 0-based start column
---@param ecol integer 0-based end column (inclusive)
local function reselect_visual(row, scol, ecol)
  -- Convert back to 1-based for Vim
  fn.setpos("'<", {0, row + 1, scol + 1, 0})
  fn.setpos("'>", {0, row + 1, ecol + 1, 0})

  -- Re-enter visual mode
  local reselect = api.nvim_replace_termcodes("<Esc>gv", true, false, true)
  api.nvim_feedkeys(reselect, "nx", false)
end

--- Wrap text with asterisks
---@param count integer Number of asterisks on each side (2 for bold)
---@return nil
local function wrap_with_asterisks(count)
  local bufnr = api.nvim_get_current_buf()

  -- Get selection
  local row, scol, ecol = get_visual_selection()

  if not (row and scol and ecol) then
    vim.notify("[Custom.Markdown] No valid selection", vim.log.levels.WARN)
    return
  end

  -- Get selected text (ecol is inclusive, so +1 for end)
  local lines = api.nvim_buf_get_text(bufnr, row, scol, row, ecol + 1, {})
  local selected_text = table.concat(lines, "\n")

  -- Build wrapped text
  local pad = string.rep("*", count)
  local wrapped = pad .. selected_text .. pad

  -- Replace text
  api.nvim_buf_set_text(bufnr, row, scol, row, ecol + 1, {wrapped})

  -- Reselect based on config
  if cfg().keep_inner_selection then
    -- Select only the inner text (without the added asterisks)
    reselect_visual(row, scol + count, scol + count + #selected_text - 1)
  else
    -- Select the entire wrapped text (including asterisks)
    reselect_visual(row, scol, ecol + (2 * count))
  end
end

--- Toggle bold: wrap if not wrapped, unwrap if already wrapped
---@return nil
function M.toggle_visual_bold()
  local bufnr = api.nvim_get_current_buf()
  local row, scol, ecol = get_visual_selection()

  if not (row and scol and ecol) then
    vim.notify("[Custom.Markdown] No valid selection", vim.log.levels.WARN)
    return
  end

  -- Check if already wrapped (expand selection by 2 chars on each side)
  local check_start = math.max(0, scol - 2)
  local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  local check_end = math.min(#line, ecol + 3)

  local extended = line:sub(check_start + 1, check_end)

  -- Check if surrounded by **
  if extended:match("^%*%*.-%*%*$") then
    -- Unwrap: remove ** on both sides
    local inner_start = scol - 2
    local inner_end = ecol + 3
    local unwrapped = line:sub(scol + 1, ecol + 1)  -- Get inner text
    api.nvim_buf_set_text(bufnr, row, inner_start, row, inner_end, {unwrapped})
    reselect_visual(row, inner_start, inner_start + #unwrapped - 1)
  else
    -- Wrap
    wrap_with_asterisks(2)
  end
end

return M
