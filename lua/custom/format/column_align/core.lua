---@module 'custom.format.column_align.core'
---@brief Core implementation for column alignment operations
---@description
--- Provides functions to align visually selected characters to a target column
--- with configurable fill characters. Supports single-line, multi-line (block),
--- and repeat operations.

local notify = require("lib.nvim.notify").create("[custom.format.column_align.core]")

local M = {}

local api = vim.api

-- Module state for repeat operations
---@type Custom.Format.ColAlign.State
local state = {
  last_target_col = nil,
  last_fill_char = nil,
}

---Calculate display width accounting for UTF-8 multi-byte characters
---@param str string Input string
---@return integer width Display width in columns
local function display_width(str)
  if type(str) ~= "string" then
    return 0
  end
  local ok, width = pcall(vim.fn.strdisplaywidth, str)
  return ok and width or #str
end

---Extract single character at byte position, handling UTF-8
---@param line string Line content
---@param byte_pos integer Byte position (0-based)
---@return string char, integer byte_len
local function get_char_at_pos(line, byte_pos)
  -- Convert byte position to character index
  local char_idx = vim.str_utfindex(line, byte_pos)
  if not char_idx then
    return line:sub(byte_pos + 1, byte_pos + 1), 1
  end

  -- Find next character boundary to determine byte length
  local next_byte = vim.str_byteindex(line, char_idx + 1) or #line
  local char = line:sub(byte_pos + 1, next_byte)
  return char, #char
end

---Validate visual selection for alignment operation
---@return boolean valid, string|nil error_msg, table|nil selection_data
local function validate_selection()
  -- Get selection marks first (they persist after leaving visual mode)
  local start_pos = api.nvim_buf_get_mark(0, "<")
  local end_pos = api.nvim_buf_get_mark(0, ">")

  -- Check if marks are valid (both must be on same buffer and valid positions)
  if not start_pos or not end_pos or start_pos[1] == 0 or end_pos[1] == 0 then
    return false, "No valid visual selection found", nil
  end

  -- Determine mode from mark positions
  local mode
  if start_pos[1] == end_pos[1] then
    -- Single line selection
    mode = "v"
  elseif start_pos[2] == end_pos[2] then
    -- Block mode (same column)
    mode = "\22"
  else
    -- Multi-line visual
    mode = "V"
  end

  return true, nil, {
    start_line = start_pos[1],
    end_line = end_pos[1],
    start_col = start_pos[2],
    end_col = end_pos[2],
    mode = mode,
  }
end

---Align single line to target column
---@param line_nr integer Line number (1-based)
---@param start_col integer Start column (0-based byte index)
---@param end_col integer End column (0-based byte index)
---@param target_col integer Target column (1-based)
---@param fill_char string Fill character
---@return boolean success, string|nil error_msg
local function align_single_line(line_nr, start_col, end_col, target_col, fill_char)
  local lines = api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)
  local line = lines and lines[1]
  if not line then
    return false, "Failed to read line"
  end

  -- Extract character at selection (handle UTF-8)
  local selected_char, char_len = get_char_at_pos(line, start_col)

  -- Check if exactly one character selected (single-line visual)
  if end_col - start_col + 1 ~= char_len then
    return false, "Select exactly one character"
  end

  -- Validate target column
  local current_col = start_col + 1  -- Convert to 1-based
  if target_col <= current_col then
    return false, "Target column must be greater than current position"
  end

  -- Calculate fill
  local fill_length = target_col - current_col
  local before = line:sub(1, start_col)
  local after = line:sub(start_col + char_len + 1)
  local fill = string.rep(fill_char, fill_length)

  -- Build new line
  local new_line = before .. fill .. selected_char .. after

  -- Apply change
  local ok = pcall(api.nvim_buf_set_lines, 0, line_nr - 1, line_nr, false, { new_line })
  if not ok then
    return false, "Failed to update buffer"
  end

  -- Move cursor to aligned character
  api.nvim_win_set_cursor(0, { line_nr, target_col - 1 })

  return true, nil
end

---Align multiple lines in visual block mode
---@param start_line integer First line (1-based)
---@param end_line integer Last line (1-based)
---@param col integer Column position (0-based, same for all lines)
---@param target_col integer Target column (1-based)
---@param fill_char string Fill character
---@return boolean success, string|nil error_msg
local function align_block_lines(start_line, end_line, col, target_col, fill_char)
  local lines = api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if not lines or #lines == 0 then
    return false, "Failed to read lines"
  end

  local new_lines = {}
  local modified = 0

  for i, line in ipairs(lines) do
    -- Skip empty lines or lines shorter than selection
    if #line > col then
      local selected_char, char_len = get_char_at_pos(line, col)
      local current_col = col + 1

      if target_col > current_col then
        local fill_length = target_col - current_col
        local before = line:sub(1, col)
        local after = line:sub(col + char_len + 1)
        local fill = string.rep(fill_char, fill_length)

        new_lines[i] = before .. fill .. selected_char .. after
        modified = modified + 1
      else
        new_lines[i] = line
      end
    else
      new_lines[i] = line
    end
  end

  if modified == 0 then
    return false, "No lines were modified (target column must be greater than current)"
  end

  local ok = pcall(api.nvim_buf_set_lines, 0, start_line - 1, end_line, false, new_lines)
  if not ok then
    return false, "Failed to update buffer"
  end

  return true, nil
end

---Align visually selected character(s) to target column
---@param target_col number Target column (1-based)
---@param fill_char string|nil Fill character (default: space)
---@return nil
function M.align_to_column(target_col, fill_char)
  -- Validate and normalize inputs
  if not target_col or type(target_col) ~= "number" or target_col < 1 then
    notify.error("[custom.format.column_align] Target column must be a positive integer")
    return
  end

  fill_char = fill_char or " "
  if type(fill_char) ~= "string" then
    notify.error("[custom.format.column_align] Fill character must be a string")
    return
  end

  -- Handle UTF-8 fill characters
  local fill_width = display_width(fill_char)
  if fill_width ~= 1 then
    notify.error("[custom.format.column_align] Fill character must have display width of 1")
    return
  end

  -- Store state for repeat
  state.last_target_col = target_col
  state.last_fill_char = fill_char

  -- Validate selection (works from normal mode after visual selection)
  local valid, err, selection = validate_selection()
  if not valid or not selection then
    notify.error("[custom.format.column_align] " .. err)
    return
  end

  -- Handle different modes
  local success, align_err
  if selection.mode == "\22" then
    -- Visual block mode: align multiple lines
    success, align_err = align_block_lines(
      selection.start_line,
      selection.end_line,
      selection.start_col,
      target_col,
      fill_char
    )
  else
    -- Visual/line mode: single line
    success, align_err = align_single_line(
      selection.start_line,
      selection.start_col,
      selection.end_col,
      target_col,
      fill_char
    )
  end

  if not success then
    notify.error("[custom.format.column_align] " .. align_err)
    return
  end

  notify.info(string.format("Aligned to column %d with '%s'", target_col, fill_char))
end

---Interactive alignment with prompts
---@return nil
function M.align_interactive()
  -- Prompt for target column
  local target_input = vim.fn.input("Target column: ", state.last_target_col or "")
  if target_input == "" then
    return
  end

  local target_col = tonumber(target_input)
  if not target_col or target_col < 1 then
    notify.error("[custom.format.column_align] Invalid column number")
    return
  end

  -- Prompt for fill character
  local fill_default = state.last_fill_char or " "
  local fill_input = vim.fn.input("Fill character (default: space): ", fill_default)
  local fill_char = (fill_input == "") and " " or fill_input

  M.align_to_column(target_col, fill_char)
end

---Repeat last alignment operation
---@return nil
function M.align_repeat()
  if not state.last_target_col then
    notify.warn("[custom.format.column_align] No previous alignment to repeat")
    return
  end

  M.align_to_column(state.last_target_col, state.last_fill_char)
end

---@type Custom.Format.ColAlign.API
return M
