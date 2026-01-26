---@module 'custom.format.table'
---@brief Markdown table formatter with alignment control
---@description
--- This module provides table formatting functionality with configurable alignment.
--- Can be used directly via API or through :Format table command.

local M = {}

-- Module state
local config = {
  header_align = "center",
  entry_align = "center",
}

-- ============================================================================
-- Utilities
-- ============================================================================

---Safe wrapper for API calls
---@param fn function Function to call safely
---@param ... any Arguments to pass
---@return boolean success, any result_or_error
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  return ok, result
end

---Calculate display width of string accounting for UTF-8
---@param str string Input string
---@return integer width Display width
local function display_width(str)
  if type(str) ~= "string" then
    return 0
  end

  local ok, width = safe_call(vim.fn.strdisplaywidth, str)
  return ok and width or #str
end

---Trim whitespace from both ends
---@param str string Input string
---@return string trimmed
local function trim(str)
  if type(str) ~= "string" then
    return ""
  end
  return str:match("^%s*(.-)%s*$") or ""
end

---Pad string to target width with alignment
---@param str string Content to pad
---@param width integer Target display width
---@param align Custom.Fmt.FmtTbl.Alignment Alignment mode
---@return string padded
local function pad_cell(str, width, align)
  local content = trim(str)
  local current_width = display_width(content)

  if current_width >= width then
    return content
  end

  local padding = width - current_width

  if align == "left" then
    return content .. string.rep(" ", padding)
  elseif align == "right" then
    return string.rep(" ", padding) .. content
  else -- center
    local left_pad = math.floor(padding / 2)
    local right_pad = padding - left_pad
    return string.rep(" ", left_pad) .. content .. string.rep(" ", right_pad)
  end
end

-- ============================================================================
-- Table Parsing
-- ============================================================================

---Check if line is a table row
---@param line string Line to check
---@return boolean is_table_row
local function is_table_line(line)
  if type(line) ~= "string" then
    return false
  end
  local trimmed = trim(line)
  return trimmed:match("^%s*|.*|%s*$") ~= nil
end

---Check if line is separator row
---@param line string Line to check
---@return boolean is_separator, "compact"|"spaced"|nil style
local function is_separator_line(line)
  if type(line) ~= "string" then
    return false, nil
  end

  local trimmed = trim(line)

  if not trimmed:match("%-") then
    return false, nil
  end

  if not trimmed:match("^|.*|$") then
    return false, nil
  end

  local content = trimmed:match("^|(.+)|$")
  if not content then
    return false, nil
  end

  if not content:match("^[%-%s:|]+$") then
    return false, nil
  end

  local has_spaces = content:match("%s%-") or content:match("%-%s")
  return true, has_spaces and "spaced" or "compact"
end

---Parse single table row into cells
---@param line string Table row
---@return string[] cells
local function parse_row(line)
  local cells = {}
  local trimmed = trim(line)

  local content = trimmed:match("^%s*|%s*(.-)%s*|%s*$")
  if not content then
    return cells
  end

  local current = ""
  for i = 1, #content do
    local char = content:sub(i, i)
    if char == "|" then
      cells[#cells + 1] = trim(current)
      current = ""
    else
      current = current .. char
    end
  end

  cells[#cells + 1] = trim(current)

  return cells
end

---Find and parse table at cursor position
---@param bufnr integer Buffer number
---@param cursor_line integer Cursor line (1-indexed)
---@return Custom.Fmt.FmtTbl.ParsedTable|nil table, string|nil error
local function parse_table_at_cursor(bufnr, cursor_line)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, "Invalid buffer"
  end

  local ok, lines = safe_call(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
  if not ok or type(lines) ~= "table" then
    return nil, "Failed to read buffer lines"
  end

  local start_line = cursor_line
  local end_line = cursor_line

  while start_line > 1 do
    if not is_table_line(lines[start_line - 1]) then
      break
    end
    start_line = start_line - 1
  end

  while end_line < #lines do
    if not is_table_line(lines[end_line + 1]) then
      break
    end
    end_line = end_line + 1
  end

  if end_line - start_line < 2 then
    return nil, "Not a valid table (need at least header + separator + 1 row)"
  end

  local rows = {}
  local separator_style = nil
  local separator_line_idx = nil
  local col_count = 0

  for i = start_line, end_line do
    local line = lines[i]
    local is_sep, style = is_separator_line(line)

    if is_sep then
      if separator_line_idx == nil then
        separator_line_idx = i
        separator_style = style
      end
    else
      local cells = parse_row(line)
      rows[#rows + 1] = cells

      if #rows == 1 then
        col_count = #cells
      end
    end
  end

  if #rows < 2 then
    return nil, "Table must have at least header and one data row"
  end

  if not separator_line_idx then
    return nil, "No separator line found (must be second line with |---|)"
  end

  if separator_line_idx ~= start_line + 1 then
    return nil, "Separator must be on line 2 (directly after header)"
  end

  for _, row in ipairs(rows) do
    while #row < col_count do
      row[#row + 1] = ""
    end
  end

  return {
    start_line = start_line,
    end_line = end_line,
    rows = rows,
    separator_style = separator_style or "compact",
    col_count = col_count,
  }, nil
end

-- ============================================================================
-- Table Formatting
-- ============================================================================

---Calculate column widths from all rows
---@param rows string[][] All table rows
---@param col_count integer Number of columns
---@return integer[] widths
local function calculate_column_widths(rows, col_count)
  local widths = {}
  for i = 1, col_count do
    widths[i] = 0
  end

  for _, row in ipairs(rows) do
    for col_idx, cell in ipairs(row) do
      if col_idx <= col_count then
        widths[col_idx] = math.max(widths[col_idx], display_width(cell))
      end
    end
  end

  return widths
end

---Generate separator line
---@param widths integer[] Column widths
---@param style "compact"|"spaced" Separator style
---@return string separator
local function generate_separator(widths, style)
  local parts = {}

  if style == "spaced" then
    for _, width in ipairs(widths) do
      local dashes = string.rep("-", width)
      parts[#parts + 1] = " " .. dashes .. " "
    end
    return "|" .. table.concat(parts, "|") .. "|"
  else
    for _, width in ipairs(widths) do
      local dashes = string.rep("-", width + 2)
      parts[#parts + 1] = dashes
    end
    return "|" .. table.concat(parts, "|") .. "|"
  end
end

---Format single row with alignment
---@param cells string[] Cell contents
---@param widths integer[] Column widths
---@param align Custom.Fmt.FmtTbl.Alignment Alignment mode
---@return string formatted_row
local function format_row(cells, widths, align)
  local formatted = {}

  for col_idx, width in ipairs(widths) do
    local cell = cells[col_idx] or ""
    formatted[#formatted + 1] = pad_cell(cell, width, align)
  end

  return "| " .. table.concat(formatted, " | ") .. " |"
end

---Format entire table
---@param parsed Custom.Fmt.FmtTbl.ParsedTable Parsed table data
---@param header_align Custom.Fmt.FmtTbl.Alignment Header alignment
---@param entry_align Custom.Fmt.FmtTbl.Alignment Entry alignment
---@return string[] formatted_lines
local function format_table(parsed, header_align, entry_align)
  local widths = calculate_column_widths(parsed.rows, parsed.col_count)
  local formatted = {}

  formatted[1] = format_row(parsed.rows[1], widths, header_align)
  formatted[2] = generate_separator(widths, parsed.separator_style)

  for i = 2, #parsed.rows do
    formatted[#formatted + 1] = format_row(parsed.rows[i], widths, entry_align)
  end

  return formatted
end

-- ============================================================================
-- Public API
-- ============================================================================

---Format table at cursor position
---@param bufnr integer Buffer number
---@param header_align Custom.Fmt.FmtTbl.Alignment|nil Header alignment (default: config)
---@param entry_align Custom.Fmt.FmtTbl.Alignment|nil Entry alignment (default: config)
---@return boolean success, string|nil error_message
function M.format_table_at_cursor(bufnr, header_align, entry_align)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  header_align = header_align or config.header_align
  entry_align = entry_align or config.entry_align

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, "Invalid buffer"
  end

  local ok, cursor = safe_call(vim.api.nvim_win_get_cursor, 0)
  if not ok or type(cursor) ~= "table" then
    return false, "Failed to get cursor position"
  end

  local cursor_line = cursor[1]

  local parsed, parse_err = parse_table_at_cursor(bufnr, cursor_line)
  if not parsed then
    return false, parse_err or "Unknown error"
  end

  local ok_format, formatted = safe_call(format_table, parsed, header_align, entry_align)
  if not ok_format or type(formatted) ~= "table" then
    return false, "Failed to format table"
  end

  ok, _ = safe_call(
    vim.api.nvim_buf_set_lines,
    bufnr,
    parsed.start_line - 1,
    parsed.end_line,
    false,
    formatted
  )

  if not ok then
    return false, "Failed to update buffer"
  end

  return true, nil
end

return M
