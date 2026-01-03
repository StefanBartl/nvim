---@module 'usrcmds.format_table'
---@brief Markdown table formatter with alignment control
---@description
--- This module provides a user command `:FormatTable` to format Markdown tables
--- with configurable header and entry alignment (left, center, right).
---
--- Key features:
--- • Preserves table structure while normalizing column widths
--- • Supports both compact (|-----|) and spaced (| ----- |) separator styles
--- • Configurable alignment per column or global defaults
--- • Handles UTF-8 characters correctly via vim.str_utfindex
--- • Type-safe with full error handling
---
--- Usage:
---   :FormatTable              " Format with default centering
---   :FormatTable center left  " Center headers, left-align entries
---   :FormatTable left center  " Left headers, center entries
---   :FormatTable right right  " Right-align both

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

  -- vim.str_utfindex gives byte->char index, we need display width
  -- For simple cases, use vim.fn.strdisplaywidth
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
---@param align UsrCmds.FmtTbl.Alignment Alignment mode
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

  -- Must contain at least one dash
  if not trimmed:match("%-") then
    return false, nil
  end

  -- Must start and end with |
  if not trimmed:match("^|.*|$") then
    return false, nil
  end

  -- Extract content between outer pipes
  local content = trimmed:match("^|(.+)|$")
  if not content then
    return false, nil
  end

  -- Check if content only contains: dashes, colons, pipes, and whitespace
  -- Valid separators: |---|, | --- |, |:---|, |---:|, |:---:|
  if not content:match("^[%-%s:|]+$") then
    return false, nil
  end

  -- Check style: has spaces around dashes?
  local has_spaces = content:match("%s%-") or content:match("%-%s")
  return true, has_spaces and "spaced" or "compact"
end

---Parse single table row into cells
---@param line string Table row
---@return string[] cells
local function parse_row(line)
  local cells = {}
  local trimmed = trim(line)

  -- Remove leading | and trailing |
  local content = trimmed:match("^%s*|%s*(.-)%s*|%s*$")
  if not content then
    return cells
  end

  -- Split by | character
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

  -- Add final cell
  cells[#cells + 1] = trim(current)

  return cells
end

---Find and parse table at cursor position
---@param bufnr integer Buffer number
---@param cursor_line integer Cursor line (1-indexed)
---@return UsrCmds.FmtTbl.ParsedTable|nil table, string|nil error
local function parse_table_at_cursor(bufnr, cursor_line)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, "Invalid buffer"
  end

  local ok, lines = safe_call(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
  if not ok or type(lines) ~= "table" then
    return nil, "Failed to read buffer lines"
  end

  -- Find table boundaries
  local start_line = cursor_line
  local end_line = cursor_line

  -- Scan upward for table start
  while start_line > 1 do
    if not is_table_line(lines[start_line - 1]) then
      break
    end
    start_line = start_line - 1
  end

  -- Scan downward for table end
  while end_line < #lines do
    if not is_table_line(lines[end_line + 1]) then
      break
    end
    end_line = end_line + 1
  end

  -- Validate minimum table structure (header + separator + at least 1 row)
  if end_line - start_line < 2 then
    return nil, "Not a valid table (need at least header + separator + 1 row)"
  end

  -- Parse rows and find separator
  local rows = {}
  local separator_style = nil
  local separator_line_idx = nil
  local col_count = 0

  for i = start_line, end_line do
    local line = lines[i]
    local is_sep, style = is_separator_line(line)

    if is_sep then
      -- Found separator, should be line 2 (after header)
      if separator_line_idx == nil then
        separator_line_idx = i
        separator_style = style
      end
    else
      local cells = parse_row(line)
      rows[#rows + 1] = cells

      -- First row (header) determines column count
      if #rows == 1 then
        col_count = #cells
      end
    end
  end

  -- Validate structure
  if #rows < 2 then
    return nil, "Table must have at least header and one data row"
  end

  if not separator_line_idx then
    return nil, "No separator line found (must be second line with |---|)"
  end

  if separator_line_idx ~= start_line + 1 then
    return nil, "Separator must be on line 2 (directly after header)"
  end

  -- Normalize all rows to have same column count
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
    -- Spaced style: | ----- | ----- |
    for _, width in ipairs(widths) do
      local dashes = string.rep("-", width)
      parts[#parts + 1] = " " .. dashes .. " "
    end
    return "|" .. table.concat(parts, "|") .. "|"
  else
    -- Compact style: |-------|-------|
    -- Add 2 to width to account for spaces in formatted rows: | content |
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
---@param align UsrCmds.FmtTbl.Alignment UsrCmds.FmtTbl.Alignment mode
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
---@param parsed UsrCmds.FmtTbl.ParsedTable Parsed table data
---@param header_align UsrCmds.FmtTbl.Alignment Header alignment
---@param entry_align UsrCmds.FmtTbl.Alignment Entry alignment
---@return string[] formatted_lines
local function format_table(parsed, header_align, entry_align)
  local widths = calculate_column_widths(parsed.rows, parsed.col_count)
  local formatted = {}

  -- Format header (first row)
  formatted[1] = format_row(parsed.rows[1], widths, header_align)

  -- Generate separator
  formatted[2] = generate_separator(widths, parsed.separator_style)

  -- Format data rows
  for i = 2, #parsed.rows do
    formatted[#formatted + 1] = format_row(parsed.rows[i], widths, entry_align)
  end

  return formatted
end

-- ============================================================================
-- Command Implementation
-- ============================================================================

---Validate alignment argument
---@param arg string User input
---@return UsrCmds.FmtTbl.Alignment|nil alignment, string|nil error
local function validate_alignment(arg)
  if type(arg) ~= "string" then
    return nil, "Alignment must be a string"
  end

  local lower = arg:lower()
  if lower == "left" or lower == "center" or lower == "right" then
    return lower, nil
  end

  return nil, "Invalid alignment: " .. arg .. " (use left, center, or right)"
end

---Main command handler
---@param args table Command arguments from nvim_create_user_command
local function format_table_command(args)
  -- Parse arguments
  local header_align = config.header_align
  local entry_align = config.entry_align

  if #args.fargs > 0 then
    local align, err = validate_alignment(args.fargs[1])
    if not align then
      vim.notify("FormatTable: " .. err, vim.log.levels.ERROR)
      return
    end
    header_align = align
  end

  if #args.fargs > 1 then
    local align, err = validate_alignment(args.fargs[2])
    if not align then
      vim.notify("FormatTable: " .. err, vim.log.levels.ERROR)
      return
    end
    entry_align = align
  end

  -- Get current buffer and cursor
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("FormatTable: Invalid buffer", vim.log.levels.ERROR)
    return
  end

  local ok, cursor = safe_call(vim.api.nvim_win_get_cursor, 0)
  if not ok or type(cursor) ~= "table" then
    vim.notify("FormatTable: Failed to get cursor position", vim.log.levels.ERROR)
    return
  end

  local cursor_line = cursor[1]

  -- Parse table
  local parsed, parse_err = parse_table_at_cursor(bufnr, cursor_line)
  if not parsed then
    vim.notify("FormatTable: " .. (parse_err or "Unknown error"), vim.log.levels.WARN)
    return
  end

  -- Format table
  local ok_format, formatted = safe_call(format_table, parsed, header_align, entry_align)
  if not ok_format or type(formatted) ~= "table" then
    vim.notify("FormatTable: Failed to format table", vim.log.levels.ERROR)
    return
  end

  -- Replace lines
  ok, _ = safe_call(
    vim.api.nvim_buf_set_lines,
    bufnr,
    parsed.start_line - 1,
    parsed.end_line,
    false,
    formatted
  )

  if not ok then
    vim.notify("FormatTable: Failed to update buffer", vim.log.levels.ERROR)
    return
  end

  vim.notify("Table formatted successfully", vim.log.levels.INFO)
end

-- ============================================================================
-- Public API
-- ============================================================================

---Setup the module and register command
---@param opts UsrCmds.FmtTbl.Cfg|nil Optional configuration
function M.setup(opts)
  if opts and type(opts) == "table" then
    if opts.header_align then
      local align, err = validate_alignment(opts.header_align)
      if align then
        config.header_align = align
      else
        vim.notify("FormatTable setup: " .. err, vim.log.levels.WARN)
      end
    end

    if opts.entry_align then
      local align, err = validate_alignment(opts.entry_align)
      if align then
        config.entry_align = align
      else
        vim.notify("FormatTable setup: " .. err, vim.log.levels.WARN)
      end
    end
  end

  -- Register user command
  vim.api.nvim_create_user_command("FormatTable", format_table_command, {
    nargs = "*",
    desc = "Format Markdown table with alignment (header_align entry_align)",
    complete = function()
      return { "left", "center", "right" }
    end,
  })
end

return M
