---@module 'custom.open.context'
---@brief Extract text context from the cursor position or visual selection.
---@description
--- Heuristically determines what text is "under" the user's intent:
---   • In normal mode  → WORD under cursor (vim's <cWORD>)
---   • After a visual selection → the selected text (via '</'> marks)
--- The result is classified as a URL, a path, or plain text.

local M = {}

local api = vim.api

-- ---------------------------------------------------------------------------
-- Heuristics
-- ---------------------------------------------------------------------------

local URL_PATTERNS = {
  "^https?://",
  "^ftp://",
  "^www%.",
}

local PATH_PATTERNS = {
  "^/",           -- absolute Unix path
  "^~/",          -- home-relative
  "^%.%./",       -- ../
  "^%./",         -- ./
  "^[A-Za-z]:\\", -- Windows drive letter  C:\
}

---@param text string
---@return boolean
local function classify_url(text)
  for _, p in ipairs(URL_PATTERNS) do
    if text:match(p) then
      return true
    end
  end
  return false
end

---@param text string
---@return boolean
local function classify_path(text)
  for _, p in ipairs(PATH_PATTERNS) do
    if text:match(p) then
      return true
    end
  end
  -- Also accept text that resolves to an existing filesystem entry.
  local stat = vim.uv.fs_stat(vim.fn.expand(text))
  return stat ~= nil
end

-- ---------------------------------------------------------------------------
-- Text extraction helpers
-- ---------------------------------------------------------------------------

---Get the WORD (non-whitespace run) under the cursor.
---@return string|nil
local function word_under_cursor()
  local ok, word = pcall(vim.fn.expand, "<cWORD>")
  if not ok or not word or word == "" then
    return nil
  end
  return word
end

---Get the visual selection using the '< and '> marks.
---Works in normal mode immediately after a visual selection ends.
---@return string|nil
local function visual_selection()
  local ok_s, start_pos = pcall(api.nvim_buf_get_mark, 0, "<")
  local ok_e, end_pos   = pcall(api.nvim_buf_get_mark, 0, ">")

  if not ok_s or not ok_e then
    return nil
  end

  if start_pos[1] == 0 or end_pos[1] == 0 then
    return nil
  end

  local ok_t, lines = pcall(
    api.nvim_buf_get_text,
    0,
    start_pos[1] - 1, start_pos[2],
    end_pos[1] - 1,   end_pos[2] + 1,
    {}
  )

  if not ok_t or not lines or #lines == 0 then
    return nil
  end

  local text = table.concat(lines, "\n")
  -- Trim surrounding whitespace from single-line results.
  if not text:find("\n") then
    text = text:match("^%s*(.-)%s*$") or text
  end

  if text == "" then
    return nil
  end

  return text
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---Build a context from the current editor state.
---Visual selection is preferred over the WORD under cursor.
---@return Custom.Open.Context|nil ctx, string|nil err
function M.build()
  -- Prefer a non-trivial visual selection when the marks are fresh.
  local text = visual_selection()

  -- Fallback to WORD under cursor.
  if not text or text == "" then
    text = word_under_cursor()
  end

  if not text or text == "" then
    return nil, "No text found under cursor or in selection"
  end

  -- Trim outer whitespace for consistent processing.
  text = text:match("^%s*(.-)%s*$") or text

  return {
    text    = text,
    is_url  = classify_url(text),
    is_path = classify_path(text),
  }, nil
end

return M
