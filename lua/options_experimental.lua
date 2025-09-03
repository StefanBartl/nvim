---@module 'options_experimental'
--- Experimental UI/UX enhancements for Neovim focusing on visual focus, feedback,
--- and gentle guidance while editing. This module is self-contained and relies
--- only on stock Neovim APIs; it optionally integrates with common plugins
--- (Treesitter, gitsigns) when available.
---
--- Each feature flag below enables an isolated UI/UX capability. Disabling a
--- feature will cleanly revert its effects (e.g., clearing extmarks, removing
--- winbar text, or undoing temporary highlights). All toggles are safe to
--- change at runtime (e.g., via user commands).
---
--- Placement:   lua/options_experimental.lua
--- Initialize:  require("options_experimental")  -- from your options/init file
---
--- Type informations for LSP ('lua_ls' / 'emmylua') ar moved to `nvim/lua/types/options_experimental`

local M = {}

-- ----------------------------------------------------------------------
-- Configuration
-- ----------------------------------------------------------------------

--- Central feature toggles and visual palette for the module.
--- You can override individual fields before calling any setup/apply function.
---@type OptionsExperimentalConfig
M._cfg = {
	-- Structural block highlighting around the cursor line.
	-- Note: if disabled, the visual block guidance is not shown. If a bug was
	-- previously present, consider re-enabling after applying the range fix.
	enable_indent_scope = false,

	-- Show compact breadcrumbs (project-relative path + optional symbol path)
	-- in the window winbar for normal editing windows. Popup/picker/floating UIs
	-- are skipped to avoid layout conflicts (e.g., E36: Not enough room).
	enable_breadcrumbs = true,

	-- Briefly flash the region that was just yanked (copied).
	enable_yank_flash = true,

	-- Briefly flash the region that was just pasted (put).
	enable_put_flash = true,

	-- Install safe, non-recursive mappings for `p`/`P` to guarantee the paste
	-- flash even across linewise/charwise variations and visual replace puts.
	map_put_flash = true,

	-- Apply a subtle SignColumn tint based on the worst diagnostic severity in
	-- the current buffer to reduce visual noise and focus attention consistently.
	enable_signcolumn_tint = true,

	-- Ensure terminal buffers (with termguicolors) visually align with the UI.
	-- Typically normalizes g:terminal_color_* and CursorLine in terminal windows.
	enable_terminal_palette = true,

	-- Adapt selected highlights (e.g., CursorLine background, guicursor tweaks)
	-- in response to mode changes (Insert/Replace/Visual/etc.) for quick feedback.
	enable_insert_submode_colors = true,

	-- Highlight the “current word” under the cursor and (optionally) its exact
	-- matches in the visible viewport. Intended as a low-noise local aid.
	enable_current_word = true,

	-- If gitsigns is present, provide a lightweight “peek” of the nearest hunk
	-- (e.g., when holding a modifier or via a command). This remains inert if
	-- gitsigns is not installed.
	enable_diff_peek = true,

	-- File-size threshold (in KiB) above which expensive visuals are throttled or
	-- disabled to keep editing responsive for large files.
	large_file_kb = 5000,

	-- Maximum length for the winbar breadcrumb string. When exceeded, the middle
	-- of the path is ellipsized to keep the most relevant ends visible.
	breadcrumbs_max_len = 80,

	-- Declarative highlight palette. Colors/styles can be freely adjusted to
	-- match your colorscheme; unspecified keys fall back to defaults.
	colors = {
		-- Cursor per mode (used through custom groups referenced by 'guicursor')
		CursorNormal   = { bg = "#ffcc00", fg = "#1e1e1e" }, -- normal: amber block
		CursorInsert   = { bg = "#5fd7ff", fg = "#1e1e1e" }, -- insert: cyan bar
		CursorVisual   = { bg = "#ff5f87", fg = "#1e1e1e" }, -- visual: pink block
		CursorReplace  = { bg = "#ff0000", fg = "#1e1e1e" }, -- replace: red underline

		-- CursorLine per mode (applied via winhighlight on ModeChanged)
		CursorLineN    = { bg = "#2a2e36" },
		CursorLineI    = { bg = "#24313a" },
		CursorLineV    = { bg = "#322b3a" },
		CursorLineR    = { bg = "#3a2323" },

		-- Line numbers
		CursorLineNr   = { fg = "#ffd75f", bold = true },
		LineNrDim      = { fg = "#5a6374" },

		-- Indent scope (current block) background/underline
		IndentScope    = { bg = "#2f3440" },

		-- Short-lived flash regions
		YankFlash      = { bg = "#3e5f2a" },
		PutFlash       = { bg = "#2a4d6b" },

		-- SignColumn tints by worst diagnostic
		SignColError   = { bg = "#3a2323" },
		SignColWarn    = { bg = "#3a3623" },
		SignColInfo    = { bg = "#22333e" },
		SignColHint    = { bg = "#1f2f2a" },
		SignColNeutral = { bg = "NONE" },

		-- Terminal palette (buffer-local)
		TermNormal     = { bg = "#151a1f" },
		TermCursorLine = { bg = "#20262d" },

		-- Current word and matching parenthesis
		CursorWord     = { underline = true }, -- underline-only, no background
		MatchParen     = { bg = "#3b4048", bold = true },
	},

	---@type WinbarSkipRules
	winbar_skip = {
		only_normal_buffers = true, -- skip if buftype ~= "" (term/prompt/help/etc.)
		skip_floating       = true, -- skip floating windows
		min_height          = 2,    -- need space for content + winbar
		buftypes            = { "nofile", "prompt", "terminal", "quickfix", "help", "acwrite" },
		filetypes           = {
			-- pickers/dashboards
			"TelescopePrompt", "TelescopeResults", "fzf", "fzf-lua", "snacks_picker", "alpha", "dashboard", "starter",
			-- explorers/sidebars
			"neo-tree", "neo-tree-popup", "NvimTree", "oil",
			-- outlines/troubles
			"aerial", "Outline", "trouble", "Trouble",
			-- notifications/tool UIs
			"noice", "notify", "lazy", "mason", "LspInfo",
			-- git UIs
			"fugitive", "fugitiveblame", "NeogitStatus", "octo", "git", "gitcommit", "lazygit",
			-- dap UIs
			"dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches", "dap-repl", "dapui_console",
			-- misc
			"help", "man", "qf", "checkhealth", "undotree", "which-key", "spectre_panel", "spectre_replace",
		},
		name_patterns       = {
			"^oil://", "^term://", "^man://",
			".*[\\/]neo%-tree[\\/].*", ".*[\\/]NvimTree[\\/].*", ".*[\\/]lazy[\\/].*", ".*[\\/]mason[\\/].*",
		},
	},

	---@type IndentScopeSkipRules
	indent_scope_skip = {
		-- Safety: only apply to "normal" buffers (buftype == "" or nil). This alone
		-- already excludes most plugin UIs and transient helper buffers.
		only_normal_buffers = true,

		-- Do not highlight in floating windows (popup UIs, prompts, etc.).
		skip_floating = true,

		-- Common non-file buftypes that should never be block-highlighted.
		buftypes = {
			"nofile", "prompt", "terminal", "quickfix", "help", "acwrite",
		},

		-- Curated list of popular UI/Picker/Sidebar/Panel filetypes. Prune this if
		-- too aggressive; the defaults are intentionally conservative.
		filetypes = {
			-- File explorers
			"neo-tree", "neo-tree-popup", "NvimTree", "oil",

			-- Fuzzy finders / pickers / dashboards
			"fzf", "fzf-lua", "TelescopePrompt", "TelescopeResults",
			"snacks_picker", "snacks_dashboard", "alpha", "dashboard", "starter",

			-- Outline / symbols / aerial / trouble
			"aerial", "Outline", "trouble", "Trouble",

			-- Notifications / messaging
			"noice", "notify",

			-- Package / tool UIs
			"lazy", "mason", "LspInfo",

			-- Git UIs
			"fugitive", "fugitiveblame", "NeogitStatus", "octo", "git", "gitcommit", "lazygit",

			-- DAP UIs
			"dapui_scopes", "dapui_breakpoints", "dapui_stacks",
			"dapui_watches", "dap-repl", "dapui_console",

			-- Misc helpers
			"help", "man", "qf", "checkhealth", "undotree", "which-key",
			"spectre_panel", "spectre_replace", "neo-term",
			"minipick", "mini.files",
		},

		-- Path/name patterns (Lua patterns) for special cases:
		--  * works across OS (use [\\/] to match slash on Windows/macOS/Linux)
		--  * covers scheme-like names (oil://, term://, man://, etc.)
		name_patterns = {
			"^oil://", "^term://", "^man://",
			".*[\\/]neo%-tree[\\/].*", ".*[\\/]NvimTree[\\/].*",
			".*[\\/]lazy[\\/].*", ".*[\\/]mason[\\/].*",
		},
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

--- Shared membership helper
--- @param lst string[]|nil
--- @param val string|nil
--- @return boolean
local function _in_list(lst, val)
	if not lst or not val or val == "" then return false end
	for _, x in ipairs(lst) do
		if x == val then return true end
	end
	return false
end

--- Decide if winbar should be skipped for current window/buffer.
--- @param bufnr integer
--- @return boolean
local function winbar_should_skip(bufnr)
	local cfg = M._cfg.winbar_skip
	if not cfg then return false end

	local wc = vim.api.nvim_win_get_config(0)
	if cfg.skip_floating and wc and wc.relative and wc.relative ~= "" then
		return true
	end

	local height = vim.api.nvim_win_get_height(0)
	if cfg.min_height and height < cfg.min_height then
		return true
	end

	local bt = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })

	if cfg.only_normal_buffers and bt and bt ~= "" then return true end
	if _in_list(cfg.buftypes, bt) or _in_list(cfg.filetypes, ft) then return true end

	local name = vim.api.nvim_buf_get_name(bufnr)
	if name and name ~= "" then
		for _, pat in ipairs(cfg.name_patterns or {}) do
			local ok, matched = pcall(function() return name:match(pat) ~= nil end)
			if ok and matched then return true end
		end
	end

	return false
end

-- ----------------------------------------------------------------------
-- Highlights + guicursor (dynamic cursor palette per mode)
-- ----------------------------------------------------------------------

---@private
local function apply_base_highlights()
	local C = M._cfg.colors
	set_hl("CursorNormal", C.CursorNormal)
	set_hl("CursorInsert", C.CursorInsert)
	set_hl("CursorVisual", C.CursorVisual)
	set_hl("CursorReplace", C.CursorReplace)

	set_hl("CursorLineN", C.CursorLineN)
	set_hl("CursorLineI", C.CursorLineI)
	set_hl("CursorLineV", C.CursorLineV)
	set_hl("CursorLineR", C.CursorLineR)

	set_hl("CursorLineNr", C.CursorLineNr)
	set_hl("LineNrDim", C.LineNrDim)

	set_hl("IndentScope", C.IndentScope)

	set_hl("YankFlash", C.YankFlash)
	set_hl("PutFlash", C.PutFlash)

	set_hl("SignColError", C.SignColError)
	set_hl("SignColWarn", C.SignColWarn)
	set_hl("SignColInfo", C.SignColInfo)
	set_hl("SignColHint", C.SignColHint)
	set_hl("SignColNeutral", C.SignColNeutral)

	set_hl("NormalTerm", C.TermNormal)
	set_hl("CursorLineTerm", C.TermCursorLine)

	set_hl("CursorWord", C.CursorWord)
	set_hl("MatchParen", C.MatchParen)
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
	vim.cmd("set guicursor&")
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

--- Full-line highlight that reliably includes the last line completely.
--- Compatible with Neovim 0.9–0.11+.
--- @param buf integer
--- @param ns integer
--- @param hl string
--- @param srow integer  -- inclusive, 0-based
--- @param erow integer  -- inclusive, 0-based
--- @param priority integer|nil
local function highlight_full_lines(buf, ns, hl, srow, erow, priority)
	if erow < srow then return end
	priority = priority or 50

	local last0 = vim.api.nvim_buf_line_count(buf) - 1
	local has_next = erow < last0
	local end_row, end_col, inclusive

	if has_next then
		-- Use exclusive end at start of NEXT line -> covers full 'erow'
		end_row, end_col, inclusive = erow + 1, 0, false
	else
		-- On physical last line: emulate EOL with a huge column and inclusive end
		end_row, end_col, inclusive = erow, 2147483647, true
	end

	if vim.hl and type(vim.hl.range) == "function" then
		vim.hl.range(buf, ns, hl, { srow, 0 }, { end_row, end_col }, { inclusive = inclusive, priority = priority })
		return
	end
	if vim.highlight and type(vim.highlight.range) == "function" then
		vim.highlight.range(buf, ns, hl, { srow, 0 }, { end_row, end_col }, { inclusive = inclusive, priority = priority })
		return
	end

	-- Fallback: per-line extmarks with hl_eol=true
	for l = srow, erow do
		vim.api.nvim_buf_set_extmark(buf, ns, l, 0, {
			end_row = l,
			end_col = 0, -- hl_eol=true fills to end-of-line
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

--- Decide whether indent-scope highlighting should be skipped for current buffer/window.
--- Covers floating windows, "only normal buffers", buftype/filetype blacklists, and filename patterns.
--- @param bufnr integer
--- @return boolean
local function indent_scope_should_skip(bufnr)
	local cfg = M._cfg.indent_scope_skip
	if not cfg then return false end

	-- 1) Window-level check: floating windows are often UI overlays
	if cfg.skip_floating then
		local wc = vim.api.nvim_win_get_config(0)
		if wc and type(wc) == "table" and wc.relative and wc.relative ~= "" then
			return true
		end
	end

	-- 2) Buffer attributes
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	local bt = vim.api.nvim_get_option_value("buftype", { buf = bufnr })

	-- Safety net: only highlight real files (buftype == ""/nil)
	if cfg.only_normal_buffers then
		if bt and bt ~= "" then
			-- Non-normal buffer (terminal, prompt, help, …)
			return true
		end
	end

	-- Fast membership test
	local function in_list(lst, val)
		if not lst or not val or val == "" then return false end
		for _, x in ipairs(lst) do
			if x == val then return true end
		end
		return false
	end

	if in_list(cfg.buftypes, bt) then return true end
	if in_list(cfg.filetypes, ft) then return true end

	-- 3) Name patterns against absolute buffer name (path or scheme)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name and name ~= "" and cfg.name_patterns then
		for _, pat in ipairs(cfg.name_patterns) do
			-- Use pcall to guard malformed user patterns
			local ok, matched = pcall(function() return name:match(pat) ~= nil end)
			if ok and matched then
				return true
			end
		end
	end

	return false
end


local NS_INDENT = vim.api.nvim_create_namespace("ExpIndentScope")

---@private

local function update_indent_scope()
	if not M._cfg.enable_indent_scope then return end
	if is_large_file() then
		vim.api.nvim_buf_clear_namespace(0, NS_INDENT, 0, -1)
		return
	end

	local bufnr = 0

	-- Clear and skip on blacklist
	if indent_scope_should_skip(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, NS_INDENT, 0, -1)
		return
	end

	local cur = vim.api.nvim_win_get_cursor(0)
	local row = cur[1] -- 1-based
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
	local start_row = topl + up - 2  -- 0-based inclusive
	local end_row   = topl + down - 2 -- 0-based inclusive
	highlight_full_lines(bufnr, NS_INDENT, "IndentScope", start_row, end_row, 50)
end

-- ----------------------------------------------------------------------
-- Breadcrumbs in winbar (repo-relative path + symbol context if possible)
-- ----------------------------------------------------------------------
--   • Extracts concise symbol names (identifiers) instead of raw node text
--   • Removes the generic “block” fallback to avoid noisy snippets
--   • Keeps LSP fallback (b:lsp_current_function)
--   • Escapes % for winbar (winbar uses statusline-format strings)

---@private
---@return string|nil
local function ts_identifier_of(node)
  -- 1) Named field "name" (common across many grammars)
  local named = node:field("name")
  if named and named[1] then
    local t = vim.treesitter.get_node_text(named[1], 0)
    if t and #t > 0 then return t end
  end

  -- 2) Shallow search for identifier-like node types
  local want = {
    "identifier", "property_identifier", "field_identifier",
    "type_identifier", "name",
  }
  local function in_list(x)
    for _, w in ipairs(want) do if x == w then return true end end
    return false
  end

  local function first_ident(n, depth)
    depth = depth or 0
    if depth > 2 then return nil end -- keep search shallow
    if in_list(n:type()) then
      local t = vim.treesitter.get_node_text(n, 0)
      if t and #t > 0 then return t end
    end
    local cnt = n:child_count()
    for i = 0, cnt - 1 do
      local r = first_ident(n:child(i), depth + 1)
      if r then return r end
    end
    return nil
  end

  local t = first_ident(node, 0)
  if t and #t > 0 then return t end

  -- 3) Last resort: skim the first line for a likely name token
  local raw = (vim.treesitter.get_node_text(node, 0) or ""):gsub("^%s+", ""):gsub("\n.*", "")
  local guess = raw:match("^%w+%s+([%w_]+)%s*%(")
             or raw:match("^%w+%s+([%w_]+)%s*[={:]")
             or raw:match("^([%w_%.:]+)%s*%(")
             or raw:match("^([%w_%.:]+)")
  if guess and #guess > 0 then return guess end
  return nil
end

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
  ---@cast node TSNode

  -- Keep only semantic, named constructs; no generic “block”
  local keep = {
    function_declaration   = true,
    function_definition    = true,
    method_declaration     = true,
    method_definition      = true,
    class_declaration      = true,
    class_specifier        = true,
    struct_specifier       = true,
    interface_declaration  = true,
    module_declaration     = true,
    namespace_definition   = true,
    impl_item              = true, -- Rust
  }

  ---@type string[]
  local names = {}

  ---@type TSNode?
  local u = node
  while u do
    local t = u:type()
    if keep[t] then
      local ident = ts_identifier_of(u)
      if ident and #ident > 0 then
        -- Normalize function/method appearance: append "()" if it looks like a callable
        if t:find("function") or t:find("method") then
          if not ident:find("%)$") then ident = ident:gsub("%s+$", "") .. "()" end
        end
        table.insert(names, 1, ident)
      end
    end
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
---@param s string
---@return string
local function stl_escape(s)
  -- winbar uses statusline-format; escape % to avoid format parsing
  return (s:gsub("%%", "%%%%"))
end

---@private
local function update_winbar()
  if not M._cfg.enable_breadcrumbs then return end
  if winbar_should_skip(0) then
    -- ensure we don't leave stale winbar text in UIs/prompts/floats
    vim.wo.winbar = ""
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  local rel = repo_relative(path)

  -- LSP hint first; if not present, use Treesitter symbol chain
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
  line = stl_escape(line)              -- protect % sequences
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
		vim.keymap.set("n", "P", paste_and_flash("P"),
			{ noremap = true, silent = true, desc = "Paste before (flash region)" })
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
		[vim.diagnostic.severity.ERROR] = "SignColError",
		[vim.diagnostic.severity.WARN]  = "SignColWarn",
		[vim.diagnostic.severity.INFO]  = "SignColInfo",
		[vim.diagnostic.severity.HINT]  = "SignColHint",
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
			vim.schedule(function()
				update_winbar()
				update_indent_scope()
			end)
		end,
		desc = "Update winbar and indent scope on movement/scroll (scheduled)",
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

---@param opts OptionsExperimentalConfig|nil
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

	apply_base_highlights()
	apply_guicursor()
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
