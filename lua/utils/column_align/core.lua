---@module 'utils.column_align.core'
--- Logic implementation for column alignment.
--- Provides `align_to_column` and `align_interactive`.

---@class column_align_module
---@field align_to_column fun(target_col: number, fill_char: string|nil): nil
---@field align_interactive fun(): nil

local M = {}

local api = vim.api

--- Align visually selected character to target column.
--- Replaces all columns between current position and target with fill_char.
--- Note: this function expects a visual selection of exactly one character on a single line.
---@param target_col number Target column (1-based)
---@param fill_char string|nil Fill character (default: space)
---@return nil
function M.align_to_column(target_col, fill_char)
  fill_char = fill_char or " "

  -- Validate fill_char is a single character (byte-wise)
  if type(fill_char) ~= "string" or #fill_char ~= 1 then
    vim.notify(" [Utils.ColumnAlign] Column align: Fill character must be exactly one character", vim.log.levels.ERROR)
    return
  end

  -- Get visual selection marks (line, col). Marks are 1-based line, 0-based col.
  local start_pos = api.nvim_buf_get_mark(0, "<")
  local end_pos = api.nvim_buf_get_mark(0, ">")

  -- Ensure selection is on a single line
  if start_pos[1] ~= end_pos[1] then
    vim.notify(" [Utils.ColumnAlign] Column align: Selection must be on a single line", vim.log.levels.ERROR)
    return
  end

  local line_nr = start_pos[1]
  local start_col = start_pos[2] + 1  -- Convert to 1-based
  local end_col = end_pos[2] + 1      -- Convert to 1-based

  -- Require exactly one character selected (start_col == end_col)
  if start_col ~= end_col then
    vim.notify(" [Utils.ColumnAlign] Column align: Select exactly one character", vim.log.levels.ERROR)
    return
  end

  -- Get current line text
  local lines = api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)
  local line = lines and lines[1]
  if not line then return end

  -- Fetch the selected character (works for byte-indexed strings)
  local selected_char = line:sub(start_col, start_col)

  -- Validate target column strictly greater than current position
  if type(target_col) ~= "number" or target_col <= start_col then
    vim.notify(" [Utils.ColumnAlign] Column align: Target column must be greater than current position", vim.log.levels.ERROR)
    return
  end

  -- Calculate fill length (number of fill_char to insert between before and selected_char)
  local fill_length = target_col - start_col
  if fill_length < 1 then
    vim.notify(" [Utils.ColumnAlign] Column align: Computed fill length invalid", vim.log.levels.ERROR)
    return
  end

  local before = line:sub(1, start_col - 1)
  local after = line:sub(start_col + 1)

  -- Build fill (may produce long string; acceptable for typical editor use)
  local fill = string.rep(fill_char, fill_length)

  -- Construct new line with selected_char moved to target_col
  local new_line = before .. fill .. selected_char .. after

  -- Set modified line and update cursor to the aligned character
  api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, { new_line })
  api.nvim_win_set_cursor(0, { line_nr, target_col - 1 })
end

--- Interactive alignment: prompt for column and fill character.
---@return nil
function M.align_interactive()
  -- Prompt for target column (string -> number)
  local target_input = vim.fn.input("Target column: ")
  if target_input == "" then return end

  local target_col = tonumber(target_input)
  if not target_col or target_col < 1 then
    vim.notify(" [Utils.ColumnAlign] Column align: Invalid column number", vim.log.levels.ERROR)
    return
  end

  -- Prompt for fill character (default: space)
  local fill_input = vim.fn.input("Fill character (default: space): ")
  local fill_char = (fill_input == "") and " " or fill_input

  M.align_to_column(target_col, fill_char)
end

return M
