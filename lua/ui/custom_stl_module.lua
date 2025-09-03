---@module 'ui.custom_stl_module
--- Module with helper function for custom nvchad/ui/statusline

local M = {}

--- Escape % so user text cannot break statusline sequences.
--- @param s string
--- @return string
function M.stl_escape(s)
	return (s:gsub("%%", "%%%%"))
end

--- Ellipsize in the middle to a maximum length (display width aware enough for ASCII).
--- @param s string
--- @param max integer
--- @return string
function M.ellipsize_middle(s, max)
	if #s <= max then return s end
	local head = math.floor((max - 1) / 2)
	local tail = max - head - 1
	return string.sub(s, 1, head) .. "…" .. string.sub(s, #s - tail + 1, #s)
end

--- Repo-/project-relative path (fallback: path relative to cwd; final fallback: tail).
--- @param path string
--- @return string
function M.repo_relative(path)
	if path == "" then return "[No Name]" end
	local dir = vim.fn.fnamemodify(path, ":h")
	local gitdir = vim.fs.find(".git", { upward = true, path = dir })[1]
	if gitdir then
		local root = vim.fn.fnamemodify(gitdir, ":h")
		local rel = vim.fn.fnamemodify(path, (":~:%s"):format(root))
		if rel == path then return vim.fn.fnamemodify(path, ":t") end
		rel = rel:gsub("^%./", ""):gsub("^/", "")
		return rel
	else
		return vim.fn.fnamemodify(path, ":~:.")
	end
end

--- Try to extract a concise symbol path near the cursor (Treesitter → LSP → nil).
--- Only keeps named semantic nodes; avoids generic "block" noise.
--- @return string|nil
function M.symbol_context()
	local ok_ts = pcall(require, "vim.treesitter")
	local ok_utils, tsu = pcall(require, "nvim-treesitter.ts_utils")
	if not ok_ts or not ok_utils or not tsu then return nil end

	local node = tsu.get_node_at_cursor()
	if not node then return nil end

	local keep = {
		function_declaration = true,
		function_definition = true,
		method_declaration = true,
		method_definition = true,
		class_declaration = true,
		class_specifier = true,
		struct_specifier = true,
		interface_declaration = true,
		module_declaration = true,
		namespace_definition = true,
		impl_item = true, -- rust
	}

	function M.ts_identifier_of(n)
		-- 1) Named field "name"
		local named = n:field("name")
		if named and named[1] then
			local t = vim.treesitter.get_node_text(named[1], 0)
			if t and #t > 0 then return t end
		end
		-- 2) Shallow search for common identifier-like node types
		local want = {
			"identifier", "property_identifier", "field_identifier",
			"type_identifier", "name",
		}
		local function in_list(x) for _, w in ipairs(want) do if x == w then return true end end end
		local function first_ident(m, depth)
			depth = depth or 0
			if depth > 2 then return nil end
			if in_list(m:type()) then
				local t = vim.treesitter.get_node_text(m, 0)
				if t and #t > 0 then return t end
			end
			for i = 0, m:child_count() - 1 do
				local r = first_ident(m:child(i), depth + 1)
				if r then return r end
			end
			return nil
		end
		local t = first_ident(n, 0)
		if t and #t > 0 then return t end
		-- 3) Final fallback: first plausible token from the line
		local raw = vim.treesitter.get_node_text(n, 0) or ""
		raw = raw:gsub("^%s+", ""):gsub("\n.*", "")
		local guess = raw:match("^%w+%s+([%w_]+)%s*%(")
				or raw:match("^%w+%s+([%w_]+)%s*[={:]")
				or raw:match("^([%w_%.:]+)%s*%(")
				or raw:match("^([%w_%.:]+)")
		return guess
	end

	local names = {}
	local u = node
	while u do
		local t = u:type()
		if keep[t] then
			local ident = M.ts_identifier_of(u)
			if ident and #ident > 0 then
				if t:find("function") or t:find("method") then
					if not ident:find("%)$") then ident = ident .. "()" end
				end
				table.insert(names, 1, ident)
			end
		end
		local p = u:parent()
		if not p or p == u then break end
		u = p
	end

	if #names == 0 then return nil end
	return table.concat(names, " → ")
end

--- Render the centered breadcrumbs module (no leading/trailing spaces to keep centering exact).
--- @return string
function M.render_breadcrumbs()
	local utils = require "nvchad.stl.utils"
	local bufnr = utils.stbufnr()
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then return "" end

	local rel = M.repo_relative(path)
	local ctx = M.symbol_context()

	local line = ctx and (#ctx > 0) and (rel .. " ⟩ " .. ctx) or rel
	-- Optional: scale with window width (use ~40% of columns)
	local maxw = math.max(30, math.floor(vim.o.columns * 0.4))
	line = M.ellipsize_middle(line, maxw)
	line = M.stl_escape(line)

	-- IMPORTANT:
	-- * No leading or trailing spaces here – they bias the visual center.
	-- * Use %* to reset highlight after the segment.
	return line .. "%*"
end

-------------------------------------
-- MODULES HIGHLIGHTING
-------------------------------------

-- Strip embedded statusline highlights like "%#Group#" / "%*" to allow re-wrapping with our own group.
function M.stl_strip_hl(s)
	return (s:gsub("%%#.-#", ""):gsub("%%%*", ""))
end

-- Open a highlight group without resetting at the end.
-- Use this when you want the band to keep filling the center area up to the next module.
function M.hl_open(group)
	return "%#" .. group .. "#"
end

-- Wrap payload with a statusline highlight group.
function M.hl_wrap(group, s)
	if not s or s == "" then return "" end
	return "%#" .. group .. "#" .. s .. "%*"
end

-- Compute current "mode band" highlight group, e.g. "St_Normalmode", "St_Insertmode", ...
-- Use this to wrap other modules so they visually match the mode/git band.
function M.mode_band_group()
	local utils = require("nvchad.stl.utils")
	local m = vim.api.nvim_get_mode().mode
	local name = (utils.modes[m] and utils.modes[m][2]) or "Normal"
	return "St_" .. name .. "mode"
end

return M
