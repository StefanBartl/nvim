---@module 'options_experimental'
--- Experimental UI/UX enhancements for Neovim focusing on visual focus, feedback,
--- and gentle guidance while editing. This module is self-contained and relies
--- only on stock Neovim APIs; it optionally integrates with common plugins
--- (Treesitter, gitsigns) when available.
---
--- Place at: lua/options_experimental.lua
--- Load from (e.g.) lua/options.lua:  require("options_experimental")

---@alias Str string
---@alias Bool boolean
---@alias Int integer

---@enum DiagLevel
local DiagLevel = {
  ERROR = vim.diagnostic.severity.ERROR, -- 1
  WARN  = vim.diagnostic.severity.WARN,  -- 2
  INFO  = vim.diagnostic.severity.INFO,  -- 3
  HINT  = vim.diagnostic.severity.HINT,  -- 4
}

---@class ExpColors
---@field CursorNormal   table
---@field CursorInsert   table
---@field CursorVisual   table
---@field CursorReplace  table
---@field CursorLineN    table
---@field CursorLineI    table
---@field CursorLineV    table
---@field CursorLineR    table
---@field CursorLineNr   table
---@field LineNrDim      table
---@field IndentScope    table
---@field YankFlash      table
---@field PutFlash       table
---@field SignColError   table
---@field SignColWarn    table
---@field SignColInfo    table
---@field SignColHint    table
---@field SignColNeutral table
---@field TermNormal     table
---@field TermCursorLine table
---@field CursorWord     table
---@field MatchParen     table

---@class ExpOptions
---@field enable_indent_scope Bool
---@field enable_breadcrumbs Bool
---@field enable_yank_flash Bool
---@field enable_put_flash Bool
---@field map_put_flash Bool
---@field enable_signcolumn_tint Bool
---@field enable_terminal_palette Bool
---@field enable_insert_submode_colors Bool
---@field enable_current_word Bool
---@field enable_diff_peek Bool
---@field colors ExpColors
---@field large_file_kb Int
---@field breadcrumbs_max_len Int

local M = {}

-- ----------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------

---@type ExpOptions
M._cfg = {
  enable_indent_scope = true,
  enable_breadcrumbs = true,
  enable_yank_flash = true,
  enable_put_flash = true,
  map_put_flash = true,          -- post-paste flash by remapping p/P (non-recursive)
  enable_signcolumn_tint = true,
  enable_terminal_palette = true,
  enable_insert_submode_colors = true,
  enable_current_word = true,
  enable_diff_peek = true,       -- integrates with gitsigns if present
  large_file_kb = 5000,          -- throttle expensive visuals above this size
  breadcrumbs_max_len = 80,      -- max length of winbar line before truncation
  colors = {
    -- Cursor per mode (used via 'guicursor' custom groups)
    CursorNormal  = { bg = "#ffcc00", fg = "#1e1e1e" }, -- normal: amber block
    CursorInsert  = { bg = "#5fd7ff", fg = "#1e1e1e" }, -- insert: cyan bar
    CursorVisual  = { bg = "#ff5f87", fg = "#1e1e1e" }, -- visual: pink block
    CursorReplace = { bg = "#ff0000", fg = "#1e1e1e" }, -- replace: red underline

    -- CursorLine per mode (window-mapped via winhighlight on ModeChanged)
    CursorLineN   = { bg = "#2a2e36" },
    CursorLineI   = { bg = "#24313a" },
    CursorLineV   = { bg = "#322b3a" },
    CursorLineR   = { bg = "#3a2323" },

    -- Line numbers: active vs dim
    CursorLineNr  = { fg = "#ffd75f", bold = true },
    LineNrDim     = { fg = "#5a6374" },

    -- Indent scope (current block)
    IndentScope   = { bg = "#2f3440" },

    -- Flash regions
    YankFlash     = { bg = "#3e5f2a" },
    PutFlash      = { bg = "#2a4d6b" },

    -- SignColumn tints by worst diagnostic
    SignColError   = { bg = "#3a2323" },
    SignColWarn    = { bg = "#3a3623" },
    SignColInfo    = { bg = "#22333e" },
    SignColHint    = { bg = "#1f2f2a" },
    SignColNeutral = { bg = "NONE" },

    -- Terminal palette
    TermNormal     = { bg = "#151a1f" },
    TermCursorLine = { bg = "#20262d" },

    -- Current word and matchparen
    CursorWord     = { underline = true }, -- underline only (no bg)
    MatchParen     = { bg = "#3b4048", bold = true },
  },
}

-- ----------------------------------------------------------------------
-- Utilities
-- ----------------------------------------------------------------------

---@private
---@return Bool
local function is_large_file()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then return false end
  local uv = vim.uv or vim.loop
  local st = uv.fs_stat(name)
  if not st or not st.size then return false end
  return math.floor(st.size / 1024) > M._cfg.large_file_kb
end

---@private
---@param items table
---@return Int|nil
local function worst_diag_severity(items)
  local worst ---@type Int|nil
  for _, d in ipairs(items) do
    if not worst or d.severity < worst then
      worst = d.severity
    end
  end
  return worst
end

---@private
---@param s Str
---@param max Int
---@return Str
local function ellipsize_middle(s, max)
  if #s <= max then return s end
  local head = math.floor((max - 1) / 2)
  local tail = max - head - 1
  return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

---@private
---@param path Str
---@return Str
local function repo_relative(path)
  if path == "" then return "[No Name]" end
  local dir = vim.fn.fnamemodify(path, ":h")
  local gitdir = vim.fs.find(".git", { upward = true, path = dir })[1]
  if gitdir then
    local root = vim.fn.fnamemodify(gitdir, ":h")
    local rel = vim.fn.fnamemodify(path, (":~:%s"):format(root))
    if rel == path then
      return vim.fn.fnamemodify(path, ":t")
    end
    rel = rel:gsub("^%./", ""):gsub("^/", "")
    return rel
  else
    return vim.fn.fnamemodify(path, ":~:.")
  end
end

---@private
---@param name Str
---@param spec table
local function set_hl(name, spec)
  vim.api.nvim_set_hl(0, name, spec)
end

-- ----------------------------------------------------------------------
-- Highlights + guicursor (dynamic cursor palette per mode)
-- ----------------------------------------------------------------------

---@private
local function apply_base_highlights()
  local C = M._cfg.colors
  set_hl("CursorNormal",  C.CursorNormal)
  set_hl("CursorInsert",  C.CursorInsert)
  set_hl("CursorVisual",  C.CursorVisual)
  set_hl("CursorReplace", C.CursorReplace)

  set_hl("CursorLineN",   C.CursorLineN)
  set_hl("CursorLineI",   C.CursorLineI)
  set_hl("CursorLineV",   C.CursorLineV)
  set_hl("CursorLineR",   C.CursorLineR)

  set_hl("CursorLineNr",  C.CursorLineNr)
  set_hl("LineNrDim",     C.LineNrDim)

  set_hl("IndentScope",   C.IndentScope)

  set_hl("YankFlash",     C.YankFlash)
  set_hl("PutFlash",      C.PutFlash)

  set_hl("SignColError",   C.SignColError)
  set_hl("SignColWarn",    C.SignColWarn)
  set_hl("SignColInfo",    C.SignColInfo)
  set_hl("SignColHint",    C.SignColHint)
  set_hl("SignColNeutral", C.SignColNeutral)

  set_hl("NormalTerm",     C.TermNormal)
  set_hl("CursorLineTerm", C.TermCursorLine)

  set_hl("CursorWord",     C.CursorWord)
  set_hl("MatchParen",     C.MatchParen)
end

---@private
local function apply_guicursor()
  local function set_gc(spec)
    return pcall(vim.api.nvim_set_option_value, "guicursor", spec, { scope = "global" })
  end

  local preferred = table.concat({
    "n-v-c:block-CursorNormal",
    "i-ci:ver25-CursorInsert",
    "r-cr:hor20-CursorReplace",
    "o:hor50-CursorNormal",
  }, ",")

  local fallback = table.concat({
    "n-v-c:block",
    "i-ci:ver25",
    "r-cr:hor20",
    "o:hor50",
  }, ",")

  if set_gc(preferred) then return end
  if set_gc(fallback) then return end
  vim.cmd( "set guicursor&")
end

-- ----------------------------------------------------------------------
-- Mode-aware CursorLine tint (winhighlight)
-- ----------------------------------------------------------------------

---@private
---@param mode string
local function set_active_window_line_tint(mode)
  local map = {
    n = "CursorLineN",
    v = "CursorLineV",
    V = "CursorLineV",
    ["\22"] = "CursorLineV", -- CTRL-V (visual block)
    i = "CursorLineI",
    R = "CursorLineR",
    r = "CursorLineR",
    c = "CursorLineN",
  }
  local hl = map[mode] or "CursorLineN"

  local wh = "CursorLine:" .. hl .. ",CursorLineNr:CursorLineNr,LineNr:LineNrDim"
  if vim.wo.cursorcolumn then
    wh = wh .. ",CursorColumn:CursorLine"
  end
  vim.wo.winhighlight = wh
  vim.wo.cursorline = true
  vim.wo.cursorlineopt = "both"
end

-- ----------------------------------------------------------------------
-- Highlight helpers (0.9–0.11 compatibility)
-- ----------------------------------------------------------------------

--- High-level range (0.11+) / compat (0.9–0.10) / extmark fallback

---@param buf integer  -- target buffer (0 = current)
---@param ns integer   -- namespace id
---@param hl string    -- highlight group name
---@param srow integer -- start row (0-based, inclusive)
---@param erow integer -- end row (0-based, inclusive)
---@param priority integer|nil
local function highlight_full_lines(buf, ns, hl, srow, erow, priority)
  if erow < srow then return end
  priority = priority or 50

  -- Preferred on Neovim >= 0.11
  if vim.hl and type(vim.hl.range) == "function" then
    -- inclusive=true makes the end position inclusive; {erow,0} covers the whole line
    vim.hl.range(buf, ns, hl, { srow, 0 }, { erow, 0 }, { inclusive = true, priority = priority })
    return
  end

  -- Neovim 0.9–0.10
  if vim.highlight and type(vim.highlight.range) == "function" then
    vim.highlight.range(buf, ns, hl, { srow, 0 }, { erow, 0 }, { inclusive = true, priority = priority })
    return
  end

  -- Fallback: per-line extmarks with hl_eol to fill the whole line
  for l = srow, erow do
    vim.api.nvim_buf_set_extmark(buf, ns, l, 0, {
      end_row = l,
      end_col = 0,      -- with hl_eol=true this highlights to end-of-line
      hl_group = hl,
      hl_eol = true,
      priority = priority,
    })
  end
end

---@param buf integer
---@param ns integer
---@param hl string
---@param srow integer
---@param scol integer
---@param erow integer
---@param ecol integer
---@param priority integer|nil
local function highlight_range(buf, ns, hl, srow, scol, erow, ecol, priority)
  priority = priority or 80
  if vim.hl and type(vim.hl.range) == "function" then
    vim.hl.range(buf, ns, hl, { srow, scol }, { erow, ecol }, { inclusive = true, priority = priority })
    return
  end
  if vim.highlight and type(vim.highlight.range) == "function" then
    vim.highlight.range(buf, ns, hl, { srow, scol }, { erow, ecol }, { inclusive = true, priority = priority })
    return
  end
  vim.api.nvim_buf_set_extmark(buf, ns, srow, scol, {
    end_row = erow,
    end_col = ecol,
    hl_group = hl,
    priority = priority,
  })
end


-- ----------------------------------------------------------------------
-- Indent-scope highlight (current block only, viewport-limited)
-- ----------------------------------------------------------------------

local NS_INDENT = vim.api.nvim_create_namespace("ExpIndentScope")

---@private
local function update_indent_scope()
  if not M._cfg.enable_indent_scope then return end
  if is_large_file() then
    vim.api.nvim_buf_clear_namespace(0, NS_INDENT, 0, -1)
    return
  end

  local bufnr = 0
  local cur = vim.api.nvim_win_get_cursor(0)
  local row = cur[1]       -- 1-based
  local topl = vim.fn.line("w0")
  local botl = vim.fn.line("w$")
  local lines = vim.api.nvim_buf_get_lines(bufnr, topl - 1, botl, false)

  local ts = vim.bo.tabstop
  local function indent_of(s)
    local n, col = 0, 0
    for i = 1, #s do
      local ch = s:sub(i, i)
      if ch == " " then
        col = col + 1
      elseif ch == "\t" then
        col = col + (ts - (col % ts))
      else
        break
      end
      n = n + 1
    end
    return col, n
  end

  local curline = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
  local curindent = indent_of(curline)

  if curline:match("^%s*$") then
    vim.api.nvim_buf_clear_namespace(bufnr, NS_INDENT, 0, -1)
    return
  end

  local function line_indent_at(idx)
    local s = lines[idx] or ""
    if s:match("^%s*$") then return -1 end
    return indent_of(s)
  end

  local rel_cur = row - topl + 1
  local up, down = rel_cur, rel_cur
  while up > 1 and line_indent_at(up - 1) >= curindent do up = up - 1 end
  while down < #lines and line_indent_at(down + 1) >= curindent do down = down + 1 end

  vim.api.nvim_buf_clear_namespace(bufnr, NS_INDENT, 0, -1)
  local start_row = topl + up   - 2  -- 0-based inclusive
  local end_row   = topl + down - 2  -- 0-based inclusive
  highlight_full_lines(bufnr, NS_INDENT, "IndentScope", start_row, end_row, 50)
end

-- ----------------------------------------------------------------------
-- Breadcrumbs in winbar (repo-relative path + symbol context if possible)
-- ----------------------------------------------------------------------

---@private
---@return string|nil
local function ts_symbol_path()
  -- Require Treesitter core + convenience utils; bail out gracefully if missing
  local ok_ts, tsmod = pcall(require, "vim.treesitter")
  if not ok_ts or not tsmod then return nil end
  local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
  if not ok_utils then return nil end

  ---@type TSNode|nil
  local node = tsu.get_node_at_cursor()
  if not node then return nil end
  ---@cast node TSNode  -- narrow: from TSNode|nil to TSNode

  ---@type string[]
  local wanted = {
    "function_declaration",
    "function_definition",
    "method_declaration",
    "method_definition",
    "class_declaration",
    "class_specifier",
    "struct_specifier",
    "interface_declaration",
    "module_declaration",
    "namespace_definition",
    "impl_item",     -- Rust
    "block",         -- last resort
  }

  ---@type string[]
  local names = {}

  --- Keep `u` optional because `:parent()` returns TSNode?
  ---@type TSNode?
  local u = node
  while u do
    local t = u:type()

    -- membership test
    local keep = false
    for _, w in ipairs(wanted) do
      if t == w then keep = true; break end
    end

    if keep then
      -- `get_node_text` expects a non-nil node; `u` is TSNode? but inside this branch it is non-nil
      ---@cast u TSNode
      local text = vim.treesitter.get_node_text(u, 0) or ""
      text = text:gsub("\n.*", ""):gsub("^%s+", "")
      text = text:gsub("%b()", "()")
      text = text:gsub("{.*", "{…}")
      if #text > 0 then table.insert(names, 1, text) end
    end

    -- advance; parent may be nil
    local parent = u:parent()
    if not parent or parent == u then break end
    u = parent
  end

  if #names == 0 then return nil end
  return table.concat(names, " → ")
end

---@private
local function lsp_current_function()
  local s = vim.b.lsp_current_function
  if type(s) == "string" and #s > 0 then return s end
  return nil
end

---@private
local function update_winbar()
  if not M._cfg.enable_breadcrumbs then return end
  local path = vim.api.nvim_buf_get_name(0)
  local rel = repo_relative(path)
  local ctx = lsp_current_function() or ts_symbol_path()

  ---@type string[]
  local parts
  if ctx and #ctx > 0 then
    parts = { rel, " ⟩ ", ctx }
  else
    parts = { rel }
  end

  local line = table.concat(parts, "")
  line = ellipsize_middle(line, M._cfg.breadcrumbs_max_len)
  vim.wo.winbar = " " .. line
end

-- ----------------------------------------------------------------------
-- Yank/Put flash (visual acknowledgement)
-- ----------------------------------------------------------------------

local NS_FLASH = vim.api.nvim_create_namespace("ExpFlash")

---@private
---@param group Str
---@param ms Int
local function flash_changed_region(group, ms)
  local bufnr = 0
  local srow, scol = unpack(vim.api.nvim_buf_get_mark(bufnr, "["))
  local erow, ecol = unpack(vim.api.nvim_buf_get_mark(bufnr, "]"))
  if srow == 0 or erow == 0 then return end
  srow = srow - 1; erow = erow - 1
  vim.api.nvim_buf_clear_namespace(bufnr, NS_FLASH, 0, -1)

  highlight_range(bufnr, NS_FLASH, group, srow, scol, erow, math.max(ecol, 0), 90)

  local uv = vim.uv or vim.loop
  local timer = uv.new_timer()
  if not timer then return end
  ---@cast timer uv.uv_timer_t  -- help LuaLS
  timer:start(ms, 0, function()
    timer:stop()
    timer:close()
    vim.schedule(function()
      if vim.api.nvim_buf_is_loaded(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, NS_FLASH, 0, -1)
      end
    end)
  end)
end

---@private
local function setup_yank_put_flash()
  if M._cfg.enable_yank_flash then
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = vim.api.nvim_create_augroup("ExpFlashYank", { clear = true }),
      callback = function()
        vim.highlight.on_yank({ higroup = "YankFlash", timeout = 150, on_visual = true })
      end,
      desc = "Flash yanked text region",
    })
  end

  if M._cfg.enable_put_flash and M._cfg.map_put_flash then
    local function paste_and_flash(which)
      return function()
        vim.api.nvim_feedkeys(which, "n", false)
        vim.schedule(function()
          flash_changed_region("PutFlash", 160)
        end)
      end
    end
    vim.keymap.set("n", "p", paste_and_flash("p"), { noremap = true, silent = true, desc = "Paste (flash region)" })
    vim.keymap.set("n", "P", paste_and_flash("P"), { noremap = true, silent = true, desc = "Paste before (flash region)" })
  end
end

-- ----------------------------------------------------------------------
-- SignColumn severity tint (per window)
-- ----------------------------------------------------------------------

---@private
local function apply_signcolumn_tint()
  if not M._cfg.enable_signcolumn_tint then return end
  local diags = vim.diagnostic.get(0)
  if #diags == 0 then
    local wh = vim.wo.winhighlight
    wh = (wh == "" and "" or (wh .. ",")):gsub("SignColumn:[^,%s]+,", "")
    vim.wo.winhighlight = wh .. "SignColumn:SignColNeutral"
    return
  end
  local worst = worst_diag_severity(diags)
  local map = {
    [DiagLevel.ERROR] = "SignColError",
    [DiagLevel.WARN]  = "SignColWarn",
    [DiagLevel.INFO]  = "SignColInfo",
    [DiagLevel.HINT]  = "SignColHint",
  }
  local grp = map[worst] or "SignColNeutral"
  local wh = vim.wo.winhighlight
  wh = (wh == "" and "" or (wh .. ",")):gsub("SignColumn:[^,%s]+,", "")
  vim.wo.winhighlight = wh .. "SignColumn:" .. grp
end

-- ----------------------------------------------------------------------
-- Diff indicators with context peek (gitsigns integration if available)
-- ----------------------------------------------------------------------

---@private
local function setup_diff_peek()
  if not M._cfg.enable_diff_peek then return end
  local ok, gs = pcall(require, "gitsigns")
  if not ok then
    local function no_gs()
      vim.notify("Diff peek requires gitsigns.nvim", vim.log.levels.INFO)
    end
    vim.keymap.set({ "n" }, "gh", no_gs, { desc = "Git hunk peek (install gitsigns)" })
    return
  end
  vim.keymap.set("n", "gh", function()
    if gs.preview_hunk_inline then
      gs.preview_hunk_inline()
    else
      gs.preview_hunk()
    end
  end, { desc = "Git hunk peek" })
end

-- ----------------------------------------------------------------------
-- Terminal buffers palette
-- ----------------------------------------------------------------------

---@private
local function setup_term_palette()
  if not M._cfg.enable_terminal_palette then return end
  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("ExpTermPalette", { clear = true }),
    callback = function()
      vim.wo.winhighlight = "Normal:NormalTerm,CursorLine:CursorLineTerm,CursorLineNr:CursorLineNr,LineNr:LineNrDim"
      vim.wo.cursorline = true
      vim.wo.cursorlineopt = "line"
    end,
    desc = "Apply terminal-specific palette",
  })
end

-- ----------------------------------------------------------------------
-- Insert submode colors (Insert vs Replace) via ModeChanged
-- ----------------------------------------------------------------------

---@private
local function setup_mode_changed()
  if not M._cfg.enable_insert_submode_colors then return end
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = vim.api.nvim_create_augroup("ExpModeTint", { clear = true }),
    callback = function(ev) ---@param ev {new_mode?:string, old_mode?:string}
      local nm = (ev and ev.new_mode) or vim.fn.mode(1)
      set_active_window_line_tint(nm:sub(1, 1))
    end,
    desc = "Tint CursorLine per mode",
  })
  set_active_window_line_tint(vim.fn.mode(1):sub(1, 1))
end

-- ----------------------------------------------------------------------
-- Current-word underline (not full background)
-- ----------------------------------------------------------------------

local NS_CWORD = vim.api.nvim_create_namespace("ExpCurrentWord")

---@private
local function setup_current_word()
  if not M._cfg.enable_current_word then return end
  local grp = vim.api.nvim_create_augroup("ExpCurrentWord", { clear = true })

  local function clear_match()
    if vim.w._exp_cword_id then
      pcall(vim.fn.matchdelete, vim.w._exp_cword_id)
      vim.w._exp_cword_id = nil
    end
    vim.api.nvim_buf_clear_namespace(0, NS_CWORD, 0, -1)
  end

  local function update()
    clear_match()
    if vim.fn.mode():find("i") then return end
    local w = vim.fn.expand("<cword>")
    if #w < 2 then return end
    local pat = "\\V\\<" .. vim.fn.escape(w, "\\") .. "\\>"
    vim.w._exp_cword_id = vim.fn.matchadd("CursorWord", pat)
  end

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    group = grp, callback = update, desc = "Underline current word",
  })
  vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave" }, {
    group = grp, callback = clear_match, desc = "Clear current-word underline",
  })
end

-- ----------------------------------------------------------------------
-- MatchParen blink (use showmatch for a subtle flash)
-- ----------------------------------------------------------------------

---@private
local function setup_matchparen()
  vim.opt.showmatch = true
  vim.opt.matchtime = 2 -- tenths of a second; ~200ms blink
end

-- ----------------------------------------------------------------------
-- Winbar updates + scope recalculation triggers
-- ----------------------------------------------------------------------

---@private
local function setup_view_updates()
  local grp = vim.api.nvim_create_augroup("ExpViewUpdates", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "WinScrolled" }, {
    group = grp,
    callback = function()
      update_winbar()
      update_indent_scope()
    end,
    desc = "Update winbar and indent scope on movement/scroll",
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = grp,
    callback = function()
      apply_base_highlights()
      set_active_window_line_tint(vim.fn.mode(1):sub(1, 1))
    end,
    desc = "Reapply experimental highlights after colorscheme changes",
  })
end

-- ----------------------------------------------------------------------
-- Diagnostic-driven SignColumn tint updates
-- ----------------------------------------------------------------------

---@private
local function setup_diag_tint()
  if not M._cfg.enable_signcolumn_tint then return end
  vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("ExpDiagTint", { clear = true }),
    callback = apply_signcolumn_tint,
    desc = "Tint SignColumn based on worst diagnostic severity",
  })
end

-- ----------------------------------------------------------------------
-- Public API
-- ----------------------------------------------------------------------

---@param opts ExpOptions|nil
---@return nil
function M.setup(opts)
  if opts then
    for k, v in pairs(opts) do
      if k == "colors" and type(v) == "table" then
        for ck, cv in pairs(v) do
          M._cfg.colors[ck] = cv
        end
      else
        ---@diagnostic disable-next-line: assign-type-mismatch
        M._cfg[k] = v
      end
    end
  end

  --apply_base_highlights()
  --apply_guicursor()
  setup_mode_changed()
  setup_view_updates()
  setup_yank_put_flash()
  setup_term_palette()
  setup_matchparen()
  setup_current_word()
  setup_diag_tint()
  setup_diff_peek()

  vim.schedule(function()
    update_winbar()
    update_indent_scope()
    apply_signcolumn_tint()
  end)
end

-- Auto-run with defaults on require
M.setup()

return M
