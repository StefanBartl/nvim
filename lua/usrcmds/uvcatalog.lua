---@module 'usrcmds.uvdoc'
--- Fetch libuv function signatures and short descriptions into a scratch buffer.
--- It resolves a vim.uv function name (e.g. "timer_start", "new_timer", "fs_open")
--- to the corresponding C API name (e.g. "uv_timer_start", "uv_timer_init", "uv_fs_open"),
--- locates the correct docs page via the libuv genindex, opens the RST source ("View this page"),
--- extracts the `.. c:function::` block and renders it nicely.
---
--- Requirements:
---   - curl available in PATH (used via vim.system)
---   - Neovim 0.9+ (vim.system) on Linux/macOS
---
--- References:
---   - API index: https://docs.libuv.org/en/v1.x/genindex.html
---   - "View this page" RST: replace "page.html#..." with "_sources/page.rst.txt"
---   - Neovim luv reference (fallback): :h luvref.txt
---
--- Limitations:
---   - Only (C function) entries are fetched; types/macros are ignored.
---   - HTML structure changes upstream may require adjusting simple patterns.
---
--- Public API:
---   require('uvdoc').setup({ open = "float"|"split", max_bytes = 512*1024 })
---   require('uvdoc').doc(name?)        -- fetch doc for given name or <cword>
---   require('uvdoc').pick()            -- pick a vim.uv name, then fetch

local M = {}

---@class UVDocConfig
---@field open? '"float"'|'"split"' How to display the scratch doc buffer
---@field max_bytes? integer Maximum bytes per HTTP response (simple guard)
local DEFAULTS ---@type UVDocConfig
DEFAULTS = {
	open = "float",
	max_bytes = 512 * 1024,
}

---@type UVDocConfig
local CFG = vim.deepcopy(DEFAULTS)

-- Cache for the genindex HTML to avoid repeated downloads.
---@type string|nil
local GENINDEX_HTML = nil

-- Base URL for libuv docs (v1.x series to match stable Neovim)
local BASE = "https://docs.libuv.org/en/v1.x/"

-- Run curl and return stdout string (bounded by CFG.max_bytes).
---@param url string
---@return string|nil, string|nil
local function http_get(url)
	-- Use -fsSL for quiet failures and follow redirects
	local cmd = { "curl", "-fsSL", url }
	local res = vim.system(cmd, { text = true }):wait()
	if res.code ~= 0 then
		return nil, string.format("curl failed (%d): %s", res.code, res.stderr or "")
	end
	local out = res.stdout or ""
	if #out > CFG.max_bytes then
		return nil, string.format("response too large (%d bytes)", #out)
	end
	return out, nil
end

-- Lazy-load the libuv genindex page.
---@return string|nil
local function get_genindex()
	if GENINDEX_HTML then return GENINDEX_HTML end
	local html, err = http_get(BASE .. "genindex.html")
	if not html then
		vim.notify("[uvdoc] failed to fetch genindex: " .. (err or "unknown"), vim.log.levels.WARN)
		return nil
	end
	GENINDEX_HTML = html
	return html
end

-- Normalize a user-supplied name to a candidate C function "uv_xxx".
-- Handles "new_timer" -> "uv_timer_init", fills missing "uv_" prefix,
-- and a few special one-offs (cwd/chdir).
---@param name string
---@return string uv_name
local function normalize_to_uv(name)
	local n = name
	n = n:gsub("^vim%.uv%.", "")   -- allow "vim.uv.timer_start"
	n = n:gsub("^vim%.loop%.", "") -- allow older alias
	n = n:gsub(":", "_")           -- handle-like "timer:start" -> "timer_start"

	-- Special cases first
	if n == "cwd" then return "uv_cwd" end
	if n == "chdir" then return "uv_chdir" end

	-- Constructors in luv are usually "new_TYPE" => uv_TYPE_init
	local t = n:match("^new_(%w+)$")
	if t then
		return "uv_" .. t .. "_init"
	end

	-- Add uv_ prefix if missing
	if not n:match("^uv_") then
		n = "uv_" .. n
	end
	return n
end

-- From an index HTML, find the href to the given uv function ("uv_...").
-- We only consider "(C function)" entries to avoid types/macros.
---@param idx_html string
---@param uvname string
---@return string|nil rel_html_href
local function find_uv_href(idx_html, uvname)
	-- Example pattern in HTML:
	-- <a class="reference internal" href="timer.html#c.uv_timer_start">uv_timer_start (C function)</a>
	local pat = 'href="([^"]-%.html#[^"]-)"%s*>%s*' .. vim.pesc(uvname) .. '%s*%(([^)]+)%)%s*</a>'
	local href, kind = idx_html:match(pat)
	if href and kind and kind:lower():find("function", 1, true) then
		return href
	end
	return nil
end

-- Convert "foo.html#c.uv_bar" to "_sources/foo.rst.txt"
---@param html_href string
---@return string
local function html_href_to_rst(html_href)
	local page = html_href:match("^([^#]+)%.html")
	if not page then
		return "_sources/index.rst.txt"
	end
	return "_sources/" .. page .. ".rst.txt"
end

-- Extract the c:function block for a given uv function name from an .rst.txt page.
-- Returns signature line and a list of description lines.
---@param rst string
---@param uvname string
---@return string sig, string[] body
local function extract_c_function(rst, uvname)
	-- Find the directive for our function; capture the whole signature line.
	local sig_pat = "%.%.%s+c:function::%s+([^\n]-" .. uvname .. "%b())"
	local sig = rst:match(sig_pat)
	if not sig then
		return "", { "[uvdoc] function not found in RST: " .. uvname }
	end

	-- Now find the slice after that directive up to the next directive or end.
	local s1, e1 = rst:find(sig_pat)
	if not s1 or not e1 then
		return sig, { "[uvdoc] unable to slice body for: " .. uvname }
	end
	local tail = rst:sub(e1 + 1)

	-- Stop at next ".. c:function::" or another ".. " directive that likely starts a new block.
	local stop1 = tail:find("\n%.%.[^\n]-::")
	local body_chunk = stop1 and tail:sub(1, stop1 - 1) or tail

	-- Clean minor RST artifacts: collapse excessive blank lines, strip leading spaces.
	local lines ---@type string[]
	lines = {}
	for L in body_chunk:gmatch("([^\n]*)\n?") do
		if L == nil then break end
		local s = L:gsub("^%s+", "")
		lines[#lines + 1] = s
	end

	-- Trim trailing empties
	while #lines > 0 and lines[#lines]:match("^%s*$") do
		table.remove(lines, #lines)
	end

	-- Minimal post-filter: keep at most the first note block fully; that’s enough for a short summary.
	return sig, lines
end

-- Render a documentation buffer (float or split) with the signature + short description.
---@param uvname string
---@param src_url string
---@param sig string
---@param body string[]
local function render_doc(uvname, src_url, sig, body)
	local lines ---@type string[]
	lines = {}
	lines[#lines + 1] = "# " .. uvname
	lines[#lines + 1] = ""
	lines[#lines + 1] = "C signature"
	lines[#lines + 1] = ""
	lines[#lines + 1] = "```c"
	lines[#lines + 1] = sig
	lines[#lines + 1] = "```"
	lines[#lines + 1] = ""
	lines[#lines + 1] = "Summary"
	lines[#lines + 1] = ""
	if #body == 0 then
		lines[#lines + 1] = "(no summary available)"
	else
		for i = 1, #body do
			local s = tostring(body[i] or "")
			if s ~= "" then
				lines[#lines + 1] = s
			else
				lines[#lines + 1] = ""
			end
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "Source"
	lines[#lines + 1] = ""
	lines[#lines + 1] = src_url

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.api.nvim_buf_set_name(buf, "libuv-doc://" .. uvname)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "markdown"

	if CFG.open == "split" then
		vim.cmd("botright new")
		vim.api.nvim_win_set_buf(0, buf)
	else
		local width  = math.floor(vim.o.columns * 0.62)
		local height = math.floor(vim.o.lines * 0.70)
		local row    = math.floor((vim.o.lines - height) / 2 - 1)
		local col    = math.floor((vim.o.columns - width) / 2)
		vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
		})
	end
end

-- Public: open docs for a given name or <cword>.
---@param name string|nil
function M.doc(name)
	local raw = name or vim.fn.expand("<cword>")
	if not raw or raw == "" then
		vim.notify("[uvdoc] no name given", vim.log.levels.WARN)
		return
	end
	local uvname = normalize_to_uv(raw)

	local idx = get_genindex()
	if not idx then
		vim.notify("[uvdoc] missing genindex (offline?). Try :h luvref.txt", vim.log.levels.WARN)
		return
	end

	local href = find_uv_href(idx, uvname)
	if not href then
		vim.notify(string.format("[uvdoc] function not found in libuv index: %s", uvname), vim.log.levels.WARN)
		return
	end

	local html_url = BASE .. href
	local rst_url  = BASE .. html_href_to_rst(href)

	local rst, err = http_get(rst_url)
	if not rst then
		vim.notify("[uvdoc] failed to fetch RST: " .. (err or "unknown"), vim.log.levels.WARN)
		return
	end

	local sig, body = extract_c_function(rst, uvname)
	if sig == "" then
		vim.notify("[uvdoc] could not extract signature for: " .. uvname, vim.log.levels.WARN)
		return
	end

	render_doc(uvname, html_url, sig, body)
end

-- Simple picker over available vim.uv function keys (runtime introspection).
---@return nil
function M.pick()
	local uv = vim.uv or vim.loop
	if type(uv) ~= "table" then
		vim.notify("[uvdoc] vim.uv not available", vim.log.levels.WARN)
		return
	end
	---@type string[]
	local names = {}
	for k, v in pairs(uv) do
		if type(v) == "function" then
			names[#names + 1] = k
		end
	end
	table.sort(names)

	vim.ui.select(names, { prompt = "vim.uv function" }, function(item)
		if not item then return end
		M.doc(item)
	end)
end

---@param opts UVDocConfig|nil
function M.setup(opts)
	CFG = vim.tbl_deep_extend("force", CFG, opts or {})
end

M.setup({ open = "float" })

vim.api.nvim_create_user_command("UVDoc", function(cmd)
	if #cmd.args > 0 then
		M.doc(cmd.args)
	else
		M.doc()
	end
end, { nargs = "?", complete = "lua", desc = "Show libuv C signature+summary for a vim.uv function" })

vim.api.nvim_create_user_command("UVDocPick", function()
	M.pick()
end, { desc = "Pick a vim.uv function and show libuv docs" })

return M
