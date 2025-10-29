---@module 'custom.markdown.tableview'
---Neovim plugin: collect markdown tables, present a picker and show selected table
---Features:
---- Detect Markdown tables in buffer via regex (GitHub Flavored Markdown table style)
---- Produce aligned Markdown and an ASCII-pretty table
---- Show result in a floating window or open temporary file for markdown-preview.nvim
---- Expose usercommands, keymaps, and config
---
---Usage:
---:TblPreviewPick         -> Collect tables in current buffer and pick one to show
---:TblPreviewCursor       -> If cursor inside a table, show that table
---map example (init.lua): vim.keymap.set('n','<leader>tp',require('md.tablepreview').pick, {desc='Pick table preview'})

-- BUG: FIX: AUDIT:

local M = {}

---@class md_tablepreview.Config
---@field prefer_browser boolean show in browser via markdown-preview if available
---@field float_width number fraction or absolute width for floating win (0.6 means 60% of columns)
---@field float_height number fraction or absolute height for floating win
---@field auto_on_cursor boolean if true show floating preview when cursor enters a table (can be noisy)
---@field filetype string filetype used for temp preview file (default 'markdown')
local default_config = {
  prefer_browser = false,
  float_width = 0.6,
  float_height = 0.4,
  auto_on_cursor = false,
  filetype = "markdown",
}

---@type md_tablepreview.Config
M.config = vim.deepcopy(default_config)

---@param opts table|nil
---@return nil
---@public
function M.setup(opts)
  -- Merge user config
  if opts and type(opts) == "table" then
    for k,v in pairs(opts) do M.config[k] = v end
  end

  -- Create user commands
  vim.api.nvim_create_user_command("TblPreviewPick", function() M.pick() end, {desc = "Pick a markdown table to preview"})
  vim.api.nvim_create_user_command("TblPreviewCursor", function() M.show_table_at_cursor() end, {desc = "Preview table at cursor"})

  -- Optional autocmd to auto-show on cursor moved (careful: can be noisy)
  if M.config.auto_on_cursor then
    vim.api.nvim_create_autocmd({"CursorMoved","CursorMovedI"}, {
      callback = function() M.show_table_at_cursor(true) end,
      desc = "Auto preview markdown table at cursor",
    })
  end
end

-- -----------------------
-- Table detection
-- -----------------------

---@return boolean
local function is_table_sep_line(s)
  -- matches separator like: | --- |:----:| ---: |
  -- allow leading/trailing spaces and optional leading/trailing '|'
  if not s then return false end
  local t = s:match("^%s*(.*)%s*$")
  if not t then return false end
  -- remove leading/trailing pipe for checking
  t = t:gsub("^%|", ""):gsub("%|$", "")
  -- split by pipe and test each cell
  for cell in t:gmatch("([^|]+)") do
    cell = vim.trim(cell)
    if cell == "" then
      -- empty cell still ok (e.g. " | :--- | ")
    else
      -- valid chars: -, :, whitespace
      if not cell:match("^:?[%-]+:??$") then
        return false
      end
    end
  end
  return true
end

---@param bufnr number
---@return {srow:number,erow:number,lines:string[]}[] list of tables with start/end (1-based)
local function find_tables_in_buffer(bufnr)
  bufNr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufNr, 0, -1, false)
  local results = {}
  local i = 1
  local n = #lines
  while i <= n do
    local line = lines[i]
    -- basic detection: a table header line containing '|' and next line is separator like ---|:---|
    if line:find("|") then
      local next_line = lines[i+1]
      if next_line and is_table_sep_line(next_line) then
        -- collect table: header + sep + following rows until blank or non-table-line
        local s = i
        local e = i+1
        for j = i+2, n do
          local l = lines[j]
          if l == "" or not l:find("|") then
            break
          end
          e = j
        end
        local tbl_lines = {}
        for k = s, e do table.insert(tbl_lines, lines[k]) end
        table.insert(results, {srow = s, erow = e, lines = tbl_lines})
        i = e + 1
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return results
end

-- -----------------------
-- Pretty align algorithm
-- -----------------------

---@param raw_lines string[] markdown table lines (header, sep, rows...)
---@return string[] aligned_lines
local function align_markdown_table(raw_lines)
  -- parse cells, compute column widths
  local rows = {}
  for _, ln in ipairs(raw_lines) do
    -- trim leading/trailing spaces and optional leading/trailing pipe
    local s = ln:match("^%s*(.*%S)%s*$") or ln
    s = s:gsub("^%|", ""):gsub("%|$", "")
    local cells = {}
    for cell in s:gmatch("([^|]*)") do
      -- cell may be empty string at end; trim spaces
      table.insert(cells, vim.trim(cell))
    end
    -- remove trailing empty cell introduced by pattern
    if #cells > 0 and cells[#cells] == "" then table.remove(cells) end
    table.insert(rows, cells)
  end

  -- compute max columns
  local cols = 0
  for _, r in ipairs(rows) do if #r > cols then cols = #r end end

  local widths = {}
  for c = 1, cols do widths[c] = 0 end
  for _, r in ipairs(rows) do
    for ci = 1, cols do
      local cell = r[ci] or ""
      local len = vim.fn.strdisplaywidth(cell)
      if len > widths[ci] then widths[ci] = len end
    end
  end

  -- produce aligned lines
  local aligned = {}
  for _, r in ipairs(rows) do
    local parts = {}
    for ci = 1, cols do
      local cell = r[ci] or ""
      -- pad cell to width
      local pad = widths[ci] - vim.fn.strdisplaywidth(cell)
      local padded = cell .. string.rep(" ", pad)
      table.insert(parts, " " .. padded .. " ")
    end
    local line = "|".. table.concat(parts, "|") .. "|"
    table.insert(aligned, line)
  end

  return aligned
end

---@param aligned_lines string[] produce an ASCII "box" representation (optional)
---@return string[] box_lines
local function ascii_box_from_aligned(aligned_lines)
  -- use aligned_lines (which are markdown pipes). Convert to a box drawing using +---+ style
  -- parse pipe-separated widths from first line
  local first = aligned_lines[1] or ""
  local cols = {}
  for seg in first:gmatch("|([^|]*)") do
    table.insert(cols, #seg)
  end
  -- top border
  local function rep(c, n) return string.rep(c, n) end
  local top = "+"
  for _, w in ipairs(cols) do top = top .. rep("-", w) .. "+" end
  local out = {top}
  for _, ln in ipairs(aligned_lines) do
    -- replace leading/trailing | with | and keep inside content
    out[#out+1] = ln
    out[#out+1] = top
  end
  return out
end

-- -----------------------
-- UI helpers
-- -----------------------

---@param lines string[] content lines for floating window
---@param opts table|nil
local function open_floating(lines, opts)
  opts = opts or {}
  local ui = vim.api.nvim_list_uis()[1] or {width = 80, height = 24}
  local width = opts.width or M.config.float_width
  local height = opts.height or M.config.float_height
  local win_width = math.floor((width < 1) and (ui.width * width) or width)
  local win_height = math.floor((height < 1) and (ui.height * height) or height)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = M.config.filetype
  local row = math.floor((ui.height - win_height) / 2)
  local col = math.floor((ui.width - win_width) / 2)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = win_width,
    height = win_height,
    style = "minimal",
    border = "rounded",
  })
  -- close on <esc>
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>bd!<CR>", {silent=true, nowait=true, noremap=true})
  return buf, win
end

---@param raw_lines string[] original markdown table lines
---@param opts table|nil
---@param use_ascii boolean|nil
function M.show_table_raw(raw_lines, opts, use_ascii)
  opts = opts or {}
  local aligned = align_markdown_table(raw_lines)
  local out = {}
  if use_ascii then
    out = ascii_box_from_aligned(aligned)
  else
    -- show header and aligned markdown
    out = aligned
  end
  open_floating(out, opts)
end

---@param bufnr number|nil
---@return nil
function M.pick(bufnr)
  local b = bufnr or vim.api.nvim_get_current_buf()
  local tables = find_tables_in_buffer(b)
  if #tables == 0 then
    vim.notify("No markdown tables found in buffer", vim.log.levels.INFO)
    return
  end
  local items = {}
  for i, t in ipairs(tables) do
    local preview = t.lines[1] or ""
    table.insert(items, ("%d: %s"):format(i, vim.trim(preview)))
  end
  vim.ui.select(items, {prompt = "Select table to preview:"}, function(choice, idx)
    if not choice or not idx then return end
    local sel = tables[idx]
    if M.config.prefer_browser then
      -- try opening with markdown-preview.nvim if available
      M.open_in_browser(sel.lines)
    else
      M.show_table_raw(sel.lines)
    end
  end)
end

---@param use_auto boolean|nil if true, suppress notifications
function M.show_table_at_cursor(use_auto)
  local b = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local tables = find_tables_in_buffer(b)
  for _, t in ipairs(tables) do
    if cur >= t.srow and cur <= t.erow then
      if M.config.prefer_browser then
        M.open_in_browser(t.lines)
      else
        M.show_table_raw(t.lines)
      end
      return
    end
  end
  if not use_auto then vim.notify("No table at cursor", vim.log.levels.INFO) end
end

-- -----------------------
-- Browser / markdown-preview integration
-- -----------------------

---@param lines string[] markdown lines
function M.open_in_browser(lines)
  -- Create temporary file and open with markdown-preview plugin if present.
  -- Fallback: open temp file in new buffer.
  local tmpname = vim.fn.tempname() .. ".md"
  local f = io.open(tmpname, "w")
  if not f then
    vim.notify("Could not create temp file for preview", vim.log.levels.ERROR)
    return
  end
  for _, l in ipairs(lines) do f:write(l .. "\n") end
  f:close()
  -- Try to trigger markdown-preview.nvim if available
  if vim.fn.exists(":MarkdownPreview") == 2 then
    -- open the temp file in a new tab and call MarkdownPreview
    vim.cmd("tabnew " .. vim.fn.fnameescape(tmpname))
    vim.cmd("MarkdownPreview")
  else
    -- fallback: open temp file in a new buffer
    vim.cmd("edit " .. vim.fn.fnameescape(tmpname))
    vim.notify("markdown-preview.nvim not found; opened temp file in buffer", vim.log.levels.INFO)
  end
end

return M
