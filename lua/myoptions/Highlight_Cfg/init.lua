---@module 'myoptions.Highlight_Cfg'
--- Visual/UX features and highlight groups. This module:
---   * Applies and maintains highlight groups & winhighlight mappings
---   * Breadcrumbs (winbar) with repo-relative path and symbol context
---   * Indent-scope block highlight (viewport-limited)
---   * Yank/Put flash, SignColumn severity tint, terminal palette
---   * Mode-aware CursorLine tint; optional current-word underline
---   * Optional Gitsigns hunk peek on `gh`
--- It exposes :MyHlSet / :MyHlShow / :MyHlList for runtime changes.

local C         = require("myoptions.config")
local cfg       = C.cfg.highlight
local PathCache = require("myoptions.Highlight_Cfg.path_cache")
local ctx_ok, ctxmod = pcall(require, "myoptions.Highlight_Cfg.breadcrumbs.ctx")

-- Namespaces & groups
local NS_INDENT = vim.api.nvim_create_namespace("myopt_IndentScope")
local NS_FLASH  = vim.api.nvim_create_namespace("myopt_Flash")
local AUG_COLOR = vim.api.nvim_create_augroup("myopt_ColorPersist", { clear = true })
local AUG_WIN   = vim.api.nvim_create_augroup("myopt_PerWindow", { clear = true })
local AUG_MODE  = vim.api.nvim_create_augroup("myopt_Mode", { clear = true })
local AUG_FLASH = vim.api.nvim_create_augroup("myopt_FlashAuto", { clear = true })
local AUG_TERM  = vim.api.nvim_create_augroup("myopt_TermPalette", { clear = true })
local AUG_DIAG  = vim.api.nvim_create_augroup("myopt_DiagTint", { clear = true })
local AUG_CWORD = vim.api.nvim_create_augroup("myopt_CWordAuto", { clear = true })
local AUG_VIEW  = vim.api.nvim_create_augroup("myopt_ViewUpdates", { clear = true })

--- Convert a hex codepoint string (e.g. "F0056") to a UTF-8 char using Neovim API.
--- Returns "" on invalid input.
---@param hex string|nil
---@return string
local function _cp(hex)
	if type(hex) ~= "string" or hex == "" then return "" end
	local n = tonumber(hex, 16)
	if not n then return "" end
	local ok, ch = pcall(vim.fn.nr2char, n)
	return (ok and type(ch) == "string") and ch or ""
end

--- Choose a breadcrumb separator: prefer Nerd Font glyph (single cell), else Unicode fallback.
---@param hex string  -- preferred Nerd Font codepoint in hex, e.g., "F0056"
---@return string     -- separator surrounded by spaces, e.g., "  "
local function nerd_sep_or_fallback(hex)
	local g = _cp(hex)
	-- Accept only single display cell to avoid layout drift in winbar
	if g ~= "" and vim.fn.strdisplaywidth(g) == 1 then
		return " " .. g .. " "
	end
	-- Fallbacks with broad coverage; pick wider arrow on wide terminals
	local wide = (tonumber(vim.o.columns) or 0) >= 100
	return wide and " ⟶ " or " › "
end

-- Example: resolve effective separator from config
---@return string
local function _effective_sep()
  local hc = require("myoptions.config").cfg.highlight
  -- Direct string wins
  if type(hc.breadcrumbs_separator) == "string" and hc.breadcrumbs_separator ~= "" then
    return hc.breadcrumbs_separator
  end
  -- Prefer Nerd Font hex if set, with width check
  return nerd_sep_or_fallback(hc.breadcrumbs_nerd_hex)
end


--- Resolve the separator according to config.
---@return string
local function get_breadcrumb_separator()
	-- 1) explicit string wins
	if type(cfg.breadcrumbs_separator) == "string" and cfg.breadcrumbs_separator ~= "" then
		return cfg.breadcrumbs_separator
	end
	-- 2) nerd hex next
	if type(cfg.breadcrumbs_nerd_hex) == "string" and cfg.breadcrumbs_nerd_hex ~= "" then
		return nerd_sep_or_fallback(cfg.breadcrumbs_nerd_hex)
	end
	-- 3) default
	return " ⟩ "
end

-- Small utils (kept local, pure)
---@param lst string[]|nil
---@param val string|nil
---@return boolean
local function in_list(lst, val)
	if not lst or not val or val == "" then return false end
	for _, x in ipairs(lst) do if x == val then return true end end
	return false
end

---@param s string
---@param max integer
---@return string
local function ellipsize_middle(s, max)
	if #s <= max then return s end
	local head = math.floor((max - 1) / 2)
	local tail = max - head - 1
	return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

---@param s string
---@return string
local function stl_escape(s) return (s:gsub("%%", "%%%%")) end

---@return boolean
local function is_large_file_any()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then return false end
	local ok, st = pcall((vim.uv or vim.loop).fs_stat, name)
	if not ok or not st or not st.size then return false end
	return math.floor(st.size / 1024) > (cfg.large_file_kb or 5000)
end

-- Highlight application
---@return nil
local function apply_highlights()
	for name, spec in pairs(cfg.colors) do
		vim.api.nvim_set_hl(0, name, spec)
	end
end

---@param mode string
---@return nil
local function set_active_window_line_tint(mode)
	local map = {
		n = "CursorLineN",
		v = "CursorLineV",
		V = "CursorLineV",
		["\22"] = "CursorLineV",
		i = "CursorLineI",
		R = "CursorLineR",
		r = "CursorLineR",
		c = "CursorLineN",
	}
	local hl = cfg.enable_insert_submode_colors and (map[mode] or "CursorLineN") or "CursorLine"
	local wh = ("CursorLine:%s,CursorLineNr:CursorLineNr"):format(hl)
	if vim.wo.cursorcolumn then wh = wh .. ",CursorColumn:CursorColumn" end

	-- keep SignColumn mapping if present
	local existing = vim.wo.winhighlight
	if existing and existing ~= "" then
		existing = existing:gsub("CursorLine:[^,%s]+,?", "")
				:gsub("CursorLineNr:[^,%s]+,?", "")
				:gsub("CursorColumn:[^,%s]+,?", "")
				:gsub(",+", ","):gsub("^,", ""):gsub(",$", "")
		if existing ~= "" then wh = existing .. "," .. wh end
	end

	vim.wo.winhighlight = wh
	vim.wo.cursorline = cfg.enable_line
	vim.wo.cursorlineopt = "both"
end

---@return boolean
local function should_enable_column()
	if not cfg.enable_column then return false end
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then return true end
	local ok, st = pcall((vim.uv or vim.loop).fs_stat, name)
	if not ok or not st or not st.size then return true end
	local kb = math.floor(st.size / 1024)
	return kb <= (cfg.min_colored_file_kb or 4096)
end

---@return nil
local function activate_window_hl()
	local m = (vim.fn.mode(1) or "n"):sub(1, 1)
	if should_enable_column() then vim.wo.cursorcolumn = true else vim.wo.cursorcolumn = false end
	set_active_window_line_tint(m)
end

---@return nil
local function deactivate_window_hl()
	vim.wo.cursorline = false
	vim.wo.cursorcolumn = false
	local wh = vim.wo.winhighlight or ""
	wh = wh:gsub("CursorLine:[^,%s]+,?", "")
			:gsub("CursorLineNr:[^,%s]+,?", "")
			:gsub("CursorColumn:[^,%s]+,?", "")
			:gsub(",+", ","):gsub("^,", ""):gsub(",$", "")
	vim.wo.winhighlight = (wh ~= "" and (wh .. ",") or "") .. "CursorLine:Normal,CursorLineNr:LineNr,CursorColumn:Normal"
end

-- Breadcrumbs
---@param bufnr integer
---@return boolean
local function winbar_should_skip(bufnr)
	local rules = cfg.winbar_skip or {}
	local wc = vim.api.nvim_win_get_config(0)
	if rules.skip_floating and wc and wc.relative and wc.relative ~= "" then return true end
	local height = vim.api.nvim_win_get_height(0)
	if rules.min_height and height < rules.min_height then return true end
	local bt = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	if rules.only_normal_buffers and bt and bt ~= "" then return true end
	if in_list(rules.buftypes, bt) or in_list(rules.filetypes, ft) then return true end
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name and name ~= "" then
		for _, pat in ipairs(rules.name_patterns or {}) do
			local ok, matched = pcall(function() return name:match(pat) ~= nil end)
			if ok and matched then return true end
		end
	end
	return false
end

-- Optional TS/LSP fallbacks used only when the ctx module is unavailable
---@return string|nil
local function _lsp_current_function()
  -- very cheap: many LSPs set this buffer variable
  local s = vim.b.lsp_current_function
  if type(s) == "string" and #s > 0 then return s end
  return nil
end

---@return string|nil
local function _ts_symbol_path_fallback()
  -- tiny, safe fallback; not as smart as the ctx module, but avoids globals
  local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
  if not ok_utils then return nil end
  local node = tsu.get_node_at_cursor()
  if not node then return nil end

  local function txt(n)
    local ok, s = pcall(vim.treesitter.get_node_text, n, 0)
    return ok and (s or "") or ""
  end

  local keep = {
    function_declaration   = true, function_definition   = true,
    method_declaration     = true, method_definition     = true,
    class_declaration      = true, class_specifier       = true,
    struct_specifier       = true, interface_declaration = true,
    module_declaration     = true, namespace_definition  = true,
    impl_item              = true,
  }

  local function ident_of(n)
    local named = n:field("name"); if named and named[1] then
      local s = txt(named[1]); if s ~= "" then return s end
    end
    local want = { identifier=true, property_identifier=true, field_identifier=true, type_identifier=true, name=true }
    local function first_ident(m, d)
      d = d or 0; if d > 2 then return nil end
      if want[m:type()] then local s = txt(m); if s ~= "" then return s end end
      local cnt = m:child_count()
      for i = 0, cnt - 1 do
        local r = first_ident(m:child(i), d + 1)
        if r then return r end
      end
      return nil
    end
    local s = first_ident(n, 0)
    if s and #s > 0 then return s end
    local raw = (txt(n):gsub("^%s+", ""):gsub("\n.*", ""))
    return raw:match("^%w+%s+([%w_]+)%s*%(")
        or raw:match("^%w+%s+([%w_]+)%s*[={:]")
        or raw:match("^([%w_%.:]+)%s*%(")
        or raw:match("^([%w_%.:]+)")
  end

  local names, u = {}, node
  while u do
    if keep[u:type()] then
      local id = ident_of(u)
      if id and #id > 0 then
        if u:type():find("function") or u:type():find("method") then
          if not id:find("%)$") then id = id:gsub("%s+$", "") .. "()" end
        end
        table.insert(names, 1, id)
      end
    end
    local p = u:parent(); if not p or p == u then break end
    u = p
  end
  if #names == 0 then return nil end
  return table.concat(names, " → ")
end


---@return nil
local function update_winbar()
  if not cfg.enable_breadcrumbs then vim.wo.winbar = ""; return end
  if winbar_should_skip(0) then vim.wo.winbar = ""; return end

  local path = vim.api.nvim_buf_get_name(0)
  local rel  = PathCache.repo_relative_cached(path)

  -- prefer the modular context builder; fallback to tiny LSP/TS helpers
  local ctx = nil
  if ctx_ok and ctxmod and type(ctxmod._build_context) == "function" then
    ctx = ctxmod._build_context()
  else
    ctx = _lsp_current_function() or _ts_symbol_path_fallback()
  end

  local sep = _effective_sep()  -- deine existierende Separator-Funktion
  local line = (ctx and #ctx > 0) and (rel .. sep .. ctx) or rel
  line = stl_escape(ellipsize_middle(line, cfg.breadcrumbs_max_len or 120))
  vim.wo.winbar = " " .. line
end

-- Indent-scope highlight (viewport-limited)
---@param bufnr integer
---@return boolean
local function indent_scope_should_skip(bufnr)
	local rules = cfg.indent_scope_skip or {}
	if rules.skip_floating then
		local wc = vim.api.nvim_win_get_config(0)
		if wc and type(wc) == "table" and wc.relative and wc.relative ~= "" then return true end
	end
	local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	local bt = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	if rules.only_normal_buffers and bt and bt ~= "" then return true end
	if in_list(rules.buftypes, bt) or in_list(rules.filetypes, ft) then return true end
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name and name ~= "" and rules.name_patterns then
		for _, pat in ipairs(rules.name_patterns) do
			local ok, matched = pcall(function() return name:match(pat) ~= nil end)
			if ok and matched then return true end
		end
	end
	return false
end

--- Highlight full lines reliably (end-of-buffer safe)
---@param buf integer @buffer handle
---@param ns integer  @namespace
---@param hl string   @highlight group
---@param srow integer @0-based inclusive
---@param erow integer @0-based inclusive
---@param priority integer|nil
local function highlight_full_lines(buf, ns, hl, srow, erow, priority)
	if erow < srow then return end
	priority = priority or 50
	local last0 = vim.api.nvim_buf_line_count(buf) - 1
	local has_next = erow < last0
	local end_row, end_col, inclusive
	if has_next then
		end_row, end_col, inclusive = erow + 1, 0, false
	else
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
	for l = srow, erow do
		vim.api.nvim_buf_set_extmark(buf, ns, l, 0,
			{ end_row = l, end_col = 0, hl_group = hl, hl_eol = true, priority = priority })
	end
end

---@return nil
local function update_indent_scope()
	if not cfg.enable_indent_scope or is_large_file_any() then
		vim.api.nvim_buf_clear_namespace(0, NS_INDENT, 0, -1); return
	end
	local bufnr = 0
	if indent_scope_should_skip(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, NS_INDENT, 0, -1); return
	end
	local cur = vim.api.nvim_win_get_cursor(0)
	local row = cur[1]
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
		vim.api.nvim_buf_clear_namespace(bufnr, NS_INDENT, 0, -1); return
	end

	local function line_indent_at(i)
		local s = lines[i] or ""
		if s:match("^%s*$") then return -1 end
		return indent_of(s)
	end

	local rel_cur = row - topl + 1
	local up, down = rel_cur, rel_cur
	while up > 1 and line_indent_at(up - 1) >= curindent do up = up - 1 end
	while down < #lines and line_indent_at(down + 1) >= curindent do down = down + 1 end

	vim.api.nvim_buf_clear_namespace(bufnr, NS_INDENT, 0, -1)
	local start_row = topl + up - 2
	local end_row   = topl + down - 2
	highlight_full_lines(bufnr, NS_INDENT, "IndentScope", start_row, end_row, 50)
end

-- Yank / Put flash
---@param group string
---@param ms integer
---@return nil
local function flash_changed_region(group, ms)
	local bufnr = 0
	local srow, scol = unpack(vim.api.nvim_buf_get_mark(bufnr, "["))
	local erow, ecol = unpack(vim.api.nvim_buf_get_mark(bufnr, "]"))
	if srow == 0 or erow == 0 then return end
	srow = srow - 1; erow = erow - 1
	vim.api.nvim_buf_clear_namespace(bufnr, NS_FLASH, 0, -1)
	local function hl_range(buf, ns, hl, sr, sc, er, ec, prio)
		local ok = (vim.hl and type(vim.hl.range) == "function")
		if ok then
			vim.hl.range(buf, ns, hl, { sr, sc }, { er, ec }, { inclusive = true, priority = prio or 90 }); return
		end
		local ok2 = (vim.highlight and type(vim.highlight.range) == "function")
		if ok2 then
			vim.highlight.range(buf, ns, hl, { sr, sc }, { er, ec }, { inclusive = true, priority = prio or 90 }); return
		end
		vim.api.nvim_buf_set_extmark(buf, ns, sr, sc, { end_row = er, end_col = ec, hl_group = hl, priority = prio or 90 })
	end
	hl_range(bufnr, NS_FLASH, group, srow, math.max(scol, 0), erow, math.max(ecol, 0), 90)
	---@type uv
	local uv = vim.uv or vim.loop
	local timer = uv.new_timer(); if not timer then return end
	---@cast timer uv.uv_timer_t
	timer:start(ms, 0, function()
		timer:stop(); timer:close()
		vim.schedule(function()
			if vim.api.nvim_buf_is_loaded(bufnr) then
				vim.api.nvim_buf_clear_namespace(bufnr, NS_FLASH, 0, -1)
			end
		end)
	end)
end

---@return nil
local function ensure_yank_put_flash()
	vim.api.nvim_clear_autocmds({ group = AUG_FLASH })
	if cfg.enable_yank_flash then
		vim.api.nvim_create_autocmd("TextYankPost", {
			group = AUG_FLASH,
			callback = function() vim.highlight.on_yank({ higroup = "YankFlash", timeout = 150, on_visual = true }) end,
			desc = "Flash yanked text region",
		})
	end
	for _, lhs in ipairs({ "p", "P" }) do pcall(vim.keymap.del, "n", lhs) end
	if cfg.enable_put_flash and cfg.map_put_flash then
		local function paste_and_flash(which)
			return function()
				vim.api.nvim_feedkeys(which, "n", false)
				vim.schedule(function() flash_changed_region("PutFlash", 160) end)
			end
		end
		vim.keymap.set("n", "p", paste_and_flash("p"), { noremap = true, silent = true, desc = "Paste (flash region)" })
		vim.keymap.set("n", "P", paste_and_flash("P"),
			{ noremap = true, silent = true, desc = "Paste before (flash region)" })
	end
end

-- SignColumn tint
---@return nil
local function apply_signcolumn_tint()
	if not cfg.enable_signcolumn_tint then return end
	local diags = vim.diagnostic.get(0)
	local wh = vim.wo.winhighlight or ""
	wh = (wh == "" and "" or (wh .. ",")):gsub("SignColumn:[^,%s]+,", "")
	if #diags == 0 then
		vim.wo.winhighlight = wh .. "SignColumn:SignColNeutral"; return
	end
	local worst
	for _, d in ipairs(diags) do if not worst or d.severity < worst then worst = d.severity end end
	local sev = vim.diagnostic.severity
	local grp = (worst == sev.ERROR and "SignColError")
			or (worst == sev.WARN and "SignColWarn")
			or (worst == sev.INFO and "SignColInfo")
			or (worst == sev.HINT and "SignColHint")
			or "SignColNeutral"
	vim.wo.winhighlight = wh .. "SignColumn:" .. grp
end

---@return nil
local function ensure_diag_tint_autocmd()
	vim.api.nvim_clear_autocmds({ group = AUG_DIAG })
	if cfg.enable_signcolumn_tint then
		vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
			group = AUG_DIAG, callback = apply_signcolumn_tint, desc = "Tint SignColumn based on worst diagnostic",
		})
	else
		local wh = vim.wo.winhighlight or ""
		wh = wh:gsub("SignColumn:[^,%s]+,?", ""):gsub(",+", ","):gsub("^,", ""):gsub(",$", "")
		vim.wo.winhighlight = wh
	end
end

-- Terminal palette
---@return nil
local function ensure_term_palette_autocmd()
	vim.api.nvim_clear_autocmds({ group = AUG_TERM })
	if cfg.enable_terminal_palette then
		vim.api.nvim_create_autocmd("TermOpen", {
			group = AUG_TERM,
			callback = function()
				vim.wo.winhighlight = "Normal:TermNormal,CursorLine:TermCursorLine,CursorLineNr:CursorLineNr,LineNr:LineNr"
				vim.wo.cursorline = true
				vim.wo.cursorlineopt = "line"
			end,
			desc = "Apply terminal-specific palette",
		})
	end
end

-- Current-word underline
---@module 'myopts.current_word'
--- Window-local underline for the word under the cursor using matchaddpos()

--- wenn config erwünscht comments weiter unten in funktion implementieren um cg
-- ---@class CWordConfig
-- ---@field enable_current_word boolean      -- master switch
-- ---@field min_len integer                  -- minimum word length to underline
-- ---@field hl string                        -- highlight group to use (will be created if missing)
-- ---@field priority integer                 -- match priority
--
-- local cfg = cfg or { enable_current_word = true, min_len = 2, hl = "CursorWord", priority = 10 }

-- ---@type integer
-- local AUG_CWORD = AUG_CWORD or vim.api.nvim_create_augroup("MyCurrentWord", { clear = true })

---@return nil
local function ensure_current_word_autocmd()
  -- clear any previous autocommands for this group
  vim.api.nvim_clear_autocmds({ group = AUG_CWORD })

  --- Clear the previous window-local match, if any.
  ---@return nil
  local function clear_match()
    -- match ids are window-local; store on vim.w
    if vim.w._myopt_cword_id then
      pcall(vim.fn.matchdelete, vim.w._myopt_cword_id)
      vim.w._myopt_cword_id = nil
    end
  end

  if cfg.enable_current_word then
    --- Update the underline for the current word at the cursor.
    --- This is window-local and affects only the single occurrence that contains the cursor.
    ---@return nil
    local function update()
      clear_match()

      -- do nothing in insert mode (cheap check)
      if vim.fn.mode():find("i") then return end

      local word = vim.fn.expand("<cword>")
      if #word < 2 then return end -- (cfg.min_len or 2)  if min word len ist wanted

      -- current cursor position: lnum is 1-based, cbyte is 0-based (byte index)
      local pos = vim.api.nvim_win_get_cursor(0)
      local lnum, cbyte = pos[1], pos[2]
      local line = vim.api.nvim_get_current_line()

      -- build a very nomagic, word-boundary-anchored pattern for this exact word
      local pat = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"

      -- iterate matches on the current line and pick the one that contains the cursor byte index
      local start = 0                ---@type integer
      local s_at, e_at = nil, nil    ---@type integer?, integer?
      while true do
        -- matchstrpos() returns: {matched_text, start_byte, end_byte}; start_byte = -1 if not found
        local _, s, e = unpack(vim.fn.matchstrpos(line, pat, start))
        if s == -1 then break end
        if s <= cbyte and cbyte < e then
          s_at, e_at = s, e
          break
        end
        start = s + 1
      end
      if not s_at then return end

      local col1 = s_at + 1                 -- convert to 1-based column for matchaddpos()
      local len  = e_at - s_at

      local hl = "CursorWord" -- cfg: or cfg.hl_word
      if vim.fn.hlexists(hl) == 0 then
        vim.api.nvim_set_hl(0, hl, { underline = true })
      end

      -- add a single-position, window-local match
      vim.w._myopt_cword_id = vim.fn.matchaddpos(hl, { { lnum, col1, len } }, 10) -- cfg: cfg.priority or 10  (10 is priority)
    end

    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      group = AUG_CWORD,
      callback = update,
      desc = "Underline current word (window-local)",
    })

    vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave" }, {
      group = AUG_CWORD,
      callback = clear_match,
      desc = "Clear current-word underline",
    })
  else
    -- feature disabled: ensure the window-local match is removed
    local _ = pcall(function()
      if vim.w._myopt_cword_id then
        vim.fn.matchdelete(vim.w._myopt_cword_id)
        vim.w._myopt_cword_id = nil
      end
    end)
  end
end


--- Resolve new mode robustly without triggering LuaLS "undefined-field" warnings.
--- This avoids direct field access like `vim.v.event.new_mode` by using rawget/pcall.
--- Fallback order:
---   1) try to read vim.v.event["new_mode"] (if host populates it)
---   2) parse from ev.match, which is "<old>:<new>"
---   3) fallback to current mode via vim.fn.mode(1)
---@param ev ModeChangedEvent|nil
---@return string  -- single-char mode like "n","i","v","R","c"
local function _resolve_new_mode(ev)
	-- Step 1: attempt to read from vim.v.event in a type-safe way
	local nm ---@type string|nil
	local ok, event_tbl = pcall(function() return vim.v.event end)
	if ok and type(event_tbl) == "table" then
		-- Use rawget to avoid LuaLS "undefined-field" diagnostics on dynamic keys
		local maybe = rawget(event_tbl, "new_mode")
		if type(maybe) == "string" and #maybe > 0 then
			nm = maybe
		end
	end

	-- Step 2: parse from ev.match ("old:new")
	if not nm and ev and type(ev.match) == "string" then
		nm = ev.match:match(":(.+)$")
	end

	-- Step 3: fallback to current mode
	nm = nm or vim.fn.mode(1)

	-- Normalize to the first mode character used by our tint mapping
	return (nm or "n"):sub(1, 1)
end


-- Mode changes + view updates + color persist
---@return nil
local function ensure_mode_changed_autocmd()
	vim.api.nvim_clear_autocmds({ group = AUG_MODE })
	if cfg.enable_insert_submode_colors then
		vim.api.nvim_create_autocmd("ModeChanged", {
			group = AUG_MODE,
			---@param ev ModeChangedEvent
			callback = function(ev)
				set_active_window_line_tint(_resolve_new_mode(ev))
			end,
			desc = "Tint CursorLine per mode",
		})
		-- initial apply
		set_active_window_line_tint(_resolve_new_mode(nil))
	else
		activate_window_hl()
	end
end

---@return nil
local function ensure_color_persist_autocmd()
	vim.api.nvim_clear_autocmds({ group = AUG_COLOR })
	if cfg.color_persist then
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = AUG_COLOR,
			callback = function()
				apply_highlights()
				activate_window_hl()
				update_winbar()
				update_indent_scope()
			end,
			desc = "Re-apply highlight groups and refresh UI after colorscheme changes",
		})
	end
end

---@return nil
local function ensure_view_updates()
	vim.api.nvim_clear_autocmds({ group = AUG_VIEW })
	vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "WinScrolled" }, {
		group = AUG_VIEW,
		callback = function()
			vim.schedule(function()
				update_winbar(); update_indent_scope()
			end)
		end,
		desc = "Update winbar and indent scope on movement/scroll",
	})
end

-- Gitsigns peek
---@return nil
local function ensure_diff_peek_keymap()
	pcall(vim.keymap.del, "n", "gh")
	if not cfg.enable_diff_peek then return end
	local ok, gs = pcall(require, "gitsigns")
	if not ok then
		vim.keymap.set("n", "gh", function() vim.notify("Diff peek requires gitsigns.nvim", vim.log.levels.INFO) end,
			{ desc = "Git hunk peek (install gitsigns)" })
		return
	end
	vim.keymap.set("n", "gh", function()
		if gs.preview_hunk_inline then gs.preview_hunk_inline() else gs.preview_hunk() end
	end, { desc = "Git hunk peek" })
end

-- Public re-apply on config change (used by :MyHlSet)
---@param key string
---@return nil
local function after_set(key)
	if key:match("^colors%.") then
		apply_highlights(); activate_window_hl(); return
	end
	if key == "enable_line" or key == "enable_column" or key == "min_colored_file_kb" then
		activate_window_hl(); return
	end
	if key == "color_persist" then
		ensure_color_persist_autocmd(); return
	end
	if key == "enable_yank_flash" or key == "enable_put_flash" or key == "map_put_flash" then
		ensure_yank_put_flash(); return
	end
	if key == "enable_signcolumn_tint" then
		ensure_diag_tint_autocmd(); return
	end
	if key == "enable_terminal_palette" then
		ensure_term_palette_autocmd(); return
	end
	if key == "enable_current_word" then
		ensure_current_word_autocmd(); return
	end
	if key == "enable_insert_submode_colors" then
		ensure_mode_changed_autocmd(); return
	end
	if key == "enable_breadcrumbs" or key == "breadcrumbs_max_len" then
		update_winbar(); return
	end
	if key == "breadcrumbs_separator" or key == "breadcrumbs_nerd_hex" then
		update_winbar(); return
	end
	if key:match("^breadcrumbs_ctx%.")
			or key == "breadcrumbs_separator"
			or key == "breadcrumbs_nerd_hex"
			or key == "breadcrumbs_max_len"
			or key == "enable_breadcrumbs" then
		update_winbar(); return
	end
	if key == "enable_indent_scope" then
		update_indent_scope(); return
	end
	if key == "enable_diff_peek" then
		ensure_diff_peek_keymap(); return
	end
	if key == "large_file_kb" then
		update_indent_scope(); return
	end
end

-- Public entry for this module
---@return nil
local function enable()
	apply_highlights()
	ensure_color_persist_autocmd()
	ensure_mode_changed_autocmd()
	ensure_yank_put_flash()
	ensure_diag_tint_autocmd()
	ensure_term_palette_autocmd()
	ensure_current_word_autocmd()
	ensure_view_updates()
	ensure_diff_peek_keymap()
	PathCache.ensure_autocmds()

	-- Activate base window mapping
	vim.api.nvim_clear_autocmds({ group = AUG_WIN })
	vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" },
		{ group = AUG_WIN, callback = activate_window_hl, desc = "Activate highlights for active window" })
	vim.api.nvim_create_autocmd({ "WinLeave" },
		{ group = AUG_WIN, callback = deactivate_window_hl, desc = "Dim highlights for inactive windows" })
	vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
		group = AUG_WIN,
		desc = "Re-check column highlight on size changes",
		callback = function() if vim.wo.cursorline then activate_window_hl() end end,
	})

	-- Subscribe to after-set events
	C.on_after_set("highlight", after_set)

	-- Register commands
	require("myoptions.commands").register_highlight_commands({
		after_set  = after_set,
		show_table = cfg,
		names      = { set = "MyHighlightSet", show = "MyHighlightShow", list = "MyHighlightList" },
	})

	require("myoptions.commands").register_highlight_debug_command({
		mod = require("myoptions.Highlight_Cfg.breadcrumbs.ctx"),
		sepfn = get_breadcrumb_separator,
		names = { debug = "MyHighlightDebugCtx" },
	})
end

return { enable = enable }
