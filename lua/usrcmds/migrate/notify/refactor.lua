---@module 'usrcmds.migrate.notify.refactor'
---@brief Apply notify migrations with proper line/multiline handling
---@description
--- FIXED VERSION - Critical fixes:
---   1. Correct index conversion (parser gives 1-based, API needs 0-based)
---   2. Single-line: use string.sub for partial replacement
---   3. Multi-line: proper line joining with indent preservation
---   4. NO newlines in replacement strings for nvim_buf_set_lines

require("usrcmds.migrate.notify.@types")

local M = {}

local api = vim.api

--------------------------------------------------------------------------------
-- Import handling
--------------------------------------------------------------------------------

---Check what kind of import exists
---@param bufnr integer
---@return boolean has_simple, boolean has_create, integer|nil import_line
local function check_import(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, 50, false)

  local has_simple = false
  local has_create = false
  local import_line = nil

  for i, line in ipairs(lines) do
    -- Check for require("lib.notify")
    if line:match('local%s+notify%s*=%s*require%s*%(%s*["\']lib%.notify["\']%s*%)') then
      has_simple = true
      import_line = i

      -- Check if it also has .create()
      if line:match('%.create%s*%(') then
        has_create = true
      end
    end
  end

  return has_simple, has_create, import_line
end

---Find first non-comment line
---@param bufnr integer
---@return integer line_idx 0-based index
local function find_first_code_line(bufnr)
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= "" and not trimmed:match("^%-%-") then
      return i - 1
    end
  end

  return 0
end

---Inject or upgrade import - ALWAYS uses .create("")
---@param bufnr integer
---@return boolean added True if import was added or modified
function M.inject_import(bufnr)
  local has_simple, has_create, import_line = check_import(bufnr)

  -- If we already have .create(), nothing to do
  if has_create then
    return false
  end

  -- If we have simple import, upgrade it to .create()
  if has_simple and import_line then
    local lines = api.nvim_buf_get_lines(bufnr, import_line - 1, import_line, false)
    local old_line = lines[1]

    -- Replace the line to add .create("")
    local new_line = old_line:gsub(
      '(local%s+notify%s*=%s*require%s*%(%s*["\']lib%.notify["\']%s*%))',
      '%1.create("")'
    )

    api.nvim_buf_set_lines(bufnr, import_line - 1, import_line, false, { new_line })
    return true
  end

  -- No import exists, add .create() version
  local insert_pos = find_first_code_line(bufnr)
  api.nvim_buf_set_lines(
    bufnr,
    insert_pos,
    insert_pos,
    false,
    { 'local notify = require("lib.notify").create("")', "" }
  )
  return true
end

--------------------------------------------------------------------------------
-- Application (FIXED VERSION)
--------------------------------------------------------------------------------

---Apply single match replacement
---@param bufnr integer
---@param match MigrateNotify.Match
---@return boolean success
function M.apply_match(bufnr, match)
  if not api.nvim_buf_is_valid(bufnr) then
    return false
  end

  -- Parser gibt 1-based line numbers (wie Vim)
  -- col/end_col sind 0-based byte offsets
  local start_line = match.line       -- 1-based (Vim-style)
  local end_line = match.end_line     -- 1-based (Vim-style)
  local start_col = match.col         -- 0-based byte offset
  local end_col = match.end_col       -- 0-based byte offset (exclusive!)

  -- Convert to 0-based for API
  local start_idx = start_line - 1
  local end_idx = end_line            -- NICHT -1! API erwartet exclusive end

  -- Get affected lines
  local lines = api.nvim_buf_get_lines(bufnr, start_idx, end_idx, false)

  if #lines == 0 then
    return false
  end

  -- CRITICAL: Replacement darf KEINE newlines enthalten!
  -- nvim_buf_set_lines erwartet array of strings, jeder string = eine Zeile
  local replacement = match.replacement:gsub("\n", " ")  -- Newlines → spaces

  if start_line == end_line then
    -- ===================================================================
    -- SINGLE-LINE REPLACEMENT
    -- ===================================================================
    local line = lines[1]

    -- Lua strings sind 1-based!
    -- start_col ist 0-based → +1 für Lua
    -- end_col ist exclusive → direkt nutzen als "bis hier" (nicht +1!)
    local before = line:sub(1, start_col)           -- Von Anfang bis start (exklusive)
    local after = line:sub(end_col + 1)             -- Von end (exclusive) bis Ende

    local new_line = before .. replacement .. after

    -- Setze die EINE Zeile
    api.nvim_buf_set_lines(bufnr, start_idx, start_idx + 1, false, { new_line })

  else
    -- ===================================================================
    -- MULTI-LINE REPLACEMENT
    -- ===================================================================
    local first_line = lines[1]
    local last_line = lines[#lines]

    -- Indent von erster Zeile extrahieren
    local indent = first_line:match("^(%s*)")

    -- Before-Teil: alles vor start_col in erster Zeile
    local before = first_line:sub(1, start_col)

    -- After-Teil: alles nach end_col in letzter Zeile
    local after = last_line:sub(end_col + 1)

    -- Baue EINE Zeile mit korrektem Indent
    local new_line = before .. replacement .. after

    -- Ersetze ALLE betroffenen Zeilen mit EINER neuen Zeile
    api.nvim_buf_set_lines(bufnr, start_idx, end_idx, false, { new_line })
  end

  return true
end

return M
