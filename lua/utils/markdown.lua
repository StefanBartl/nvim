---@module 'utils.markdown'
--- Markdown utilities: folding, heading navigation, heading level shifting, and TOC updates.

---@class MdUtils
---@field last_search string|nil Private cache for last search pattern (optional)
local M = {}

-- Local aliases (kept minimal; see project rules). Improves readability without over-optimizing.
local api, fn, cmd = vim.api, vim.fn, vim.cmd

--------------------------------------------------------------------------------
-- Types
--------------------------------------------------------------------------------

---@alias Lnum integer
---@alias HeadingLevel integer  -- 1..6
---@alias ShiftDelta integer    -- positive or negative

---@class ShiftOpts
---@field min_level HeadingLevel|nil Minimum level to consider (default: 2)
---@field max_level HeadingLevel|nil Maximum level to consider (default: 6)
---@field restrict_to_visual boolean|nil If true, only operate on visual selection (auto-detected by default)

--------------------------------------------------------------------------------
-- Internal helpers (private)
--------------------------------------------------------------------------------

--- Validate current buffer handle.
--- @return integer|nil buf Returns buffer handle or nil if invalid
local function current_buf_valid()
  local buf = api.nvim_get_current_buf()
  if type(buf) ~= "number" or buf <= 0 then return nil end
  if not api.nvim_buf_is_valid(buf) then return nil end
  return buf
end

--- Validate current window handle.
--- @return integer|nil win Returns window handle or nil if invalid
local function current_win_valid()
  local win = api.nvim_get_current_win()
  if type(win) ~= "number" or win <= 0 then return nil end
  if not api.nvim_win_is_valid(win) then return nil end
  return win
end

--- Save current view safely.
--- @return table view A view snapshot to restore with winrestview
local function save_view()
  return fn.winsaveview()
end

--- Restore a previously saved view.
--- @param view table
--- @return nil
local function restore_view(view)
  if type(view) == "table" then pcall(fn.winrestview, view) end
end

--- Clear search highlight (no side effects if disabled).
--- @return nil
local function clear_hlsearch()
  cmd("nohlsearch")
end

--- Compute frontmatter region at top of file if present.
--- Returns the 1-based line number of the closing '---' or 0 if absent.
--- @param buf integer
--- @return Lnum
local function frontmatter_end(buf)
  -- Only top-level '---' ... '---' pair counts as YAML frontmatter.
  local line1 = api.nvim_buf_get_lines(buf, 0, 1, false)[1]
  if line1 ~= "---" then return 0 end
  local lines = api.nvim_buf_get_lines(buf, 1, -1, false)
  for i = 1, #lines do
    if lines[i] == "---" then
      -- +1 for zero-based to one-based; plus the initial line.
      return i + 1
    end
  end
  return 0
end

--- Detect ATX heading level (e.g., "### Title" -> 3).
--- Ignores fenced code blocks start/stop lines.
--- @param s string
--- @return HeadingLevel|nil
local function atx_level(s)
  -- Ignore fenced markers themselves
  if s:match("^%s*```") or s:match("^%s*~~~") then return nil end
  local hashes, rest = s:match("^%s*(#+)%s+(.*)$")
  if not hashes then return nil end
  if rest:match("^%s*$") then return nil end
  return #hashes
end

--- Determine Setext level based on current and next line ("====" -> 1, "----" -> 2).
--- @param cur string
--- @param nxt string|nil
--- @return HeadingLevel|nil
local function setext_level(cur, nxt)
  if not nxt or nxt == "" then return nil end
  if cur:match("^%s*```") or cur:match("^%s*~~~") then return nil end
  if nxt:match("^%s*==+%s*$") then return 1 end
  if nxt:match("^%s*%-%-+%s*$") then return 2 end
  return nil
end

--- Get current visual selection range as (start_lnum, end_lnum) or nil.
--- Works only if mode is visual-line/char; otherwise returns nil.
--- @return Lnum|nil, Lnum|nil
local function get_visual_range()
  local mode = api.nvim_get_mode().mode
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then return nil, nil end -- char/line/block
  local srow = fn.getpos("v")[2]
  local erow = fn.getpos(".")[2]
  if type(srow) ~= "number" or type(erow) ~= "number" then return nil, nil end
  if srow > erow then srow, erow = erow, srow end
  return srow, erow
end

--- Iterate over lines [start_lnum, end_lnum] (inclusive) from current buffer.
--- @param start_lnum Lnum
--- @param end_lnum Lnum
--- @return string[] lines
local function get_lines_range(start_lnum, end_lnum)
  -- Buffer API uses 0-based indices; ensure clamp.
  local s = math.max(0, start_lnum - 1)
  local e = math.max(s, end_lnum) -- exclusive end (1-based)
  return api.nvim_buf_get_lines(0, s, e, false)
end

--- Safely set lines over a range.
--- @param start_lnum Lnum
--- @param end_lnum Lnum
--- @param lines string[]
--- @return boolean ok
local function set_lines_range(start_lnum, end_lnum, lines)
  local s = math.max(0, start_lnum - 1)
  local e = math.max(s, end_lnum)
  local ok = pcall(api.nvim_buf_set_lines, 0, s, e, false, lines)
  return ok
end

--- Build a Lua pattern to match exactly a given heading level.
--- @param level HeadingLevel
--- @return string
local function heading_pattern(level)
  return "^" .. string.rep("#", level) .. "%s+"
end

--------------------------------------------------------------------------------
-- Folding expression
--------------------------------------------------------------------------------

--- Fold expression for Markdown headings; recognizes:
--- - ATX headings (#..######) with H1 allowed only at top or immediately after frontmatter.
--- - Setext H1/H2 ("===="/"----" underline) as levels 1/2.
--- Returns Vim fold-expr codes: ">"..level to start fold, "=" to keep, "0" for none.
--- @param lnum Lnum
--- @return string|integer
function M.foldexpr(lnum)
  local buf = current_buf_valid()
  if not buf then return "0" end

  local cur = fn.getline(lnum)
  local nxt = fn.getline(lnum + 1)

  -- Fenced code lines: no folding markers on fence itself
  if cur:match("^%s*```") or cur:match("^%s*~~~") then
    return "0"
  end

  -- Setext detection (current + next)
  local s = setext_level(cur, nxt)
  if s then
    return ">" .. tostring(s)
  end

  -- ATX detection
  local a = atx_level(cur)
  if a then
    if a == 1 then
      local fm_end = frontmatter_end(buf)
      -- Allow H1 only on very first content line or directly after frontmatter.
      if lnum == 1 or (fm_end > 0 and lnum == fm_end + 1) then
        return ">1"
      else
        -- Treat stray H1 as a regular fold start anyway to avoid surprising behavior.
        return ">1"
      end
    else
      return ">" .. tostring(a)
    end
  end

  return "="
end

--------------------------------------------------------------------------------
-- Heading navigation and folding
--------------------------------------------------------------------------------

--- Jump to previous heading (H2..H6).
--- Uses a strict pattern: at least two hashes followed by space.
--- @return nil
function M.goto_prev_heading()
  if not current_win_valid() then return end
  -- 'b' flag = backward, 'W' = don't wrap (avoid infinite loops), 's' = set previous search register
  fn.search("^##\\+\\s\\+.*$", "bWs")
  clear_hlsearch()
end

--- Jump to next heading (H2..H6).
--- @return nil
function M.goto_next_heading()
  if not current_win_valid() then return end
  fn.search("^##\\+\\s\\+.*$", "Ws")
  clear_hlsearch()
end

--- Toggle fold under cursor and center line.
--- No-op if current line has no fold.
--- @return nil
function M.toggle_fold_under_cursor()
  if not current_win_valid() then return end
  local line = fn.line(".")
  local lvl = fn.foldlevel(line)
  if lvl == 0 then return end
  cmd("normal! za")
  cmd("normal! zz")
end

--- Unfold all folds and center cursor.
--- @return nil
function M.unfold_all_then_center()
  if not current_win_valid() then return end
  cmd("normal! zR")
  cmd("normal! zz")
end

--- Go to previous heading (H2+) and fold it; center the view.
--- @return nil
function M.fold_prev_heading_then_center()
  if not current_win_valid() then return end
  M.goto_prev_heading()
  cmd("normal! za")
  cmd("normal! zz")
end

--- Fold all headings of specific levels (e.g., {6,5,4,3,2}).
--- Requires a valid foldexpr to have been set.
--- @param levels HeadingLevel[]
--- @return nil
function M.fold_markdown_headings(levels)
  if not current_win_valid() then return end
  if type(levels) ~= "table" then return end
  local view = save_view()
  -- Re-open all to start from a known state.
  cmd("normal! zR")

  local total = fn.line("$")
  local pattern_cache = {} ---@type table<HeadingLevel,string>
  for i = 1, #levels do
    local lv = levels[i]
    if type(lv) == "number" and lv >= 1 and lv <= 6 then
      pattern_cache[lv] = heading_pattern(lv)
    end
  end

  for lnum = 1, total do
    local line = fn.getline(lnum)
    -- Skip fences entirely
    if not (line:match("^%s*```") or line:match("^%s*~~~")) then
      local a = atx_level(line)
      if a and pattern_cache[a] and fn.foldlevel(lnum) > 0 and fn.foldclosed(lnum) == -1 then
        cmd(("keepjumps call cursor(%d,1)"):format(lnum))
        cmd("normal! za")
      end
    end
  end

  clear_hlsearch()
  restore_view(view)
end

--------------------------------------------------------------------------------
-- Heading level shifting
--------------------------------------------------------------------------------

--- Shift heading levels by a delta (e.g., +1 or -1).
--- By default operates on the entire buffer; if visual selection is active, restricts to it.
--- Frontmatter is preserved; H1 can be protected by min_level=2 (default).
--- @param delta ShiftDelta Positive to increase, negative to decrease
--- @param opts ShiftOpts|nil Optional constraints (min_level/max_level)
--- @return nil
function M.shift_headings(delta, opts)
  if type(delta) ~= "number" or delta == 0 then return end
  local buf = current_buf_valid()
  if not buf then return end

  opts = opts or {}
  local min_level = (type(opts.min_level) == "number" and opts.min_level) or 2
  local max_level = (type(opts.max_level) == "number" and opts.max_level) or 6

  local srow, erow = get_visual_range()
  if not srow or not erow then
    srow, erow = 1, fn.line("$")
  end

  local fm_end = frontmatter_end(buf)
  local view = save_view()

  local lines = get_lines_range(srow, erow)
  local out = { [#lines] = "" } ---@type string[]  -- pre-allocate to reduce reallocations

  for i = 1, #lines do
    local lnum = srow + i - 1
    local line = lines[i]
    -- Preserve fence markers
    if line:match("^%s*```") or line:match("^%s*~~~") then
      out[i] = line
    else
      local lvl = atx_level(line)
      -- Skip setext here; we only shift ATX headings to avoid ambiguity.
      if lvl and lvl >= min_level and lvl <= max_level then
        local new_lvl = lvl + delta
        if new_lvl < 1 then new_lvl = 1 end
        if new_lvl > 6 then new_lvl = 6 end

        -- Protect the very first H1 after frontmatter if min_level > 1
        if new_lvl == 1 and min_level > 1 then
          if not (lnum == 1 or (fm_end > 0 and lnum == fm_end + 1)) then
            new_lvl = 2
          end
        end

        local _, rest = line:match("^(%s*#+)(%s+.*)$")
        if rest then
          out[i] = string.rep("#", new_lvl) .. rest
        else
          out[i] = line
        end
      else
        out[i] = line
      end
    end
  end

  set_lines_range(srow, erow, out)
  restore_view(view)
  clear_hlsearch()
end

--------------------------------------------------------------------------------
-- TOC update (markdown-toc CLI)
--------------------------------------------------------------------------------

--- Insert/update a Markdown TOC using the external "markdown-toc" CLI.
--- Places optional headings (H2 and H3) and '<!-- toc -->' below the first H1,
--- respecting an optional frontmatter block.
--- @param h2 string H2 title to insert above the TOC marker (e.g., "## Contents")
--- @param h3 string H3 title (subtitle) to insert above the TOC marker (e.g., "### Table of contents")
--- @return boolean ok
function M.update_markdown_toc(h2, h3)
  local buf = current_buf_valid()
  if not buf then return false end
  if fn.executable("markdown-toc") ~= 1 then
    -- No hard failure; just return false so callers can notify in UI layer if desired.
    return false
  end

  local view = save_view()
  local path = fn.expand("%")
  if type(path) ~= "string" or path == "" then
    restore_view(view)
    return false
  end

  -- Gather lines and find insertion points and existing marker.
  local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
  local has_toc = false
  local fm_end = frontmatter_end(buf)
  local h1_line = 0

  for i = (fm_end > 0 and fm_end or 0) + 1, #lines do
    if lines[i]:match("^#%s+") then
      h1_line = i
      break
    end
  end

  for i = 1, #lines do
    if lines[i]:match("^%s*<!%-%-%s*toc%s*%-%->%s*$") then
      has_toc = true
      break
    end
  end

  if not has_toc and h1_line > 0 then
    -- Insert H2, H3, and marker right below H1 (no blank lines).
    local insertion = h1_line + 1
    local to_insert = { h2, h3, "<!-- toc -->" }
    api.nvim_buf_set_lines(buf, insertion, insertion, false, to_insert)
    cmd("silent write")
  end

  -- Execute markdown-toc in-place with dash bullets only.
  fn.system({ "markdown-toc", "--bullets", "-", "-i", path })
  cmd("edit!")
  cmd("silent write")
  restore_view(view)
  return true
end

return M

