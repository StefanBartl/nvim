---@module 'custom.markdown.tableview.renderer'
---@description Renderer for MarkdownTable structures. Renders tables into a persistent floating window or into a scratch buffer.

local M = {}

local hl = vim.highlight
local api = vim.api

-- Module state: persistent buffer/window to reuse the floating view.
---@private
---@type table
local state = {
  buf = nil,
  win = nil,
  namespace = api.nvim_create_namespace("custom_markdown_tableview"),
}

--- Default configuration for rendering. Can be extended by caller.
---@type table
local default_opts = {
  floating = true,
  width = nil, -- absolute or fraction logic applied later
  height = nil,
  max_width_frac = 0.85,
  max_height_frac = 0.75,
  border = "rounded",
  use_box_chars = false, -- whether to draw box-drawing characters
  highlight = {
    header = "Title",
    separator = "Comment",
    cell = "Normal",
  },
}

-- Utility: safe table-merge shallow
---@param a table
---@param b table
---@return table
local function merge(a, b)
  local out = {}
  for k, v in pairs(a) do
    out[k] = v
  end
  if b then
    for k, v in pairs(b) do
      out[k] = v
    end
  end
  return out
end

--- Build a matrix of strings from MarkdownTable structure.
--- Return: array of rows, each row is array of cell strings.
---@param mt MarkdownTable
---@return string[][] matrix where first row is header
local function table_to_matrix(mt)
  local matrix = {}

  -- header row
  local header_cells = {}
  for _, c in ipairs(mt.header.cells) do
    table.insert(header_cells, tostring(c.content or ""))
  end
  table.insert(matrix, header_cells)

  -- data rows
  for _, r in ipairs(mt.rows) do
    local row_cells = {}
    for _, c in ipairs(r.cells) do
      table.insert(row_cells, tostring(c.content or ""))
    end
    table.insert(matrix, row_cells)
  end

  return matrix
end

--- Compute column widths for a matrix. Uses string length (#) which is byte-length;
--- for multi-byte characters, users may extend to use vim.str_utfindex if desired.
---@param matrix string[][]
---@return number[] widths
local function compute_col_widths(matrix)
  local widths = {}
  for _, row in ipairs(matrix) do
    for col_idx, cell in ipairs(row) do
      local len = #cell
      if not widths[col_idx] or len > widths[col_idx] then
        widths[col_idx] = len
      end
    end
  end
  return widths
end

--- Pad or align a single cell according to alignment.
---@param text string
---@param width number
---@param align string "left"|"center"|"right"
---@return string
local function align_cell(text, width, align)
  align = align or "left"
  local len = #text
  if width <= len then
    return text
  end
  local pad = width - len
  if align == "left" then
    return text .. string.rep(" ", pad)
  elseif align == "right" then
    return string.rep(" ", pad) .. text
  else -- center
    local left = math.floor(pad / 2)
    local right = pad - left
    return string.rep(" ", left) .. text .. string.rep(" ", right)
  end
end

--- Create a text line for a row given widths and alignments.
---@param row string[]
---@param widths number[]
---@param alignments string[] (for data rows, header alignment falls back to provided)
---@return string
local function format_row_with_alignment(row, widths, alignments)
  local parts = {}
  for i = 1, #widths do
    local cell = row[i] or ""
    local align = alignments[i] or "left"
    parts[i] = align_cell(cell, widths[i], align)
  end
  return "| " .. table.concat(parts, " | ") .. " |"
end

--- Build lines from MarkdownTable (including separator line)
---@param mt MarkdownTable
---@return string[] lines
local function build_lines_from_markdowntable(mt)
  local matrix = table_to_matrix(mt)
  if #matrix == 0 then
    return {}
  end

  local widths = compute_col_widths(matrix)

  -- Optionally enforce a max width per column (not implemented here by default)
  -- Build header line
  local lines = {}
  local header_row = matrix[1]
  table.insert(lines, format_row_with_alignment(header_row, widths, mt.alignments))

  -- Separator line: use dashes with alignment markers for readability
  local sep_parts = {}
  for i, w in ipairs(widths) do
    local align = mt.alignments[i] or "left"
    local _ = string.rep("-", math.max(1, w))
    if align == "center" then
      sep_parts[i] = ":" .. string.rep("-", math.max(1, w - 2)) .. ":"
    elseif align == "right" then
      sep_parts[i] = string.rep("-", math.max(1, w - 1)) .. ":"
    else
      sep_parts[i] = ":" .. string.rep("-", math.max(1, w - 1))
    end
  end
  table.insert(lines, "| " .. table.concat(sep_parts, " | ") .. " |")

  -- Data rows
  for ridx = 2, #matrix do
    table.insert(lines, format_row_with_alignment(matrix[ridx], widths, mt.alignments))
  end

  return lines
end

-- Helper wrappers to set buffer/window-local options using the new API.
-- Using pcall to avoid hard errors when running on older Neovim versions.
---@param buf number
---@param name string
---@param value any
local function set_buf_opt(buf, name, value)
  pcall(api.nvim_set_option_value, name, value, { scope = "local", buf = buf })
end

---@param win number
---@param name string
---@param value any
local function set_win_opt(win, name, value)
  pcall(api.nvim_set_option_value, name, value, { scope = "local", win = win })
end

--- Ensure there is a persistent scratch buffer and window for the table view.
--- Replaces deprecated nvim_buf_set_option / nvim_win_set_option usages.
---@param opts table|nil
---@return number buf, number win
local function ensure_view(opts)
  opts = opts or {}

  -- reuse existing valid buffer+window if present
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    if state.win and api.nvim_win_is_valid(state.win) then
      return state.buf, state.win
    end
    -- if buffer exists but window invalid, fall through to create new window for same buffer
  end

  -- create or reuse buffer
  if not (state.buf and api.nvim_buf_is_valid(state.buf)) then
    state.buf = api.nvim_create_buf(false, true) -- listed=false, scratch=true
  end

  -- Set buffer-local options via new API
  set_buf_opt(state.buf, "bufhidden", "wipe")
  set_buf_opt(state.buf, "filetype", "markdown-tableview")
  set_buf_opt(state.buf, "modifiable", false)
  set_buf_opt(state.buf, "buftype", "nofile")

  -- determine size
  local max_w = math.floor(vim.o.columns * (opts.max_width_frac or default_opts.max_width_frac))
  local max_h = math.floor(vim.o.lines * (opts.max_height_frac or default_opts.max_height_frac))
  local width = opts.width or math.min(math.max(40, max_w), vim.o.columns - 4)
  local height = opts.height or math.min(math.max(6, max_h), vim.o.lines - 4)

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = opts.border or default_opts.border,
  }

  -- ensure old invalid window handle is cleared
  if state.win and not api.nvim_win_is_valid(state.win) then
    state.win = nil
  end

  -- open a new floating window for the buffer (focus it)
  state.win = api.nvim_open_win(state.buf, true, win_opts)

  -- Set window-local options via new API
  set_win_opt(state.win, "wrap", false)
  set_win_opt(state.win, "cursorline", false)
  set_win_opt(state.win, "number", false)
  set_win_opt(state.win, "relativenumber", false)

  return state.buf, state.win
end

--- Clear namespace highlights in view buffer
---@param buf number
local function clear_highlights(buf)
  pcall(api.nvim_buf_clear_namespace, buf, state.namespace, 0, -1)
end

--- Render a MarkdownTable into the persistent floating view (or into a new scratch buffer if not floating)
---@param mt MarkdownTable
---@param opts table|nil
function M.render_markdowntable(mt, opts)
  opts = merge(default_opts, opts or {})

  local lines = build_lines_from_markdowntable(mt)

  if opts.floating then
    local buf, _ = ensure_view(opts)
    if not (buf and api.nvim_buf_is_valid(buf)) then
      return
    end

    -- write content (use proper nvim_buf_set_option instead of api.bo[...] access)
    set_buf_opt(state.buf, "modifiable", true)
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    set_buf_opt(state.buf, "modifiable", false)

    -- Apply simple highlights: header line (0) and separator (1)
    clear_highlights(buf)

    pcall(function()
      -- Use vim.highlight.range to mark entire header line and separator line.
      -- start_pos and end_pos are 0-indexed (line, col).
      -- Use col -1 to indicate end-of-line for range functions.
      local ns = state.namespace
      local header_hl = opts.highlight and opts.highlight.header or "Title"
      local sep_hl = opts.highlight and opts.highlight.separator or "Comment"

      -- header line (line 0)
      if #lines >= 1 then
        -- safe call: ensure highlight API exists
        if hl and hl.range then
          hl.range(buf, ns, header_hl, { 0, 0 }, { 0, -1 }, { inclusive = false })
        end
      end

      -- separator line (line 1)
      if #lines >= 2 then
        if hl and hl.range then
          hl.range(buf, ns, sep_hl, { 1, 0 }, { 1, -1 }, { inclusive = false })
        end
      end
    end)
  else
    -- Plain scratch buffer (not floating) - create a new buffer so user can edit/copy
    local buf = api.nvim_create_buf(true, false)
    api.nvim_buf_set_name(buf, opts.bufname or "[Markdown Table]")
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- set filetype using proper API
    api.bo[buf].filetype = "markdown"
    api.nvim_set_current_buf(buf)
  end
end

--- Close the persistent floating view if open
function M.close_view()
  if state.win and api.nvim_win_is_valid(state.win) then
    pcall(api.nvim_win_close, state.win, true)
  end
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    pcall(api.nvim_buf_delete, state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

--- Toggle rendering: if view open, close it; otherwise render the provided table
---@param mt MarkdownTable
---@param opts table|nil
function M.toggle_markdowntable(mt, opts)
  if state.win and api.nvim_win_is_valid(state.win) then
    M.close_view()
    return
  end
  M.render_markdowntable(mt, opts)
end

-- Public aliases for convenience
M.render_table = M.render_markdowntable
M.toggle_table = M.toggle_markdowntable
M.close = M.close_view

return M
