---@module 'bindings.usrcmds.execute.source'
---@brief Where the text of `:Execute` comes from: a selection, an inline `code` span, a fenced block, a line.
---@description
--- The command needs one answer to "what is the user pointing at?". This module gives it, in a fixed
--- order when the user does not say (`from = "auto"`):
---
---   1. a range / Visual selection      (`:'<,'>Execute`)
---   2. the `inline code` span under the cursor
---   3. the fenced block (``` or ~~~) the cursor is inside
---   4. the current line
---
--- `from` pins one of them (`selection`, `backtick`, `fence`, `line`, `clipboard`), so a typo in the
--- text never silently turns into another source.
---
--- Key responsibilities:
---  - `backtick_at` / `fence_at`: the two text-shape finders, pure (a string or a list of lines in,
---    text out), so they are tested without a window
---  - `get`: reads the current buffer / the clipboard and applies the order above
---
--- Not its job: deciding whether the text is Ex, Lua or shell (`execute.kind`), running it
--- (`execute.sink`), the command itself (`execute.init`).

local M = {}

---Every value `from` takes, in the order the completion shows them.
---@type string[]
M.FROM = { "auto", "selection", "backtick", "line", "fence", "clipboard" }

---What each `from` value means (shown by the completion).
---@type table<string, string>
M.FROM_DESC = {
  auto = "selection, else `code` under the cursor, else fenced block, else the line",
  selection = "the Visual selection or the given range",
  backtick = "the `inline code` span under the cursor",
  line = "the current line (or the lines of the range)",
  fence = "the fenced code block the cursor is inside",
  clipboard = "the text in the + register",
}

---@alias Execute.From "auto"|"selection"|"backtick"|"line"|"fence"|"clipboard"

---One piece of text and where it came from.
---@class Execute.Source
---@field text string        the text, lines joined with "\n"
---@field lines string[]     the same text as lines
---@field from Execute.From  what was used; never "auto"
---@field lang string|nil    the info string of a fence ("bash", "lua", ...), lower-cased

---The Visual / range data the command hands over (`ctx.range` of the composer).
---@class Execute.Range
---@field range integer|nil   0 when the command had no range
---@field line1 integer|nil
---@field line2 integer|nil
---@field mode string|nil     "v", "V" or the block mode of the last Visual selection
---@field col1 integer|nil    byte column of '<
---@field col2 integer|nil    byte column of '>

---@class Execute.GetOpts
---@field from? Execute.From        default "auto"
---@field range? Execute.Range      `ctx.range` of the command
---@field bufnr? integer            default: the current buffer
---@field winid? integer            default: the current window (its cursor is read)

-- ── pure finders ─────────────────────────────────────────────────────────────

---The inline code span that contains byte column `col` of `line`.
---
---Implements the CommonMark rule that matters here: a span opens with a run of N backticks and closes at the
---next run of exactly N backticks, so ``a`b`` is one span holding a`b. A run without a partner is plain text.
---The cursor counts as inside when it is on the opening or closing backticks too.
---@param line string
---@param col integer  0-based byte column of the cursor
---@return string|nil inner  the text between the backticks, trimmed
function M.backtick_at(line, col)
  local runs = {} ---@type { s: integer, e: integer }[]
  local pos = 1
  while true do
    local s, e = line:find("`+", pos)
    if not s or not e then
      break
    end
    runs[#runs + 1] = { s = s, e = e }
    pos = e + 1
  end
  local i = 1
  while i <= #runs do
    local open = runs[i]
    local width = open.e - open.s + 1
    local partner
    for j = i + 1, #runs do
      if runs[j].e - runs[j].s + 1 == width then
        partner = j
        break
      end
    end
    if not partner then
      i = i + 1
    else
      local close = runs[partner]
      -- `col` is 0-based, the run positions are 1-based
      if col + 1 >= open.s and col + 1 <= close.e then
        local inner = vim.trim(line:sub(open.e + 1, close.s - 1))
        return inner ~= "" and inner or nil
      end
      i = partner + 1
    end
  end
  return nil
end

---The fenced block that contains line `row`.
---
---A fence opens with three or more backticks or tildes (any indent: a list item indents deeper than
---Markdown's three spaces) and closes with at least as many of the same character on a line of their own.
---An unclosed fence runs to the end of the buffer, like Markdown does. The fence lines themselves count as
---inside.
---@param lines string[]
---@param row integer  1-based line of the cursor
---@return string[]|nil body  the lines between the fences
---@return string|nil lang    first word of the info string, lower-cased; nil when there is none
function M.fence_at(lines, row)
  local open_row, char, width, lang
  for i, line in ipairs(lines) do
    if not open_row then
      local ticks, info = line:match("^%s*(```+)%s*(.-)%s*$")
      if not ticks then
        ticks, info = line:match("^%s*(~~~+)%s*(.-)%s*$")
      end
      -- a backtick fence cannot carry a backtick in its info string (that would be an inline span)
      if ticks and not (ticks:sub(1, 1) == "`" and info:find("`", 1, true)) then
        open_row, char, width = i, ticks:sub(1, 1), #ticks
        local first = info:match("^(%S+)")
        lang = first and first:lower() or nil
      end
    else
      local run = line:match("^%s*(" .. (char == "`" and "`+" or "~+") .. ")%s*$")
      if run and #run >= width then
        if row >= open_row and row <= i then
          return vim.list_slice(lines, open_row + 1, i - 1), lang
        end
        open_row = nil
      end
    end
  end
  if open_row and row >= open_row then
    return vim.list_slice(lines, open_row + 1, #lines), lang
  end
  return nil, nil
end

-- ── readers ──────────────────────────────────────────────────────────────────

---Whether the command really came with a range.
---@param range Execute.Range|nil
---@return boolean
local function has_range(range)
  return range ~= nil and (range.range or 0) > 0 and range.line1 ~= nil and range.line2 ~= nil
end

---The selected text.
---
---A charwise selection (`v`) is cut at its columns; a linewise or blockwise one, and a plain range, give
---whole lines. The columns come from the `'<` / `'>` marks, which outlive their selection, so they are used
---only when the marks sit on exactly the lines of this range (`:5,10Execute` after an old selection must not
---cut by the old columns).
---@param bufnr integer
---@param range Execute.Range
---@return string[] lines
local function selection_lines(bufnr, range)
  local l1, l2 = range.line1, range.line2
  local m1, m2 = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local charwise = range.mode == "v" and m1[2] == l1 and m2[2] == l2
  if not charwise then
    return vim.api.nvim_buf_get_lines(bufnr, l1 - 1, l2, false)
  end
  local c1, c2 = m1[3], m2[3]
  local last = vim.api.nvim_buf_get_lines(bufnr, l2 - 1, l2, false)[1] or ""
  -- `'>` points at the first byte of the last selected character: take the whole (multibyte) character
  local stop = c2 - 1
  if c2 >= 1 and c2 <= #last then
    stop = c2 + vim.str_utf_end(last, c2)
  end
  stop = math.min(stop, #last)
  local ok, got = pcall(vim.api.nvim_buf_get_text, bufnr, l1 - 1, c1 - 1, l2 - 1, stop, {})
  if ok then
    return got
  end
  return vim.api.nvim_buf_get_lines(bufnr, l1 - 1, l2, false)
end

---@param lines string[]
---@param from Execute.From
---@param lang? string
---@return Execute.Source
local function make(lines, from, lang)
  return { text = table.concat(lines, "\n"), lines = lines, from = from, lang = lang }
end

---The text of the clipboard as lines (CRLF and one trailing newline removed).
---@return string[]|nil lines  nil when the clipboard is empty
local function clipboard_lines()
  local text = vim.fn.getreg("+")
  if text == "" then
    text = vim.fn.getreg("*")
  end
  if text == "" then
    return nil
  end
  text = text:gsub("\r\n", "\n")
  text = text:gsub("\n$", "")
  return vim.split(text, "\n", { plain = true })
end

---Read the text the user points at.
---@param opts? Execute.GetOpts
---@return Execute.Source|nil source
---@return string|nil err  why there is nothing to run
function M.get(opts)
  opts = opts or {}
  local from = opts.from or "auto"
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()
  local winid = opts.winid or vim.api.nvim_get_current_win()
  local range = opts.range
  local row, col = unpack(vim.api.nvim_win_get_cursor(winid))

  if from == "clipboard" then
    local lines = clipboard_lines()
    if not lines then
      return nil, "the clipboard is empty"
    end
    return make(lines, "clipboard")
  end

  if from == "selection" or (from == "auto" and has_range(range)) then
    if not has_range(range) then
      return nil,
        "no selection: select text first (Visual mode) or give a range, e.g. :'<,'>Execute"
    end
    ---@cast range Execute.Range
    return make(selection_lines(bufnr, range), "selection")
  end

  if from == "line" then
    if has_range(range) then
      ---@cast range Execute.Range
      return make(vim.api.nvim_buf_get_lines(bufnr, range.line1 - 1, range.line2, false), "line")
    end
    return make(vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false), "line")
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  if from == "backtick" or from == "auto" then
    local inner = M.backtick_at(line, col)
    if inner then
      return make({ inner }, "backtick")
    end
    if from == "backtick" then
      return nil, "the cursor is not inside an `inline code` span"
    end
  end

  if from == "fence" or from == "auto" then
    local body, lang = M.fence_at(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), row)
    if body then
      return make(body, "fence", lang)
    end
    if from == "fence" then
      return nil, "the cursor is not inside a fenced code block"
    end
  end

  return make({ line }, "line")
end

return M
