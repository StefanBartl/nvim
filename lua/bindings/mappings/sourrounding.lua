---@module 'bindings.mappings.sourrounding'
--- CDX: filename is misspelled ("sourrounding" → "surrounding"). Rename the
--- file + the one `require` in bindings/mappings/init.lua.
--- Visual-mode mappings to surround the current selection.
--- This version binds the bracket pairs to single-tap sequences:
---   []  -> surround with [ ... ]
---   ()  -> surround with ( ... )
---   {}  -> surround with { ... }
---   `   -> surround with ` ... `   (one tap, see `define_mappings`)
--- The legacy double-tap triggers [[, ((, {{ are no longer used to avoid conflicts
--- (e.g., markdown section jumps on [[).

---@class SurroundConfig
---@field single_quote  boolean|nil  -- enable '' for quotes
---@field double_quotes boolean|nil  -- enable "" for quotes
---@field backticks     boolean|nil  -- enable ` for backticks
---@field backtick_lhs  string|nil   -- trigger for the backtick surround (default "`")
---@field parens        boolean|nil  -- enable () for parentheses
---@field brackets      boolean|nil  -- enable [] for brackets
---@field braces        boolean|nil  -- enable {} for braces
---@field desc_prefix   string|nil   -- map description prefix
---@field mapfun        fun(mode:string,lhs:string,rhs:function,opts:table)|nil  -- optional custom map helper

local M = {}

---@type SurroundConfig
M.cfg = {
  single_quote = true,
  double_quotes = true,
  backticks = true,
  -- Single tap, not the `` double tap the other pairs use — see the note in
  -- `define_mappings`. Set to "``" to get the old double-tap trigger back.
  backtick_lhs = "`",
  parens = true,
  brackets = true,
  braces = true,
  desc_prefix = "Surround selection with ",
}

local ESC = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
local CTRL_V = vim.api.nvim_replace_termcodes("<C-v>", true, false, true)

--- Byte-length of the line at 0-based `row`.
---@param row integer
---@return integer
local function line_len(row)
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
  return line and #line or 0
end

--- Leave Visual mode and return the selected region together with the mode it
--- was made in. Must run before the '< / '> marks are read, because those are
--- only updated once Visual mode ends.
---@return string mode  -- "v", "V" or "<C-v>"
---@return integer srow, integer scol, integer erow, integer ecol  -- 0-based, end-exclusive
local function selection()
  local mode = vim.fn.mode()
  vim.api.nvim_feedkeys(ESC, "nx", false)

  local s = vim.api.nvim_buf_get_mark(0, "<")
  local e = vim.api.nvim_buf_get_mark(0, ">")
  local srow, scol = s[1] - 1, s[2]
  local erow, ecol = e[1] - 1, e[2]

  if mode == "V" then
    -- Linewise: the marks carry no meaningful columns, so span the full lines.
    scol, ecol = 0, line_len(erow)
  else
    -- Charwise/blockwise marks are inclusive and point at the FIRST byte of the
    -- last character; extend past that character so multibyte text survives.
    local last = vim.api.nvim_buf_get_lines(0, erow, erow + 1, false)[1] or ""
    if vim.o.selection == "exclusive" then
      ecol = math.min(ecol, #last)
    elseif ecol < #last then
      ecol = ecol + vim.str_utf_end(last, ecol + 1) + 1
    else
      ecol = #last
    end
  end

  return mode, srow, scol, erow, ecol
end

--- Insert `open` / `close` around one region of a single line or across lines.
--- Applied end-first so the start position stays valid.
---@param srow integer  -- 0-based start row
---@param scol integer  -- 0-based start byte column
---@param erow integer  -- 0-based end row
---@param ecol integer  -- 0-based end byte column (exclusive)
---@param open string
---@param close string
---@return nil
local function wrap_region(srow, scol, erow, ecol, open, close)
  vim.api.nvim_buf_set_text(0, erow, ecol, erow, ecol, { close })
  vim.api.nvim_buf_set_text(0, srow, scol, srow, scol, { open })
end

--- Surround the current Visual selection with an opening/closing pair.
--- Uses the buffer API rather than feedkeys, so neither the selection mode
--- (charwise vs. linewise) nor insert-mode plugins such as nvim-autopairs can
--- alter the inserted delimiters.
---@param open string  -- e.g. "(", "[", "{", "`"
---@param close string -- e.g. ")", "]", "}", "`"
---@return nil
local function surround_pair(open, close)
  local mode, srow, scol, erow, ecol = selection()

  if mode == CTRL_V then
    -- Blockwise: wrap the same column range on every touched line, skipping
    -- lines that are too short to contain the block.
    local lo, hi = math.min(scol, ecol), math.max(scol, ecol)
    for row = erow, srow, -1 do
      local len = line_len(row)
      if len > lo then
        wrap_region(row, lo, row, math.min(hi, len), open, close)
      end
    end
  else
    wrap_region(srow, scol, erow, ecol, open, close)
  end

  vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
end

--- Surround the current Visual selection with a symmetric delimiter.
---@param ch string  -- expected: '"', "'", or "`"
---@return nil
local function surround_with(ch)
  surround_pair(ch, ch)
end

--- Define a Visual-mode mapping with optional project-specific helper.
---@param lhs string
---@param cb fun()
---@param desc string
---@return nil
local function xmap(lhs, cb, desc)
  -- Optional project-specific helper:
  local map = M.cfg.mapfun or require("lib.nvim.bindings.keymap")
  map("x", lhs, cb, { desc = desc, silent = true, noremap = true })
end

--- Apply user overrides into M.cfg.
---@param opts table|nil
---@return nil
local function apply_opts(opts)
  if type(opts) ~= "table" then
    return
  end
  for k, v in pairs(opts) do
    M.cfg[k] = v
  end
end

--- Create all requested mappings based on M.cfg.
---@return nil
local function define_mappings()
  local pfx = M.cfg.desc_prefix or "Surround selection with "

  if M.cfg.double_quotes ~= false then
    xmap('""', function()
      surround_with('"')
    end, pfx .. 'double quotes (")')
  end

  if M.cfg.single_quote ~= false then
    xmap("''", function()
      surround_with("'")
    end, pfx .. "single quotes (')")
  end

  -- Single tap, not the `` double tap the bracket pairs use: the first ` is
  -- already a complete built-in (goto-mark), so at normal typing speed
  -- 'timeoutlen' fires it before the second ` arrives and the surround
  -- silently no-ops. Cost: `{mark} as a Visual motion, which ' covers.
  if M.cfg.backticks ~= false then
    xmap(M.cfg.backtick_lhs or "`", function()
      surround_with("`")
    end, pfx .. "backticks (`)")
  end

  if M.cfg.parens ~= false then
    xmap("()", function()
      surround_pair("(", ")")
    end, pfx .. "()")
  end

  if M.cfg.brackets ~= false then
    xmap("[]", function()
      surround_pair("[", "]")
    end, pfx .. "[]")
  end

  if M.cfg.braces ~= false then
    xmap("{}", function()
      surround_pair("{", "}")
    end, pfx .. "{}")
  end
end

--- Public setup entrypoint.
---@param opts SurroundConfig|nil
---@return nil
function M.setup(opts)
  apply_opts(opts)
  define_mappings()
end

return M
