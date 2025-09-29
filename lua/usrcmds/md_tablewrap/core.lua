---@module 'usrcmds.md_tablewrap.core'
--- Core logic for Markdown table detection, parsing, width planning, and reformatting.
--- This module is UI-agnostic: no notifications, no user commands, pure return values.
--- All functions report errors via (ok=false, err="...") tuples where applicable.

local api, fn         = vim.api, vim.fn

-- Local references to hot functions to reduce table lookup overhead in tight loops.
local strdisplaywidth = fn.strdisplaywidth
local strcharpart     = fn.strcharpart
local strchars        = fn.strchars

---@param s string
---@return integer
local function dispw(s)
	-- Use cached reference; ensure nil-safe input
	return strdisplaywidth(s or "")
end

-- Dependency injection hook for measuring the window text area (in columns).
-- Defaults to a getwininfo()-based provider; tests can inject their own.
---@type fun(win:integer):integer
local TEXT_AREA_PROVIDER

---@return integer
local function default_text_area_cols(win)
	local info_list = fn.getwininfo(win)
	if type(info_list) == "table" and info_list[1] then
		local width   = tonumber(info_list[1].width) or api.nvim_win_get_width(win)
		local textoff = tonumber(info_list[1].textoff) or 0
		return width - textoff
	end
	return api.nvim_win_get_width(win)
end

TEXT_AREA_PROVIDER = default_text_area_cols

---@param parsed MDTableParse
---@return integer[] para_need
local function measure_paragraph_widths(parsed)
	local n = parsed.ncols
	local p = {}
	for i = 1, n do p[i] = 0 end
	for _, row in ipairs(parsed.body) do
		for i = 1, n do
			local d = dispw(row[i] or "")
			if d > p[i] then p[i] = d end
		end
	end
	return p
end

--- proportional expansion with optional per-column caps
---@param widths integer[]    -- current widths
---@param remainder integer   -- total extra columns to distribute (>=0)
---@param weights number[]    -- non-negative weights; zero means not eligible
---@param cap integer|nil     -- optional cap per column (content width)
---@return integer[] widths
local function expand_proportionally(widths, remainder, weights, cap)
	if remainder <= 0 then return widths end
	local n, elig, wsum = #widths, {}, 0
	for i = 1, n do
		local eligible = (weights[i] or 0) > 0 and (not cap or widths[i] < cap)
		elig[i] = eligible and 1 or 0
		if eligible then wsum = wsum + (weights[i] or 0) end
	end
	if wsum == 0 then return widths end

	-- First pass: floor shares
	local added, frac = {}, {}
	local used = 0
	for i = 1, n do
		if elig[i] == 1 then
			local share = (weights[i] / wsum) * remainder
			local add = math.floor(share)
			if cap then add = math.min(add, cap - widths[i]) end
			if add < 0 then add = 0 end
			added[i] = add
			frac[i]  = share - add
			used     = used + add
		else
			added[i], frac[i] = 0, 0
		end
	end

	-- Second pass: assign the leftovers by descending fractional parts
	local left = remainder - used
	if left > 0 then
		local idx = {}
		for i = 1, n do if elig[i] == 1 then idx[#idx + 1] = i end end
		table.sort(idx, function(a, b) return frac[a] > frac[b] end)
		local k = 1
		while left > 0 and #idx > 0 do
			local i = idx[k]
			if not cap or (widths[i] + added[i] < cap) then
				added[i] = added[i] + 1
				left = left - 1
			end
			k = (k % #idx) + 1
		end
	end

	for i = 1, n do widths[i] = widths[i] + (added[i] or 0) end
	return widths
end

---@param line string
---@return boolean
local function is_table_like(line)
	if not line or line == "" then return false end
	if line:match("^%s*```") then return false end
	local pipe_count = select(2, line:gsub("|", ""))
	if pipe_count < 2 then return false end
	if line:match("^%s*|%s*[:%- ]-|") then return true end
	return line:match("%S") ~= nil
end

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
---@return string[]
local function split_cells(line)
	local body = line:gsub("^%s*|", ""):gsub("|%s*$", "")
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
	local aligns = {}
	if not sep_line or sep_line == "" then
		for _ = 1, ncols do aligns[#aligns + 1] = { left = true, right = false } end
		return aligns
	end
	local cells = split_cells(sep_line)
	for i = 1, ncols do
		local c             = vim.trim(cells[i] or "---")
		local left          = c:sub(1, 1) == ":"
		local right         = c:sub(#c, #c) == ":"
		aligns[#aligns + 1] = { left = left, right = right }
	end
	return aligns
end

---@param buf integer
---@param lnum integer
---@return boolean ok, MDWrapBounds|nil bounds, string|nil err
local function find_table_bounds(buf, lnum)
	if not (api.nvim_buf_is_valid(buf)) then return false, nil, "invalid buffer" end
	local total = api.nvim_buf_line_count(buf)
	if lnum < 1 or lnum > total then return false, nil, "cursor out of range" end
	local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
	if not is_table_like(lines[lnum]) then return false, nil, "not on a table line" end

	local s = lnum
	while s > 1 and is_table_like(lines[s - 1]) do s = s - 1 end
	local e = lnum
	while e < total and is_table_like(lines[e + 1]) do e = e + 1 end

	local first = lines[s]
	local fp = first:find("|", 1, true) or 1
	local indent_str = first:sub(1, fp - 1)
	local indent_col = dispw(indent_str)
	return true, { start_lnum = s, end_lnum = e, indent_col = indent_col, indent_str = indent_str }, nil
end

---@param buf integer
---@return boolean ok, MDWrapBounds[]|nil list, string|nil err
local function find_all_table_bounds(buf)
	if not api.nvim_buf_is_valid(buf) then return false, nil, "invalid buffer" end
	local total = api.nvim_buf_line_count(buf)
	local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
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
	return true, out, nil
end

---@param lines string[]
---@return MDTableParse
local function parse_table_lines(lines)
	local sep_idx
	for i, L in ipairs(lines) do
		if is_separator_line(L) and not sep_idx then sep_idx = i end
	end
	local ncols = 0
	local header ---@type string[]|nil
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
	local function pad_to(cols, row)
		while #row < cols do row[#row + 1] = "" end
	end
	if header then pad_to(ncols, header) end
	for _, r in ipairs(body) do pad_to(ncols, r) end
	return {
		header = header,
		body = body,
		has_separator = sep_idx ~= nil,
		aligns = aligns,
		ncols = ncols,
	}
end

---@param win integer
---@param indent_col integer
---@param ncols integer
---@param pad integer
---@param cfg MDTableWrapConfig
---@return boolean ok, integer|nil content_total, string|nil err
local function compute_content_total(win, indent_col, ncols, pad, cfg)
	if not api.nvim_win_is_valid(win) then return false, nil, "invalid window" end
	local text_area = TEXT_AREA_PROVIDER(win)
	local available = text_area - indent_col - cfg.outer_left - cfg.outer_right
	if available <= 0 then return false, nil, "no horizontal budget" end
	local pipes = ncols + 1
	local content_total = available - pipes - (2 * pad * ncols)
	if content_total < ncols then return false, nil, "not enough space for minimal columns" end
	return true, content_total, nil
end

--- Compute "natural" content widths per column.
--- Header cells use full display width (stay on one physical line).
--- Body cells use the maximum token width (longest unbreakable word),
--- which avoids overestimating widths for paragraphs that will be wrapped.
---@param parsed MDTableParse
---@param cap integer|nil     -- optional max_col_width
---@param minw integer|nil    -- optional min_col_width
---@return integer[] widths   -- per-column content widths
local function measure_natural_col_widths(parsed, cap, minw)
	---@param s string
	---@return integer
	local function max_token_width(s)
		-- Split by whitespace; measure display width of each token.
		-- If no tokens exist (empty/whitespace-only), width = 0.
		local maxw, any = 0, false
		for tok in (s or ""):gmatch("%S+") do
			any = true
			local d = dispw(tok)
			if d > maxw then maxw = d end
		end
		return any and maxw or 0
	end

	---@type integer[]
	local w = {}
	for i = 1, parsed.ncols do w[i] = 1 end

	-- 1) Header: use full cell width (headers are kept to one physical line)
	if parsed.header then
		for i = 1, parsed.ncols do
			local d = dispw(parsed.header[i] or "")
			if d > w[i] then w[i] = d end
		end
	end

	-- 2) Body: use longest token width (natural, unbreakable unit)
	for _, row in ipairs(parsed.body) do
		for i = 1, parsed.ncols do
			local d = max_token_width(row[i] or "")
			if d > w[i] then w[i] = d end
		end
	end

	-- 3) Clamp to min/max as configured
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
---@return integer[]
local function equal_widths(ncols, content_total, cap, minw)
	local base = math.floor(content_total / ncols)
	local leftover = content_total % ncols
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
	for _, v in ipairs(widths) do s = s + v end
	return s
end

---@param widths integer[]
---@param target integer
---@param lower_bound integer
---@return integer[]
local function shrink_proportionally(widths, target, lower_bound)
	local lb = math.max(1, lower_bound or 1)
	local n = #widths
	local sum = sum_widths(widths)
	if sum <= target then return widths end

	local scaled, res = {}, {}
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
---@param cfg MDTableWrapConfig
---@return boolean ok, MDWrapPlan|nil plan, string|nil err
local function compute_plan(indent_col, parsed, cfg)
	local pad = cfg.inner_pad
	local ok, content_total, err = compute_content_total(0, indent_col, parsed.ncols, pad, cfg)
	if not ok then return false, nil, err end

	-- helper: need without expansion (min + header + longest token; no cap)
	local function need_without_expansion()
		-- reuse natural meter but without max cap, min enforced
		return measure_natural_col_widths(parsed, nil, cfg.min_col_width or 1)
	end

	if cfg.width_mode == "minflex" then
		local minw  = cfg.min_col_width and math.max(1, cfg.min_col_width) or 1
		local cap   = cfg.max_col_width
		local need  = need_without_expansion() -- >= minw and >= header/longest-token
		local sum_n = sum_widths(need)

		-- If even "need" does not fit, shrink but keep ≥ minw if possible.
		if sum_n > content_total then
			local min_sum = minw * parsed.ncols
			local lower   = (min_sum <= content_total) and minw or 1
			local shrunk  = shrink_proportionally(need, content_total, lower)
			return true, { col_widths = shrunk, padding = pad }, nil
		end

		-- We have remainder to spread only across columns with wrap pressure.
		local para       = measure_paragraph_widths(parsed)
		local widths     = vim.deepcopy(need)
		local remainder  = content_total - sum_n

		-- Compute weights: extra demand beyond 'need' (paragraph width - need).
		local weights    = {}
		local has_weight = false
		for i = 1, parsed.ncols do
			local demand = math.max(0, (para[i] or 0) - widths[i])
			-- tiny epsilon: ensure columns with any demand get at least a sliver
			if demand > 0 then has_weight = true end
			weights[i] = demand
		end

		if has_weight and remainder > 0 then
			widths = expand_proportionally(widths, remainder, weights, cap)
		end

		-- enforce cap softly if someone overshot due to remainder distribution
		if cap and cap >= 1 then
			local oversum = 0
			for i = 1, #widths do
				if widths[i] > cap then
					oversum = oversum + (widths[i] - cap)
					widths[i] = cap
				end
			end
			-- if we clipped, try to redistribute clipped space to non-capped flex columns
			if oversum > 0 then
				local reweights = {}
				local any = false
				for i = 1, parsed.ncols do
					if (not cap) or widths[i] < cap then
						local demand = math.max(0, (para[i] or 0) - widths[i])
						if demand > 0 then any = true end
						reweights[i] = demand
					else
						reweights[i] = 0
					end
				end
				if any then widths = expand_proportionally(widths, oversum, reweights, cap) end
			end
		end

		return true, { col_widths = widths, padding = pad }, nil
	end

	-- existing branches unchanged (auto/equal)
	if cfg.width_mode == "auto" or cfg.auto_width == true then
		local widths = measure_natural_col_widths(parsed, cfg.max_col_width, cfg.min_col_width or 1)
		local sumw   = sum_widths(widths)
		if sumw > content_total then
			local minw = cfg.min_col_width and math.max(1, cfg.min_col_width) or 1
			local min_sum = minw * parsed.ncols
			local lb = (min_sum <= content_total) and minw or 1
			widths = shrink_proportionally(widths, content_total, lb)
		end
		return true, { col_widths = widths, padding = pad }, nil
	else -- "equal"
		local widths = equal_widths(parsed.ncols, content_total, cfg.max_col_width, cfg.min_col_width or 1)
		local sumw   = sum_widths(widths)
		if sumw > content_total then
			widths = shrink_proportionally(widths, content_total, 1)
		end
		return true, { col_widths = widths, padding = pad }, nil
	end
end

---@param token string
---@param width integer
---@return string[]
local function break_token_utf8(token, width)
	local parts = {}
	local i, total = 0, strchars(token)
	while i < total do
		local chunk, w = "", 0
		while i < total do
			local ch = strcharpart(token, i, 1)
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
---@param pad integer
---@return string
local function format_single_row(row, widths, aligns, pad)
	local parts = {}
	for c, w in ipairs(widths) do
		parts[#parts + 1] = pad_cell(row[c] or "", math.max(1, w), aligns[c] or { left = true, right = false }, pad)
	end
	return "|" .. table.concat(parts, "|") .. "|"
end

---@param rows string[][]
---@param widths integer[]
---@param aligns MDColumnAlign[]
---@param pad integer
---@return string[]
local function format_body_rows(rows, widths, aligns, pad)
	local out = {}
	for _, row in ipairs(rows) do
		local wrapped_per_col, maxh = {}, 1
		for c, s in ipairs(row) do
			local w = math.max(1, widths[c] or 1)
			wrapped_per_col[c] = wrap_cell(s, w)
			if #wrapped_per_col[c] > maxh then maxh = #wrapped_per_col[c] end
		end
		for k = 1, maxh do
			local parts = {}
			for c, w in ipairs(widths) do
				local text = wrapped_per_col[c][k] or ""
				parts[#parts + 1] = pad_cell(text, w, aligns[c] or { left = true, right = false }, pad)
			end
			out[#out + 1] = "|" .. table.concat(parts, "|") .. "|"
		end
	end
	return out
end

---@param buf integer
---@param bounds MDWrapBounds
---@param cfg MDTableWrapConfig
---@return boolean ok, boolean|nil overflow, string|nil err
local function table_has_overflow(buf, bounds, cfg)
	if not api.nvim_buf_is_valid(buf) then return false, nil, "invalid buffer" end
	local text_area = TEXT_AREA_PROVIDER(0)
	local avail = text_area - bounds.indent_col - cfg.outer_left - cfg.outer_right
	if avail <= 0 then return true, true, nil end
	local lines = api.nvim_buf_get_lines(buf, bounds.start_lnum - 1, bounds.end_lnum, false)
	for _, L in ipairs(lines) do
		local fp = L:find("|", 1, true) or 1
		local tail = L:sub(fp)
		if dispw(tail) > avail then
			return true, true, nil
		end
	end
	return true, false, nil
end

---@param buf integer
---@param win integer
---@param bounds MDWrapBounds
---@param cfg MDTableWrapConfig
---@return boolean ok, string|nil err
local function reformat_table(buf, win, bounds, cfg)
	if not (api.nvim_buf_is_valid(buf) and api.nvim_win_is_valid(win)) then
		return false, "invalid handles"
	end
	local lines = api.nvim_buf_get_lines(buf, bounds.start_lnum - 1, bounds.end_lnum, false)
	if #lines == 0 then return false, "empty table block" end

	local parsed = parse_table_lines(lines)
	if parsed.ncols == 0 then return false, "no columns detected" end

	local ok, plan, perr = compute_plan(bounds.indent_col, parsed, cfg)
	if not ok or not plan then return false, perr or "plan failed" end

	local widths, aligns, pad = plan.col_widths, parsed.aligns, plan.padding
	local formatted = {}

	if parsed.header then
		formatted[#formatted + 1] = format_single_row(parsed.header, widths, aligns, pad)
		formatted[#formatted + 1] = build_separator_row(aligns, widths)
	end
	local body_lines = format_body_rows(parsed.body, widths, aligns, pad)
	for _, L in ipairs(body_lines) do formatted[#formatted + 1] = L end
	for i = 1, #formatted do
		formatted[i] = bounds.indent_str .. formatted[i]
	end

	local ok_set, err = pcall(api.nvim_buf_set_lines, buf, bounds.start_lnum - 1, bounds.end_lnum, false, formatted)
	if not ok_set then return false, tostring(err) end
	return true, nil
end

-- High-level helpers (still UI-agnostic)

---@param mode MDMode
---@param cfg MDTableWrapConfig
---@return boolean ok, string|nil err
local function reformat_current(mode, cfg)
	local win = api.nvim_get_current_win()
	local buf = api.nvim_get_current_buf()
	if not (api.nvim_buf_is_valid(buf) and api.nvim_win_is_valid(win)) then
		return false, "invalid current win/buf"
	end
	local cur = api.nvim_win_get_cursor(win)
	local okb, bounds, berr = find_table_bounds(buf, cur[1])
	if not okb then return false, berr end

	if mode ~= "force" then
		local oko, overflow = table_has_overflow(buf, bounds, cfg)
		if not oko then return false, "overflow check failed" end
		if not overflow then return true, nil end
	end

	return reformat_table(buf, win, bounds, cfg)
end

---@param mode MDMode
---@param buf integer
---@param cfg MDTableWrapConfig
---@return boolean ok, integer|nil changed, string|nil err
local function reformat_all(mode, buf, cfg)
	if not api.nvim_buf_is_valid(buf) then return false, nil, "invalid buffer" end
	local okb, list, berr = find_all_table_bounds(buf)
	if not okb then return false, nil, berr end
	if #list == 0 then return true, 0, nil end

	table.sort(list, function(a, b) return a.start_lnum > b.start_lnum end)
	local changed = 0
	for _, b in ipairs(list) do
		if mode == "force" then
			local ok, err = reformat_table(buf, 0, b, cfg)
			if ok then changed = changed + 1 else return false, nil, err end
		else
			local oko, overflow = table_has_overflow(buf, b, cfg)
			if not oko then return false, nil, "overflow check failed" end
			if overflow then
				local ok, err = reformat_table(buf, 0, b, cfg)
				if not ok then return false, nil, err end
				changed = changed + 1
			end
		end
	end
	return true, changed, nil
end

-- Public API of the core module
local M = {}

---@param fn_provider fun(win:integer):integer
function M.set_text_area_provider(fn_provider)
	if type(fn_provider) == "function" then
		TEXT_AREA_PROVIDER = fn_provider
	else
		TEXT_AREA_PROVIDER = default_text_area_cols
	end
end

M.find_table_bounds     = find_table_bounds
M.find_all_table_bounds = find_all_table_bounds
M.reformat_table        = reformat_table
M.reformat_current      = reformat_current
M.reformat_all          = reformat_all

return M
