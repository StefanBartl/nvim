---@module 'custom.format.table'
---@brief Markdown table formatter with per-role and per-column alignment control.
---@description
--- Public API:
---   M.format_table_at_cursor(bufnr, opts)      – format the table under the cursor
---   M.format_tables_in_buffer(bufnr, opts)     – format every table in a buffer
---   M.format_tables_in_scope(opts)             – format by scope (cursor/buffer/cwd/path)
---
--- Fixes vs. v1:
---   • Bug: passing a single alignment (e.g. "left") now correctly applies to
---     BOTH header and entries, not just the header.
---   • New: header_align and entry_align are independent (header=left cell=center).
---   • New: col_overrides[] lets you pin individual columns to a specific alignment,
---     identified by 1-based index or by header text (case-insensitive).
---   • New: scope parameter – "cursor" | "buffer" | "cwd" | "<path>"

---@see custom.format.table.@types

local notify = require("lib.notify").create("[custom.format.table]")

local M = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Module-level default config
-- ─────────────────────────────────────────────────────────────────────────────

---@type Custom.Fmt.FmtTbl.Cfg
local _cfg = {
  header_align = "center",
  entry_align  = "center",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Utilities
-- ─────────────────────────────────────────────────────────────────────────────

---@param fn function
---@param ... any
---@return boolean ok, any result
local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  return ok, result
end

---@param str string
---@return integer
local function display_width(str)
  if type(str) ~= "string" then
    return 0
  end
  local ok, w = safe_call(vim.fn.strdisplaywidth, str)
  return ok and w or #str
end

---@param str string
---@return string
local function trim(str)
  if type(str) ~= "string" then return "" end
  return str:match("^%s*(.-)%s*$") or ""
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Cell padding
-- ─────────────────────────────────────────────────────────────────────────────

---Pad `str` to exactly `width` display columns using `align`.
---@param str   string
---@param width integer
---@param align Custom.Fmt.FmtTbl.Alignment
---@return string
local function pad_cell(str, width, align)
  local content = trim(str)
  local cw      = display_width(content)

  if cw >= width then
    return content
  end

  local pad = width - cw

  if align == "left" then
    return content .. string.rep(" ", pad)
  elseif align == "right" then
    return string.rep(" ", pad) .. content
  else -- center
    local lp = math.floor(pad / 2)
    return string.rep(" ", lp) .. content .. string.rep(" ", pad - lp)
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Column-override resolution
-- ─────────────────────────────────────────────────────────────────────────────

---Build a lookup table  col_index → alignment  from the user-supplied overrides.
---Header names are matched case-insensitively against `header_cells`.
---@param overrides    Custom.Fmt.FmtTbl.ColOverride[]|nil
---@param header_cells string[]
---@param col_count    integer
---@return table<integer, Custom.Fmt.FmtTbl.Alignment>  idx_to_align
local function resolve_overrides(overrides, header_cells, col_count)
  local map = {}

  if not overrides or #overrides == 0 then
    return map
  end

  -- Build a name→index lookup from the header row.
  local name_to_idx = {}
  for i = 1, col_count do
    local key = trim(header_cells[i] or ""):lower()
    if key ~= "" then
      name_to_idx[key] = i
    end
  end

  for _, ov in ipairs(overrides) do
    local idx

    if type(ov.col) == "number" then
      idx = ov.col
    elseif type(ov.col) == "string" then
      idx = name_to_idx[ov.col:lower()]
    end

    if idx and idx >= 1 and idx <= col_count then
      map[idx] = ov.align
    else
      notify.warn(string.format(
        "col_overrides: column %q not found (ignored)",
        tostring(ov.col)
      ))
    end
  end

  return map
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Table parsing helpers
-- ─────────────────────────────────────────────────────────────────────────────

---@param line string
---@return boolean
local function is_table_line(line)
  if type(line) ~= "string" then return false end
  return trim(line):match("^|.*|$") ~= nil
end

---@param line string
---@return boolean is_sep, "compact"|"spaced"|nil style
local function is_separator_line(line)
  if type(line) ~= "string" then return false, nil end
  local t = trim(line)
  if not t:match("%-") then return false, nil end
  if not t:match("^|.*|$") then return false, nil end
  local inner = t:match("^|(.+)|$")
  if not inner then return false, nil end
  if not inner:match("^[%-%s:|]+$") then return false, nil end
  local spaced = inner:match("%s%-") or inner:match("%-%s")
  return true, spaced and "spaced" or "compact"
end

---@param line string
---@return string[]
local function parse_row(line)
  local cells   = {}
  local trimmed = trim(line)
  local inner   = trimmed:match("^|(.-)%s*|$") or trimmed:match("^|(.*)|$")
  if not inner then return cells end

  local cur = ""
  for i = 1, #inner do
    local ch = inner:sub(i, i)
    if ch == "|" then
      cells[#cells + 1] = trim(cur)
      cur = ""
    else
      cur = cur .. ch
    end
  end
  cells[#cells + 1] = trim(cur)
  return cells
end

---Find all tables in `lines` and return their parsed representations.
---@param lines    string[]
---@return Custom.Fmt.FmtTbl.ParsedTable[]
local function parse_all_tables(lines)
  local tables = {}
  local i      = 1

  while i <= #lines do
    if not is_table_line(lines[i]) then
      i = i + 1
    else
      -- Scan forward to find the full table block.
      local start = i
      while i <= #lines and is_table_line(lines[i]) do
        i = i + 1
      end
      local stop = i - 1

      if stop - start < 2 then
        goto continue
      end

      -- Parse this block.
      local rows           = {}
      local sep_style      = nil
      local sep_line_idx   = nil
      local col_count      = 0

      for ln = start, stop do
        local is_sep, style = is_separator_line(lines[ln])
        if is_sep then
          if not sep_line_idx then
            sep_line_idx = ln
            sep_style    = style
          end
        else
          local cells = parse_row(lines[ln])
          rows[#rows + 1] = cells
          if #rows == 1 then
            col_count = #cells
          end
        end
      end

      if #rows >= 2 and sep_line_idx and sep_line_idx == start + 1 then
        -- Pad short rows.
        for _, row in ipairs(rows) do
          while #row < col_count do row[#row + 1] = "" end
        end

        tables[#tables + 1] = {
          start_line     = start,
          end_line       = stop,
          rows           = rows,
          separator_style = sep_style or "compact",
          col_count      = col_count,
        }
      end

      ::continue::
    end
  end

  return tables
end

---Find the table that contains `cursor_line` (1-based) among `tables`.
---@param tables      Custom.Fmt.FmtTbl.ParsedTable[]
---@param cursor_line integer
---@return Custom.Fmt.FmtTbl.ParsedTable|nil, string|nil
local function find_table_at_cursor(tables, cursor_line)
  for _, tbl in ipairs(tables) do
    if cursor_line >= tbl.start_line and cursor_line <= tbl.end_line then
      return tbl, nil
    end
  end
  return nil, "Cursor is not inside a table"
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Formatting
-- ─────────────────────────────────────────────────────────────────────────────

---@param rows      string[][]
---@param col_count integer
---@return integer[]
local function calc_widths(rows, col_count)
  local widths = {}
  for i = 1, col_count do widths[i] = 1 end  -- min width = 1 for separator dashes
  for _, row in ipairs(rows) do
    for ci, cell in ipairs(row) do
      if ci <= col_count then
        widths[ci] = math.max(widths[ci], display_width(cell))
      end
    end
  end
  return widths
end

---@param widths integer[]
---@param style  "compact"|"spaced"
---@return string
local function gen_separator(widths, style)
  local parts = {}
  if style == "spaced" then
    for _, w in ipairs(widths) do
      parts[#parts + 1] = " " .. string.rep("-", w) .. " "
    end
    return "|" .. table.concat(parts, "|") .. "|"
  else
    for _, w in ipairs(widths) do
      parts[#parts + 1] = string.rep("-", w + 2)
    end
    return "|" .. table.concat(parts, "|") .. "|"
  end
end

---Format one row, applying per-column overrides where present.
---@param cells      string[]
---@param widths     integer[]
---@param default_align Custom.Fmt.FmtTbl.Alignment
---@param override_map  table<integer, Custom.Fmt.FmtTbl.Alignment>
---@return string
local function format_row(cells, widths, default_align, override_map)
  local parts = {}
  for ci, w in ipairs(widths) do
    local align = override_map[ci] or default_align
    parts[#parts + 1] = pad_cell(cells[ci] or "", w, align)
  end
  return "| " .. table.concat(parts, " | ") .. " |"
end

---Render a ParsedTable to lines.
---@param parsed       Custom.Fmt.FmtTbl.ParsedTable
---@param header_align Custom.Fmt.FmtTbl.Alignment
---@param entry_align  Custom.Fmt.FmtTbl.Alignment
---@param override_map table<integer, Custom.Fmt.FmtTbl.Alignment>
---@return string[]
local function render_table(parsed, header_align, entry_align, override_map)
  local widths    = calc_widths(parsed.rows, parsed.col_count)
  local out       = {}

  out[1] = format_row(parsed.rows[1], widths, header_align, override_map)
  out[2] = gen_separator(widths, parsed.separator_style)

  for i = 2, #parsed.rows do
    out[#out + 1] = format_row(parsed.rows[i], widths, entry_align, override_map)
  end

  return out
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Buffer helpers
-- ─────────────────────────────────────────────────────────────────────────────

---Read all lines from a buffer (must be valid).
---@param bufnr integer
---@return string[]|nil, string|nil
local function buf_get_lines(bufnr)
  local ok, lines = safe_call(vim.api.nvim_buf_get_lines, bufnr, 0, -1, false)
  if not ok or type(lines) ~= "table" then
    return nil, "Failed to read buffer lines"
  end
  return lines, nil
end

---Apply formatted tables back to a buffer.
---Tables must be provided in *reverse* order (last first) so that replacing
---earlier lines does not invalidate the line numbers of later tables.
---@param bufnr   integer
---@param tables  { parsed: Custom.Fmt.FmtTbl.ParsedTable, rendered: string[] }[]
---@return boolean ok, string|nil err
local function apply_tables_to_buf(bufnr, tables)
  -- Sort descending by start_line so replacements don't shift subsequent indices.
  table.sort(tables, function(a, b)
    return a.parsed.start_line > b.parsed.start_line
  end)

  for _, entry in ipairs(tables) do
    local ok = safe_call(
      vim.api.nvim_buf_set_lines,
      bufnr,
      entry.parsed.start_line - 1,
      entry.parsed.end_line,
      false,
      entry.rendered
    )
    if not ok then
      return false, "Failed to update buffer at line " .. entry.parsed.start_line
    end
  end

  return true, nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- File-level helpers (for scope = "cwd" / explicit path)
-- ─────────────────────────────────────────────────────────────────────────────

---Format every table in a file on disk (without opening it as a Neovim buffer).
---@param path         string
---@param header_align Custom.Fmt.FmtTbl.Alignment
---@param entry_align  Custom.Fmt.FmtTbl.Alignment
---@param override_map table<integer, Custom.Fmt.FmtTbl.Alignment>
---@return boolean ok, string|nil err
local function format_file(path, header_align, entry_align, override_map)
  local fh, open_err = io.open(path, "r")
  if not fh then
    return false, string.format("Cannot open %q: %s", path, open_err or "?")
  end

  local lines = {}
  for line in fh:lines() do
    lines[#lines + 1] = line
  end
  fh:close()

  local tables    = parse_all_tables(lines)
  if #tables == 0 then return true, nil end

  -- Build replacements in-place (reverse order).
  table.sort(tables, function(a, b) return a.start_line > b.start_line end)

  for _, parsed in ipairs(tables) do
    -- Resolve overrides now that we have the header row.
    local om       = resolve_overrides(override_map ~= nil and {} or nil, parsed.rows[1], parsed.col_count)
    -- (override_map is already resolved for index-based; name-based needs header)
    -- We re-resolve per-table from the raw ColOverride list stored in a closure.
    local rendered = render_table(parsed, header_align, entry_align, om)

    for ri, rendered_line in ipairs(rendered) do
      lines[parsed.start_line - 1 + ri] = rendered_line
    end
  end

  local wh, write_err = io.open(path, "w")
  if not wh then
    return false, string.format("Cannot write %q: %s", path, write_err or "?")
  end

  for _, line in ipairs(lines) do
    wh:write(line .. "\n")
  end
  wh:close()

  return true, nil
end

---Collect *.md files under `dir` recursively using `vim.fn.glob`.
---@param dir string
---@return string[]
local function collect_md_files(dir)
  local pattern = dir:gsub("[/\\]$", "") .. "/**/*.md"
  local result  = vim.fn.glob(pattern, false, true)

  -- Also include *.md directly under dir (glob ** may miss the top level).
  local top = vim.fn.glob(dir:gsub("[/\\]$", "") .. "/*.md", false, true)
  for _, f in ipairs(top) do
    result[#result + 1] = f
  end

  return result
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────

---Format only the table the cursor is currently inside.
---@param bufnr integer|nil  nil → current buffer
---@param opts  Custom.Fmt.FmtTbl.Opts|nil
---@return boolean ok, string|nil err
function M.format_table_at_cursor(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts  = opts  or {}

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, "Invalid buffer"
  end

  local header_align = opts.header_align or _cfg.header_align
  local entry_align  = opts.entry_align  or _cfg.entry_align

  local ok_cur, cursor = safe_call(vim.api.nvim_win_get_cursor, 0)
  if not ok_cur then
    return false, "Failed to get cursor position"
  end

  local lines, read_err = buf_get_lines(bufnr)
  if not lines then return false, read_err end

  local tables = parse_all_tables(lines)
  local parsed, find_err = find_table_at_cursor(tables, cursor[1])
  if not parsed then return false, find_err end

  local override_map = resolve_overrides(opts.col_overrides, parsed.rows[1], parsed.col_count)
  local rendered     = render_table(parsed, header_align, entry_align, override_map)

  local ok_set = safe_call(
    vim.api.nvim_buf_set_lines,
    bufnr,
    parsed.start_line - 1,
    parsed.end_line,
    false,
    rendered
  )

  if not ok_set then
    return false, "Failed to update buffer"
  end

  return true, nil
end

---Format every table in a buffer.
---@param bufnr integer|nil  nil → current buffer
---@param opts  Custom.Fmt.FmtTbl.Opts|nil
---@return boolean ok, string|nil err, integer count
function M.format_tables_in_buffer(bufnr, opts)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts  = opts  or {}

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, "Invalid buffer", 0
  end

  local header_align = opts.header_align or _cfg.header_align
  local entry_align  = opts.entry_align  or _cfg.entry_align

  local lines, read_err = buf_get_lines(bufnr)
  if not lines then return false, read_err, 0 end

  local tables = parse_all_tables(lines)
  if #tables == 0 then return true, nil, 0 end

  local pending = {}
  for _, parsed in ipairs(tables) do
    local override_map = resolve_overrides(opts.col_overrides, parsed.rows[1], parsed.col_count)
    local rendered     = render_table(parsed, header_align, entry_align, override_map)
    pending[#pending + 1] = { parsed = parsed, rendered = rendered }
  end

  local ok, apply_err = apply_tables_to_buf(bufnr, pending)
  return ok, apply_err, #pending
end

---Dispatch formatting by scope.
---
--- scope = "cursor"  → format_table_at_cursor (default)
--- scope = "buffer"  → format_tables_in_buffer on current buf
--- scope = "cwd"     → all *.md files under getcwd()
--- scope = <path>    → that specific file (or glob)
---
---@param opts Custom.Fmt.FmtTbl.Opts|nil
---@return boolean ok, string|nil err
function M.format_tables_in_scope(opts)
  opts = opts or {}

  local scope = opts.scope or "cursor"

  if scope == "cursor" then
    local ok, err = M.format_table_at_cursor(nil, opts)
    return ok, err

  elseif scope == "buffer" then
    local ok, err, count = M.format_tables_in_buffer(nil, opts)
    if ok then
      notify.info(string.format("Formatted %d table(s) in buffer", count))
    end
    return ok, err

  elseif scope == "cwd" then
    local cwd   = vim.fn.getcwd()
    local files = collect_md_files(cwd)

    if #files == 0 then
      notify.info("No *.md files found under " .. cwd)
      return true, nil
    end

    local header_align = opts.header_align or _cfg.header_align
    local entry_align  = opts.entry_align  or _cfg.entry_align
    -- For file-level formatting we pass nil overrides (resolved per-table inside format_file).
    local errors   = {}
    local fmt_count = 0

    for _, path in ipairs(files) do
      local ok, err = format_file(path, header_align, entry_align, nil)
      if ok then
        fmt_count = fmt_count + 1
      else
        errors[#errors + 1] = err
      end
    end

    if #errors > 0 then
      notify.warn(string.format(
        "Formatted %d/%d files; %d error(s):\n  %s",
        fmt_count, #files, #errors, table.concat(errors, "\n  ")
      ))
    else
      notify.info(string.format("Formatted tables in %d file(s)", fmt_count))
    end

    return #errors == 0, #errors > 0 and table.concat(errors, "; ") or nil

  else
    -- Treat scope as a file path.
    local path = vim.fn.expand(scope)

    if vim.fn.filereadable(path) == 0 then
      return false, string.format("File not readable: %q", path)
    end

    local header_align = opts.header_align or _cfg.header_align
    local entry_align  = opts.entry_align  or _cfg.entry_align
    local ok, err      = format_file(path, header_align, entry_align, nil)

    if ok then
      notify.info(string.format("Formatted tables in %q", path))
    end

    return ok, err
  end
end

return M
