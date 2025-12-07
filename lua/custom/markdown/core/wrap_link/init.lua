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
---
--- All operations work directly on the buffer without autocommands.

local M = {}
local map = require("lib.map")
local api = vim.api
local nvim_buf_set_text = api.nvim_buf_set_text
local nvim_win_set_cursor = api.nvim_win_set_cursor
local nvim_buf_get_mark = api.nvim_buf_get_mark

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

---@param bufnr integer|nil Buffer number
function M.attach(bufnr)
  if not bufnr or not is_markdown_buf(bufnr) then
    return
  end

  local opts = { buffer = bufnr, noremap = true, silent = true }

  --- Handler for <leader>[ mapping in normal mode
  local function wrap_handler_normal()
    local row, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_get_current_line()

    -- Get word under cursor using native Vim word boundaries
    local word_start = col
    local word_end = col

    -- Find start of word (move left while on word character)
    while word_start > 0 and line:sub(word_start, word_start):match("%S") do
      word_start = word_start - 1
    end
    word_start = word_start + 1

    -- Find end of word (move right while on word character)
    while word_end <= #line and line:sub(word_end + 1, word_end + 1):match("%S") do
      word_end = word_end + 1
    end

    local word = line:sub(word_start, word_end)

    -- Case 1: Empty space or no word under cursor
    if word == "" or word:match("^%s*$") then
      -- Insert []() and position cursor inside []
      nvim_buf_set_text(bufnr, row - 1, col, row - 1, col, { "[]()" })
      nvim_win_set_cursor(0, { row, col + 1 })
      return
    end

    -- Case 2: URL or file path under cursor
    if is_url_or_path(word) then
      -- Wrap with () and prepend [], cursor inside []
      local wrapped = "[](" .. word .. ")"
      nvim_buf_set_text(bufnr, row - 1, word_start - 1, row - 1, word_end, { wrapped })
      -- Position cursor inside []
      nvim_win_set_cursor(0, { row, word_start })
      return
    end

    -- Case 3: Plain text under cursor
    -- Wrap with [], append (), cursor inside ()
    local wrapped = "[" .. word .. "]()"
    nvim_buf_set_text(bufnr, row - 1, word_start - 1, row - 1, word_end, { wrapped })
    -- Position cursor inside ()
    nvim_win_set_cursor(0, { row, word_start + #word + 2 })
  end

  --- Handler for <leader>[ mapping in visual mode
  local function wrap_handler_visual()
    -- Get visual selection boundaries BEFORE exiting visual mode
    -- Use marks '< and '> which are set by visual mode
    local start_mark = nvim_buf_get_mark(bufnr, "<")
    local end_mark = nvim_buf_get_mark(bufnr, ">")

    local start_row = start_mark[1] - 1  -- Convert to 0-indexed
    local start_col = start_mark[2]      -- Already 0-indexed
    local end_row = end_mark[1] - 1      -- Convert to 0-indexed
    local end_col = end_mark[2]          -- Already 0-indexed

    -- Get the selected text
    local lines = api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col + 1, {})

    -- Exit visual mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

    -- Join lines if multi-line selection
    local text = table.concat(lines, "\n")

    -- Trim whitespace for better analysis
    local trimmed_text = text:match("^%s*(.-)%s*$") or ""

    if trimmed_text == "" then
      -- Empty selection, just insert []()
      nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col + 1, { "[]()" })
      nvim_win_set_cursor(0, { start_row + 1, start_col + 1 })
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
        -- Wrap with () and prepend [], cursor inside []
        wrapped = "[](" .. trimmed_text .. ")"
        cursor_offset = 1  -- Position cursor inside []
      else
        -- Case: Single plain word
        -- Wrap with [], append (), cursor inside ()
        wrapped = "[" .. trimmed_text .. "]()"
        cursor_offset = #trimmed_text + 2  -- Position cursor inside ()
      end
    else
      -- Multiple words or multiline: always treat as plain text
      -- Wrap with [], append (), cursor inside ()
      wrapped = "[" .. trimmed_text .. "]()"
      cursor_offset = #trimmed_text + 2  -- Position cursor inside ()
    end

    -- Replace the selected text with wrapped version
    nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col + 1, { wrapped })
    nvim_win_set_cursor(0, { start_row + 1, start_col + cursor_offset })
  end

  map("n", "<leader>[", wrap_handler_normal, opts, "[Custom.Markdown] Wrap word, URL, or path in link")
  map("v", "<leader>[", wrap_handler_visual, opts, "[Custom.Markdown] Wrap selection in link")
end

return M
