---@module 'custom.markdown.tableview.parser'
---@description Parses Markdown pipe-tables into structured Lua tables suitable for rendering.
--- The parser returns a `MarkdownTable` structure:
--- {
---   header = { cells = { { content = "H1" }, { content = "H2" } } },
---   alignments = { "left", "center", "right" },
---   rows = { { cells = {...} }, { cells = {...} } },
---   start_line = <1-based line>,
---   end_line = <1-based line>
--- }

local M = {}

--- Trim whitespace helper
---@param s string?
---@return string
local function trim(s)
  if not s then
    return ""
  end
  return s:match("^%s*(.-)%s*$")
end

--- Parse alignment token from a separator cell like ":---:", "---:", ":---"
---@param token string?
---@return string "left"|"center"|"right"
local function parse_alignment(token)
  if not token then
    return "left"
  end
  token = trim(token)
  if token:match("^:%-+:$") then
    return "center"
  elseif token:match("^:%-+$") then
    return "left"
  elseif token:match("^-+:$") then
    return "right"
  else
    return "left"
  end
end

--- Parse a single pipe-separated row into cell objects.
--- Accepts lines with or without leading/trailing pipes.
---@param line string
---@return MarkdownTableCell[]
local function parse_row(line)
  local cells = {}
  -- Remove leading/trailing pipe if present, but allow rows without outer pipes
  line = line:gsub("^%s*|", ""):gsub("|%s*$", "")
  -- Split on top-level pipes
  for cell in line:gmatch("([^|]+)") do
    table.insert(cells, { content = trim(cell) })
  end
  return cells
end

--- Heuristic: detect whether a line is a separator row (alignment row).
--- We allow pipes, hyphens, colons and whitespace.
---@param line string
---@return boolean
local function is_separator_row(line)
  if not line then
    return false
  end
  -- Remove leading/trailing whitespace for check
  local s = trim(line)
  -- Must contain at least one '-' and may contain ':' and '|' and whitespace
  if not s:match("-") then
    return false
  end
  -- Keep it permissive but avoid matching other content: only these chars allowed
  return s:match("^|?%s*[:%-|%s]+%s*|?$") ~= nil
end

--- Parse a sequence of contiguous lines that represent a table.
--- `lines` is an array of strings starting at the header line.
--- `start_line` is the 1-based buffer line number corresponding to lines[1].
---@param lines string[]
---@param start_line integer
---@return MarkdownTable|nil
function M.parse_table(lines, start_line)
  if not lines or #lines < 2 then
    return nil
  end

  local header_line = lines[1]
  local sep_line = lines[2]

  if not is_separator_row(sep_line) then
    return nil
  end

  local tbl = {
    header = nil,
    alignments = {},
    rows = {},
    start_line = start_line,
    end_line = start_line,
  }

  -- parse header
  local header_cells = parse_row(header_line)
  tbl.header = { cells = header_cells }

  -- parse alignment tokens from sep line
  local align_cells = parse_row(sep_line)
  for i, ac in ipairs(align_cells) do
    -- ac is a table { content = ":-:" } if produced by parse_row,
    -- but parse_row produces plain strings wrapped in content when called here.
    local token = ac.content or ac
    tbl.alignments[i] = parse_alignment(token)
  end

  -- parse data rows (lines starting with pipe or that appear consistent)
  for idx = 3, #lines do
    local l = lines[idx]
    if not l then
      break
    end
    -- Accept rows that look like table rows: contain at least one pipe or non-empty after trimming
    if l:match("|") then
      local row_cells = parse_row(l)
      table.insert(tbl.rows, { cells = row_cells })
      tbl.end_line = start_line + idx - 1
    else
      break
    end
  end

  return tbl
end

--- Scan a buffer for all pipe-style Markdown tables.
--- Returns a list of MarkdownTable structures.
---@param bufnr integer|nil
---@return MarkdownTable[] tables
function M.get_tables(bufnr)
  bufnr = bufnr or 0
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
  if not ok or not lines then
    return {}
  end

  local tables = {}
  local i = 1
  while i <= #lines do
    local line = lines[i]
    -- Quick check: line contains a pipe character and next line exists and is a separator
    if line and line:match("|") and (i + 1) <= #lines and is_separator_row(lines[i + 1]) then
      local tbl_lines = { lines[i], lines[i + 1] }
      local j = i + 2
      while j <= #lines and lines[j] and lines[j]:match("|") do
        table.insert(tbl_lines, lines[j])
        j = j + 1
      end
      local parsed = M.parse_table(tbl_lines, i)
      if parsed then
        table.insert(tables, parsed)
        i = parsed.end_line + 1
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end

  return tables
end

return M
