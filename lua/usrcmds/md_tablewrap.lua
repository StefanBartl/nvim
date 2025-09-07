---@module 'md.tablewrap'
--- Wrap and reflow Markdown tables to fit the current window's text area.
--- Features:
---   * Auto-width (default) vs. equal-width mode; min/max per-column widths.
---   * UTF-8 safe wrapping; shared continuation rows; header kept to one line.
---   * Respects gutters via getwininfo().textoff; configurable inner/outer padding.
---   * Scope control: current table vs. all tables in the buffer (toggle + commands).
---   * Optional on-save reflow for Markdown buffers (toggle via command or config).
---
--- Commands:
---   :MDTableWrap[!]             Reflow (scope depends on CFG.wrap_all_default; ! forces)
---   :MDTableWrapAll[!]          Reflow all tables in current buffer (! forces)
---   :MDTableWrapAllToggle       Toggle default scope between current/all tables
---   :MDTableOnSaveToggle        Toggle on-save reflow for Markdown buffers
---   :MDTableWidthToggle         Toggle between auto-width and equal-width
---   :MDTableAutoWidth           Set auto-width mode
---   :MDTableEqualWidth          Set equal-width mode
---   :MDTableSetMaxWidth [n]     Set max column width; omit/0/nil/false to unset
---   :MDTableSetMinWidth [n]     Set min column width (>=1); omit/0/nil/false -> 1
---   :MDTableWidthInfo           Show current width settings and toggles
---
--- Setup (defaults shown):
---   require('md.tablewrap').setup({
---     inner_pad        = 1,     -- spaces inside cells (per side)
---     outer_left       = 3,     -- reserved columns (left margin)
---     outer_right      = 3,     -- reserved columns (right margin)
---     auto_width       = true,  -- true: natural widths; false: equal widths
---     max_col_width    = nil,   -- integer cap per column; nil/false to disable
---     min_col_width    = 20,    -- preferred minimum width per column (>=1)
---     wrap_all_default = false, -- if true, :MDTableWrap operates on all tables by default
---     on_save_enabled  = false, -- if true, reflow all tables on save in Markdown buffers
---   })

local M = {}

---@type MDTableWrapConfig
local CFG = {
	inner_pad = 1,
	outer_left = 3,
	outer_right = 3,
	auto_width = true,
	max_col_width = nil,
	min_col_width = 20,
	wrap_all_default = false,
	on_save_enabled = false,
}

local AUGROUP = "MDTableWrapAuto"

-- Display width with multibyte/ambiguous width awareness.
---@param s string
---@return integer
local function dispw(s) return vim.fn.strdisplaywidth(s) end

-- Heuristic: table-like line (or separator).
---@param line string
---@return boolean
local function is_table_like(line)
	if not line or line == "" then return false end
	if line:match("^%s*```") then return false end
	local pc = select(2, line:gsub("|", ""))
	if pc < 2 then return false end
	if line:match("^%s*|%s*[:%- ]-|") then return true end
	return line:match("%S") ~= nil
end

-- Markdown separator: | --- | :---: | --: |
---@param line string
---@return boolean
local function is_separator_line(line)
	if not is_table_like(line) then return false end
	local body = line:gsub("^%s*|", ""):gsub("|%s*$", "")
	for cell in (body .. "|"):gmatch("([^|]*)|") do
		local t = vim.trim(cell)
		if t == "" then return false end
		if not t:match("^:?-+:?$") then return false end
	end
	return true
end

---@param line string
---@return string[] cells
local function split_cells(line)
	local body = line:gsub("^%s*|", ""):gsub("|%s*$", "")
	---@type string[]
	local out = {}
	for cell in (body .. "|"):gmatch("([^|]*)|") do
		out[#out + 1] = vim.trim(cell)
	end
	return out
end

---@param sep_line string
---@param ncols integer
---@return MDColumnAlign[]
local function parse_aligns(sep_line, ncols)
	---@type MDColumnAlign[]
	local aligns = {}
	if not sep_line or sep_line == "" then
		for _ = 1, ncols do aligns[#aligns + 1] = { left = true, right = false } end
		return aligns
	end
	local cells = split_cells(sep_line)
	for i = 1, ncols do
		local c = vim.trim(cells[i] or "---")
		local left = c:sub(1, 1) == ":"
		local right = c:sub(#c, #c) == ":"
		aligns[#aligns + 1] = { left = left, right = right }
	end
	return aligns
end

---@param buf integer
---@param lnum integer
---@return MDWrapBounds|nil
local function find_table_bounds(buf, lnum)
	local total = vim.api.nvim_buf_line_count(buf)
	if lnum < 1 or lnum > total then return nil end
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	if not is_table_like(lines[lnum]) then return nil end
	local s = lnum
	while s > 1 and is_table_like(lines[s - 1]) do s = s - 1 end
	local e = lnum
	while e < total and is_table_like(lines[e + 1]) do e = e + 1 end
	local first = lines[s]
	local fp = first:find("|", 1, true) or 1
	local indent_str = first:sub(1, fp - 1)
	local indent_col = dispw(indent_str)
	return { start_lnum = s, end_lnum = e, indent_col = indent_col, indent_str = indent_str }
end

---@param buf integer
---@return MDWrapBounds[] bounds_list
local function find_all_table_bounds(buf)
	local total = vim.api.nvim_buf_line_count(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	---@type MDWrapBounds[]
	local out = {}
	local i = 1
	while i <= total do
		if is_table_like(lines[i]) then
			local s = i
			while i + 1 <= total and is_table_like(lines[i + 1]) do i = i + 1 end
			local e = i
			local first = lines[s]
			local fp = first:find("|", 1, true) or 1
			local indent_str = first:sub(1, fp - 1)
			local indent_col = dispw(indent_str)
			out[#out + 1] = { start_lnum = s, end_lnum = e, indent_col = indent_col, indent_str = indent_str }
		end
		i = i + 1
	end
	return out
end

---@param lines string[]
---@return MDTableParse
local function parse_table_lines(lines)
	local sep_idx
	for i, L in ipairs(lines) do
		if is_separator_line(L) and not sep_idx then sep_idx = i end
	end
	local ncols = 0
	---@type string[]|nil
	local header = nil
	---@type string[][]
	local body = {}
	for i, L in ipairs(lines) do
		if i ~= sep_idx then
			local cells = split_cells(L)
			if sep_idx and i < sep_idx and not header then
				header = cells
			else
				body[#body + 1] = cells
			end
			if #cells > ncols then ncols = #cells end
		end
	end
	local aligns = parse_aligns(sep_idx and lines[sep_idx] or "", ncols)
	local function pad_to(cols, row) while #row < cols do row[#row + 1] = "" end end
	if header then pad_to(ncols, header) end
	for _, r in ipairs(body) do pad_to(ncols, r) end
	return { header = header, body = body, has_separator = sep_idx ~= nil, aligns = aligns, ncols = ncols }
end

---@return integer text_area_cols
local function get_text_area_width()
	local info_list = vim.fn.getwininfo(vim.api.nvim_get_current_win())
	local info = (type(info_list) == "table" and info_list[1]) and info_list[1] or nil
	local win_width = info and tonumber(info.width) or vim.api.nvim_win_get_width(0)
	local textoff = info and tonumber(info.textoff) or 0
	return win_width - textoff
end

---@param indent_col integer
---@param ncols integer
---@param pad integer
---@return integer|nil content_total
local function compute_content_total(indent_col, ncols, pad)
	local text_area = get_text_area_width()
	local available = text_area - indent_col - CFG.outer_left - CFG.outer_right
	if available <= 0 then return nil end
	local pipes = ncols + 1
	local content_total = available - pipes - (2 * pad * ncols)
	if content_total < ncols then return nil end
	return content_total
end

---@param parsed MDTableParse
---@param cap integer|nil
---@param minw integer|nil
---@return integer[] widths
local function measure_natural_col_widths(parsed, cap, minw)
	---@type integer[]
	local w = {}
	for i = 1, parsed.ncols do w[i] = 1 end
	local function acc(row)
		for i = 1, parsed.ncols do
			local s = row[i] or ""
			local d = dispw(s)
			if d > w[i] then w[i] = d end
		end
	end
	if parsed.header then acc(parsed.header) end
	for _, r in ipairs(parsed.body) do acc(r) end
	if minw and minw >= 1 then
		for i = 1, #w do if w[i] < minw then w[i] = minw end end
	end
	if cap and cap >= 1 then
		for i = 1, #w do if w[i] > cap then w[i] = cap end end
	end
	return w
end

---@param ncols integer
---@param content_total integer
---@param cap integer|nil
---@param minw integer|nil
---@return integer[] widths
local function equal_widths(ncols, content_total, cap, minw)
	local base = math.floor(content_total / ncols)
	local leftover = content_total % ncols
	---@type integer[]
	local w = {}
	for i = 1, ncols do
		local v = base + ((i <= leftover) and 1 or 0)
		if minw and minw >= 1 then v = math.max(v, minw) end
		if cap and cap >= 1 then v = math.min(v, cap) end
		if v < 1 then v = 1 end
		w[i] = v
	end
	return w
end

---@param widths integer[]
---@return integer
local function sum_widths(widths)
	local s = 0
	for _, v in ipairs(widths) do s = s + (tonumber(v) or 0) end
	return s
end

---@param widths integer[]
---@param target integer
---@param lower_bound integer|nil
---@return integer[] widths
local function shrink_proportionally(widths, target, lower_bound)
	local lb = math.max(1, lower_bound or 1)
	local n = #widths
	local sum = 0
	for _, v in ipairs(widths) do sum = sum + v end
	if sum <= target then return widths end

	---@type number[]
	local scaled = {}
	---@type integer[]
	local res = {}
	local new_sum = 0
	for i, v in ipairs(widths) do
		local x = (v * target) / sum
		scaled[i] = x
		local iv = math.max(lb, math.floor(x))
		res[i] = iv
		new_sum = new_sum + iv
	end

	local remainder = target - new_sum
	if remainder ~= 0 then
		local idx = {}
		for i = 1, n do idx[i] = i end
		table.sort(idx, function(a, b)
			return (scaled[a] - math.floor(scaled[a])) > (scaled[b] - math.floor(scaled[b]))
		end)
		local k = 1
		while remainder > 0 do
			local i = idx[k]; res[i] = res[i] + 1; remainder = remainder - 1; k = (k % n) + 1
		end
		while remainder < 0 do
			local i = idx[k]
			if res[i] > lb then
				res[i] = res[i] - 1; remainder = remainder + 1
			end
			k = (k % n) + 1
			if k == 1 and remainder < 0 then break end
		end
	end
	return res
end

---@param indent_col integer
---@param parsed MDTableParse
---@return MDWrapPlan|nil
local function compute_plan(indent_col, parsed)
	local pad = CFG.inner_pad
	local content_total = compute_content_total(indent_col, parsed.ncols, pad)
	if not content_total then return nil end

	---@type integer[]
	local widths
	if CFG.auto_width then
		widths = measure_natural_col_widths(parsed, CFG.max_col_width, CFG.min_col_width or 1)
	else
		widths = equal_widths(parsed.ncols, content_total, CFG.max_col_width, CFG.min_col_width or 1)
	end

	local sumw = sum_widths(widths)
	if sumw <= content_total then
		return { col_widths = widths, padding = pad }
	end

	local minw = CFG.min_col_width and math.max(1, CFG.min_col_width) or 1
	local min_sum = minw * parsed.ncols
	if min_sum <= content_total then
		widths = shrink_proportionally(widths, content_total, minw)
	else
		widths = shrink_proportionally(widths, content_total, 1)
	end

	return { col_widths = widths, padding = pad }
end

---@param token string
---@param width integer
---@return string[]
local function break_token_utf8(token, width)
	---@type string[]
	local parts = {}
	local i, total = 0, vim.fn.strchars(token)
	while i < total do
		local chunk, w = "", 0
		while i < total do
			local ch = vim.fn.strcharpart(token, i, 1)
			local nw = dispw(chunk .. ch)
			if nw > width and chunk ~= "" then break end
			if nw > width and chunk == "" then
				chunk = ch; i = i + 1; break
			end
			chunk = chunk .. ch
			w = nw
			i = i + 1
			if w == width then break end
		end
		parts[#parts + 1] = chunk
	end
	if #parts == 0 then parts = { "" } end
	return parts
end

---@param text string
---@param width integer
---@return string[]
local function wrap_cell(text, width)
	if width <= 0 then return { text } end
	---@type string[]
	local words, lines = {}, {}
	for w in text:gmatch("%S+") do words[#words + 1] = w end
	if #words == 0 then return { "" } end
	local current = ""
	local function push()
		lines[#lines + 1] = current; current = ""
	end
	local function fits(a, b)
		local sep = (a == "") and "" or " "; return dispw(a .. sep .. b) <= width
	end
	for _, w in ipairs(words) do
		if current == "" then
			if dispw(w) <= width then
				current = w
			else
				for _, piece in ipairs(break_token_utf8(w, width)) do
					if dispw(piece) == width then lines[#lines + 1] = piece else current = piece end
				end
			end
		else
			if fits(current, w) then
				current = current .. " " .. w
			else
				push()
				if dispw(w) <= width then
					current = w
				else
					local pieces = break_token_utf8(w, width)
					for i, piece in ipairs(pieces) do if i < #pieces then lines[#lines + 1] = piece else current = piece end end
				end
			end
		end
	end
	if current ~= "" then push() end
	if #lines == 0 then lines = { "" } end
	return lines
end

---@param s string
---@param width integer
---@param align MDColumnAlign
---@param pad integer
---@return string
local function pad_cell(s, width, align, pad)
	local content_w = dispw(s)
	local rest = math.max(0, width - content_w)
	local left_extra, right_extra = 0, rest
	if align.left and align.right then
		left_extra = math.floor(rest / 2); right_extra = rest - left_extra
	elseif align.right and not align.left then
		left_extra = rest; right_extra = 0
	end
	return string.rep(" ", pad)
			.. string.rep(" ", left_extra) .. s .. string.rep(" ", right_extra)
			.. string.rep(" ", pad)
end

---@param n integer
---@param ch string
---@return string
local function repn(n, ch) return string.rep(ch, math.max(0, n)) end

---@param aligns MDColumnAlign[]
---@param widths integer[]
---@return string
local function build_separator_row(aligns, widths)
	---@type string[]
	local parts = {}
	for i, w in ipairs(widths) do
		local left, right = aligns[i].left, aligns[i].right
		local core = repn(math.max(3, w), "-")
		if left and not right then core = ":" .. core:sub(2) end
		if right and not left then core = core:sub(1, #core - 1) .. ":" end
		if left and right then core = ":" .. core:sub(2, #core - 1) .. ":" end
		parts[#parts + 1] = " " .. core .. " "
	end
	return "|" .. table.concat(parts, "|") .. "|"
end

---@param row string[]
---@param widths integer[]
---@param aligns MDColumnAlign[]
---@return string
local function format_single_row(row, widths, aligns)
	---@type string[]
	local parts = {}
	for c, w in ipairs(widths) do
		parts[#parts + 1] = pad_cell(row[c] or "", math.max(1, w), aligns[c] or { left = true, right = false }, CFG
			.inner_pad)
	end
	return "|" .. table.concat(parts, "|") .. "|"
end

---@param rows string[][]
---@param widths integer[]
---@param aligns MDColumnAlign[]
---@return string[]
local function format_body_rows(rows, widths, aligns)
	---@type string[]
	local out = {}
	for _, row in ipairs(rows) do
		---@type string[][]
		local wrapped_per_col = {}
		local maxh = 1
		for c, s in ipairs(row) do
			local w = math.max(1, widths[c] or 1)
			wrapped_per_col[c] = wrap_cell(s, w)
			if #wrapped_per_col[c] > maxh then maxh = #wrapped_per_col[c] end
		end
		for k = 1, maxh do
			---@type string[]
			local parts = {}
			for c, w in ipairs(widths) do
				local text = wrapped_per_col[c][k] or ""
				parts[#parts + 1] = pad_cell(text, w, aligns[c] or { left = true, right = false }, CFG.inner_pad)
			end
			out[#out + 1] = "|" .. table.concat(parts, "|") .. "|"
		end
	end
	return out
end

---@param buf integer
---@param _ integer unused win
---@param bounds MDWrapBounds
---@return boolean
local function reformat_table(buf, _, bounds)
	local lines = vim.api.nvim_buf_get_lines(buf, bounds.start_lnum - 1, bounds.end_lnum, false)
	if #lines == 0 then return false end
	local parsed = parse_table_lines(lines)
	if parsed.ncols == 0 then return false end

	local plan = compute_plan(bounds.indent_col, parsed)
	if not plan then
		vim.notify("MDTableWrap: Not enough horizontal space to format table.", vim.log.levels.WARN)
		return false
	end

	local widths, aligns = plan.col_widths, parsed.aligns
	---@type string[]
	local formatted = {}

	if parsed.header then
		formatted[#formatted + 1] = format_single_row(parsed.header, widths, aligns)
		formatted[#formatted + 1] = build_separator_row(aligns, widths)
	end

	local body_lines = format_body_rows(parsed.body, widths, aligns)
	for _, L in ipairs(body_lines) do formatted[#formatted + 1] = L end

	for i = 1, #formatted do
		formatted[i] = bounds.indent_str .. formatted[i]
	end

	vim.api.nvim_buf_set_lines(buf, bounds.start_lnum - 1, bounds.end_lnum, false, formatted)
	return true
end

---@param buf integer
---@param bounds MDWrapBounds
---@return boolean
local function table_has_overflow(buf, bounds)
	local text_area = get_text_area_width()
	local avail = text_area - bounds.indent_col - CFG.outer_left - CFG.outer_right
	if avail <= 0 then return true end
	local lines = vim.api.nvim_buf_get_lines(buf, bounds.start_lnum - 1, bounds.end_lnum, false)
	for _, L in ipairs(lines) do
		local fp = L:find("|", 1, true) or 1
		local tail = L:sub(fp)
		if dispw(tail) > avail then return true end
	end
	return false
end

---@param mode MDMode
local function do_wrap_current(mode)
	local buf, win = 0, 0
	local lnum = vim.api.nvim_win_get_cursor(win)[1]
	local bounds = find_table_bounds(buf, lnum)
	if not bounds then
		vim.notify("MDTableWrap: Cursor is not on a Markdown table.", vim.log.levels.WARN)
		return
	end
	if mode ~= "force" and not table_has_overflow(buf, bounds) then
		vim.notify("MDTableWrap: No overflow detected; nothing to do.", vim.log.levels.INFO)
		return
	end
	vim.cmd("undojoin")
	if reformat_table(buf, win, bounds) then
		vim.notify("MDTableWrap: Table formatted.", vim.log.levels.INFO)
	end
end

---@param mode MDMode
local function do_wrap_all(mode)
	local buf, win = 0, 0
	local bounds_list = find_all_table_bounds(buf)
	if #bounds_list == 0 then
		vim.notify("MDTableWrap: No tables found.", vim.log.levels.INFO)
		return
	end
	-- Process from bottom to top to avoid shifting ranges while editing.
	table.sort(bounds_list, function(a, b) return a.start_lnum > b.start_lnum end)
	local changed = 0
	for _, b in ipairs(bounds_list) do
		if mode == "force" or table_has_overflow(buf, b) then
			vim.cmd("undojoin")
			if reformat_table(buf, win, b) then changed = changed + 1 end
		end
	end
	if changed > 0 then
		vim.notify(string.format("MDTableWrap: Formatted %d table(s).", changed), vim.log.levels.INFO)
	else
		vim.notify("MDTableWrap: Nothing to format.", vim.log.levels.INFO)
	end
end

local function show_info()
	local m = string.format(
		"auto_width=%s, max_col_width=%s, min_col_width=%s, inner_pad=%d, outer_left=%d, outer_right=%d, wrap_all_default=%s, on_save_enabled=%s",
		tostring(CFG.auto_width),
		CFG.max_col_width and tostring(CFG.max_col_width) or "nil",
		CFG.min_col_width and tostring(CFG.min_col_width) or "nil",
		CFG.inner_pad, CFG.outer_left, CFG.outer_right,
		tostring(CFG.wrap_all_default),
		tostring(CFG.on_save_enabled)
	)
	vim.notify("MDTableWrap: " .. m, vim.log.levels.INFO, { title = "MDTableWrap" })
end

---@param arg string
local function set_max_width_from_string(arg)
	local a = vim.trim(arg or "")
	if a == "" or a == "nil" or a == "false" or a == "0" then
		CFG.max_col_width = nil
		vim.notify("MDTableWrap: max_col_width unset (nil).", vim.log.levels.INFO)
		return
	end
	local n = tonumber(a)
	if not n or n < 1 then
		vim.notify("MDTableWrap: invalid max_col_width (need integer >= 1).", vim.log.levels.ERROR)
		return
	end
	CFG.max_col_width = math.floor(n)
	vim.notify("MDTableWrap: max_col_width = " .. tostring(CFG.max_col_width), vim.log.levels.INFO)
end

---@param arg string
local function set_min_width_from_string(arg)
	local a = vim.trim(arg or "")
	if a == "" or a == "nil" or a == "false" or a == "0" then
		CFG.min_col_width = 1
		vim.notify("MDTableWrap: min_col_width set to 1 (unset).", vim.log.levels.INFO)
		return
	end
	local n = tonumber(a)
	if not n or n < 1 then
		vim.notify("MDTableWrap: invalid min_col_width (need integer >= 1).", vim.log.levels.ERROR)
		return
	end
	CFG.min_col_width = math.floor(n)
	vim.notify("MDTableWrap: min_col_width = " .. tostring(CFG.min_col_width), vim.log.levels.INFO)
end

local function clear_autocmds()
	pcall(vim.api.nvim_del_augroup_by_name, AUGROUP)
end

local function ensure_autocmds()
	clear_autocmds()
	if not CFG.on_save_enabled then return end
	local id = vim.api.nvim_create_augroup(AUGROUP, { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = id,
		-- Using FileType check at runtime ensures compatibility with various markdown extensions.
		callback = function(args)
			local ft = vim.bo[args.buf].filetype
			if ft == "markdown" then
				-- On save we reflow all tables in 'detect' mode (no force).
				do_wrap_all("detect")
			end
		end,
		desc = "MDTableWrap: reflow all tables on save (Markdown only).",
	})
end

--- Public API

---@param cfg MDTableWrapConfig|nil
function M.setup(cfg)
	if cfg then
		if cfg.inner_pad ~= nil then CFG.inner_pad = tonumber(cfg.inner_pad) or CFG.inner_pad end
		if cfg.outer_left ~= nil then CFG.outer_left = tonumber(cfg.outer_left) or CFG.outer_left end
		if cfg.outer_right ~= nil then CFG.outer_right = tonumber(cfg.outer_right) or CFG.outer_right end
		if cfg.auto_width ~= nil then CFG.auto_width = not not cfg.auto_width end
		if cfg.max_col_width ~= nil then
			local n = tonumber(cfg.max_col_width); CFG.max_col_width = (n and n >= 1) and math.floor(n) or nil
		end
		if cfg.min_col_width ~= nil then
			local n = tonumber(cfg.min_col_width); CFG.min_col_width = (n and n >= 1) and math.floor(n) or 15
		end
		if cfg.wrap_all_default ~= nil then CFG.wrap_all_default = not not cfg.wrap_all_default end
		if cfg.on_save_enabled ~= nil then CFG.on_save_enabled = not not cfg.on_save_enabled end
	end

	ensure_autocmds()

	vim.api.nvim_create_user_command("MDTableWrap", function(opts)
		local mode = opts.bang and "force" or "detect"
		if CFG.wrap_all_default then do_wrap_all(mode) else do_wrap_current(mode) end
	end, { desc = "Reflow Markdown tables (scope: current or all via toggle). Use ! to force.", bang = true })

	vim.api.nvim_create_user_command("MDTableWrapAll", function(opts)
		local mode = opts.bang and "force" or "detect"
		do_wrap_all(mode)
	end, { desc = "Reflow all Markdown tables in the current buffer. Use ! to force.", bang = true })

	vim.api.nvim_create_user_command("MDTableWrapAllToggle", function()
		CFG.wrap_all_default = not CFG.wrap_all_default
		vim.notify("MDTableWrap: wrap_all_default = " .. tostring(CFG.wrap_all_default), vim.log.levels.INFO)
	end, { desc = "Toggle default scope for :MDTableWrap between current table and all tables." })

	vim.api.nvim_create_user_command("MDTableOnSaveToggle", function()
		CFG.on_save_enabled = not CFG.on_save_enabled
		ensure_autocmds()
		vim.notify("MDTableWrap: on_save_enabled = " .. tostring(CFG.on_save_enabled), vim.log.levels.INFO)
	end, { desc = "Toggle reflow of all tables on save (Markdown buffers only)." })

	vim.api.nvim_create_user_command("MDTableWidthToggle", function()
		CFG.auto_width = not CFG.auto_width
		vim.notify("MDTableWrap: auto_width = " .. tostring(CFG.auto_width), vim.log.levels.INFO)
	end, { desc = "Toggle between auto-width and equal-width modes." })

	vim.api.nvim_create_user_command("MDTableAutoWidth", function()
		CFG.auto_width = true
		vim.notify("MDTableWrap: auto_width = true", vim.log.levels.INFO)
	end, { desc = "Set auto-width mode." })

	vim.api.nvim_create_user_command("MDTableEqualWidth", function()
		CFG.auto_width = false
		vim.notify("MDTableWrap: auto_width = false", vim.log.levels.INFO)
	end, { desc = "Set equal-width mode." })

	vim.api.nvim_create_user_command("MDTableSetMaxWidth", function(opts)
		set_max_width_from_string(opts.args or "")
	end, { desc = "Set max column width in cells; omit/0/nil/false to unset.", nargs = "?" })

	vim.api.nvim_create_user_command("MDTableSetMinWidth", function(opts)
		set_min_width_from_string(opts.args or "")
	end, { desc = "Set min column width in cells; omit/0/nil/false -> 1.", nargs = "?" })

	vim.api.nvim_create_user_command("MDTableWidthInfo", function() show_info() end,
		{ desc = "Show current width settings and toggles." })
end

M.setup()

return M
