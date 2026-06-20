---@module 'custom.markdown.core.wrap_link'
--- Module for wrapping words, selections, URLs, or file paths in Markdown links [text](url)
---
--- Behavior overview:
--- 1. Empty space (no word): Insert `[]()` and position cursor inside `[]`
--- 2. URL or file path under cursor: Wrap with `()` and prepend `[]`, cursor inside `[]`
--- 3. Plain text under cursor: Wrap with `[]`, append `()`, cursor inside `()`
--- 4. Visual mode selection:
---    * If selection is URL/path: Wrap with `()` and prepend `[]`, cursor inside `[]`
---    * Otherwise: Wrap with `[]`, append `()`, cursor inside `()`

local notify = require("lib.notify").create("[custom.markdown.core.wrap_link]")

local M = {}
local api = vim.api
local nvim_buf_set_text, nvim_win_set_cursor = api.nvim_buf_set_text, api.nvim_win_set_cursor

---@param bufnr integer Buffer number
---@return boolean True if buffer is markdown filetype
local function is_markdown_buf(bufnr)
  return vim.bo[bufnr].filetype == "markdown"
end

---@param text string Text to check
---@return boolean True if text looks like a URL or file path
local function is_url_or_path(text)
  -- Check for common URL schemes
  if text:match("^https?://") or text:match("^file://") or text:match("^ftp://") then
    return true
  end
  -- Check for file paths (contains path separators or file extensions)
  if text:match("[/\\]") or text:match("^%S+%.%S+$") then
    return true
  end
  return false
end

---@param bufnr integer Buffer number
function M.attach(bufnr)
  if not bufnr or not is_markdown_buf(bufnr) then
    return
  end

  local opts = { buffer = bufnr, noremap = true, silent = true }

  --- Handler for <leader>[ mapping in normal mode
  local function wrap_handler_normal()
    ---@diagnostic disable-next-line: deprecated
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_get_current_line()

    -- FIX: Use proper word character class instead of %S
    local word_start = col
    local word_end = col

    -- Find start of word (move left while on word character)
    while word_start > 0 and line:sub(word_start, word_start):match("[%w_./:\\-]") do
      word_start = word_start - 1
    end
    word_start = word_start + 1

    -- Find end of word (move right while on word character)
    while word_end < #line and line:sub(word_end + 1, word_end + 1):match("[%w_./:\\-]") do
      word_end = word_end + 1
    end

    local word = line:sub(word_start, word_end)

    -- Case 1: Empty space or no word under cursor
    if word == "" or word:match("^%s*$") then
      nvim_buf_set_text(bufnr, row - 1, col, row - 1, col, { "[]()" })
      nvim_win_set_cursor(0, { row, col + 1 })
      return
    end

    -- Case 2: URL or file path under cursor
    if is_url_or_path(word) then
      local wrapped = "[](" .. word .. ")"
      nvim_buf_set_text(bufnr, row - 1, word_start - 1, row - 1, word_end, { wrapped })
      nvim_win_set_cursor(0, { row, word_start })
      return
    end

    -- Case 3: Plain text under cursor
    local wrapped = "[" .. word .. "]()"
    nvim_buf_set_text(bufnr, row - 1, word_start - 1, row - 1, word_end, { wrapped })
    nvim_win_set_cursor(0, { row, word_start + #word + 2 })
  end

  --- Handler for <leader>[ mapping in visual mode
  local function wrap_handler_visual()
    -- CRITICAL FIX: We MUST read the actual selection from the mode state,
    -- NOT from marks, because marks are only updated AFTER visual mode exits.
    -- Use vim.fn.getpos('v') and current cursor to get live selection bounds.

    local mode = vim.fn.mode()
    if not mode:match('[vV\22]') then
      notify.error("[wrap_link] Not in visual mode")
      return
    end

    -- Get live selection bounds (these are 1-based)
    local cursor = api.nvim_win_get_cursor(0)
    local v_start = vim.fn.getpos('v')

    -- Determine selection bounds (handle reverse selection)
    local start_row, end_row, start_col, end_col
    if v_start[2] < cursor[1] or (v_start[2] == cursor[1] and v_start[3] <= cursor[2] + 1) then
      -- Normal direction: v_start is beginning
      start_row = v_start[2] - 1  -- Convert to 0-indexed
      start_col = v_start[3] - 1  -- Convert to 0-indexed
      end_row = cursor[1] - 1     -- Convert to 0-indexed
      end_col = cursor[2]         -- Already 0-indexed from nvim_win_get_cursor
    else
      -- Reverse selection: cursor is beginning
      start_row = cursor[1] - 1
      start_col = cursor[2]
      end_row = v_start[2] - 1
      end_col = v_start[3] - 1
    end

    -- For charwise visual mode, end_col points to the last selected character
    -- We need to make it exclusive (one past) for nvim_buf_set_text
    local end_col_exclusive = end_col + 1

    -- Validate indices
    local line_count = api.nvim_buf_line_count(bufnr)
    if start_row >= line_count or end_row >= line_count or start_row < 0 or end_row < 0 then
      notify.error("[wrap_link] Invalid selection range")
      return
    end

    -- Get line lengths to validate column positions
    local start_line = api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
    local end_line = api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1]

    if not start_line or not end_line then
      notify.error("[wrap_link] Could not read selection lines")
      return
    end

    -- Clamp column positions to valid range
    start_col = math.max(0, math.min(start_col, #start_line))
    end_col_exclusive = math.max(start_col + 1, math.min(end_col_exclusive, #end_line + 1))

    -- Get the selected text BEFORE exiting visual mode
    local ok, lines = pcall(api.nvim_buf_get_text, bufnr, start_row, start_col, end_row, end_col_exclusive, {})
    if not ok or not lines then
      notify.error("[wrap_link] Could not extract selection text: " .. tostring(lines))
      return
    end

    -- NOW exit visual mode (after all data is captured)
    vim.cmd('normal! \\<Esc>')

    -- Small delay to ensure mode change is complete
    vim.schedule(function()

    -- Join lines if multi-line selection
    local text = table.concat(lines, "\n")

    -- Trim whitespace for analysis
    local trimmed_text = text:match("^%s*(.-)%s*$") or ""

    if trimmed_text == "" then
      -- Empty selection, just insert []()
      local ok_set = pcall(api.nvim_buf_set_text, bufnr, start_row, start_col, end_row, end_col_exclusive, { "[]()" })
      if ok_set then
        api.nvim_win_set_cursor(0, { start_row + 1, start_col + 1 })
      end
      return
    end

    -- Check if it's a single word or multiple words
    local word_count = 0
    for _ in trimmed_text:gmatch("%S+") do
      word_count = word_count + 1
    end

    local wrapped
    local cursor_offset

    -- Single word without newlines: check if URL/path or plain text
    if word_count == 1 and not trimmed_text:match("\n") then
      if is_url_or_path(trimmed_text) then
        -- Case: Single word URL or file path
        wrapped = "[](" .. trimmed_text .. ")"
        cursor_offset = 1  -- Position cursor inside []
      else
        -- Case: Single plain word
        wrapped = "[" .. trimmed_text .. "]()"
        cursor_offset = #trimmed_text + 2  -- Position cursor inside ()
      end
    else
      -- Multiple words or multiline: always treat as plain text
      wrapped = "[" .. trimmed_text .. "]()"
      cursor_offset = #trimmed_text + 2  -- Position cursor inside ()
    end

    -- Replace the selected text with wrapped version
    local ok_set = pcall(api.nvim_buf_set_text, bufnr, start_row, start_col, end_row, end_col_exclusive, { wrapped })
    if ok_set then
      api.nvim_win_set_cursor(0, { start_row + 1, start_col + cursor_offset })
    else
      notify.error("[wrap_link] Failed to replace text")
    end
    end)  -- end of vim.schedule
  end

  -- Register keymaps
  vim.keymap.set("n", "<leader>[", wrap_handler_normal,
    vim.tbl_extend("force", opts, { desc = "[Custom.Markdown] Wrap word/URL in link" }))
  vim.keymap.set("v", "<leader>[", wrap_handler_visual,
    vim.tbl_extend("force", opts, { desc = "[Custom.Markdown] Wrap selection in link" }))
end

return M
