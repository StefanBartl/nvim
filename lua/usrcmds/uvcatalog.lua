---@module 'uvdoc'
--- libuv doc fetcher with robust index parsing, fuzzy list UI, and "insert here".
--- This module targets https://docs.libuv.org/en/v1.x/ and extracts functions by the
--- Sphinx anchor ids (#c.uv_*), not by link labels. It provides:
---   :UVDoc [name]      -- exact or fuzzy (e.g., "loop", "timer", "fs_open")
---   :UVDocList [q]     -- line-based picker with cursorline; <CR> opens
---   :UVDocPick         -- alias to list all
---   :UVDocHere [name]  -- insert only the C signature at cursor
---   :UVDocCacheClear   -- clear in-session caches
---
--- Requirements:
---   - curl in PATH (Linux/macOS; Windows not covered by default)
---   - Neovim ≥ 0.9 (vim.system)

local M = {}

---@class UVDocConfig
---@field open? '"float"'|'"split"' How to display the doc window
---@field max_bytes? integer         Max HTTP response size
---@field user_agent? string|nil     Optional curl User-Agent
local DEFAULTS ---@type UVDocConfig
DEFAULTS = {
	open = "float",
	max_bytes = 512 * 1024,
	user_agent = "uvdoc.nvim/0.2 (+https://docs.libuv.org)",
}

---@type UVDocConfig
local CFG = vim.deepcopy(DEFAULTS)

-- Session caches -------------------------------------------------------------

---@type string|nil
local GENINDEX_HTML = nil

---@type string[]|nil
local INDEX_FUNCTIONS = nil -- all "uv_*" function names extracted from genindex

-- Constant base URL (stable series to match Neovim bindings)
local BASE = "https://docs.libuv.org/en/v1.x/"

-- Utilities ------------------------------------------------------------------

--- Run curl and return stdout as text (bounded).
---@param url string
---@return string|nil, string|nil
local function http_get(url)
	---@type string[]
	local cmd = { "curl", "-fsSL" }
	if CFG.user_agent and CFG.user_agent ~= "" then
		cmd[#cmd + 1] = "-H"
		cmd[#cmd + 1] = "User-Agent: " .. CFG.user_agent
	end
	cmd[#cmd + 1] = url

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

--- Fetch and cache the libuv genindex.
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

--- Extract all uv_* function names by scanning anchor IDs (#c.uv_*),
--- independent of link labels and surrounding markup.
---@param idx_html string
---@return string[] names
local function parse_functions_from_index(idx_html)
	---@type table<string, boolean>
	local seen = {}
	---@type string[]
	local names = {}

	-- Match any href ending with "#c.uv_...."
	-- Example: href="timer.html#c.uv_timer_start"
	for _, idpart in idx_html:gmatch('href="([^"]-%.html#c%.(uv_[%w_]+))"') do
		-- idpart is like "uv_timer_start"
		if idpart and not seen[idpart] then
			seen[idpart] = true
			names[#names + 1] = idpart
		end
	end

	table.sort(names)
	return names
end

--- Ensure we have the list of uv_* functions in memory.
---@return string[]|nil
local function ensure_index_cache()
	if INDEX_FUNCTIONS then return INDEX_FUNCTIONS end
	local html = get_genindex()
	if not html then return nil end
	local names = parse_functions_from_index(html)
	if #names == 0 then
		vim.notify("[uvdoc] genindex parsed but no uv_* anchors found", vim.log.levels.WARN)
	end
	INDEX_FUNCTIONS = names
	return INDEX_FUNCTIONS
end

--- Map user input to an "uv_*" canonical function name if it already looks exact.
---@param name string
---@return string
local function normalize_to_uv(name)
	local n = name
	n = n:gsub("^vim%.uv%.", "")
	n = n:gsub("^vim%.loop%.", "")
	n = n:gsub(":", "_")

	if n == "cwd" then return "uv_cwd" end
	if n == "chdir" then return "uv_chdir" end

	local t = n:match("^new_(%w+)$")
	if t then return "uv_" .. t .. "_init" end

	if not n:match("^uv_") then n = "uv_" .. n end
	return n
end

--- Find the relative HTML href for a given "uv_*" by its anchor id (#c.uv_*).
---@param idx_html string
---@param uvname string
---@return string|nil
local function find_uv_href(idx_html, uvname)
	local id = "c." .. uvname
	-- We search for any anchor that references "#c.uv_name", not relying on link text.
	local pat = 'href="([^"]-%.html#' .. vim.pesc(id) .. ')"'
	local href = idx_html:match(pat)
	return href
end

--- Convert "foo.html#c.uv_bar" to "_sources/foo.rst.txt".
---@param html_href string
---@return string
local function html_href_to_rst(html_href)
	local page = html_href:match("^([^#]+)%.html")
	if not page then return "_sources/index.rst.txt" end
	return "_sources/" .. page .. ".rst.txt"
end

--- Extract the `.. c:function::` block for uvname from an RST page.
---@param rst string
---@param uvname string
---@return string sig, string[] body
local function extract_c_function(rst, uvname)
	local sig_pat = "%.%.%s+c:function::%s+([^\n]-" .. uvname .. "%b())"
	local s1, e1 = rst:find(sig_pat)
	if not s1 or not e1 then
		return "", { "[uvdoc] function not found in RST: " .. uvname }
	end
	local sig = rst:match(sig_pat) or ""

	local tail = rst:sub(e1 + 1)
	local stop1 = tail:find("\n%.%.[^\n]-::")
	local body_chunk = stop1 and tail:sub(1, stop1 - 1) or tail

	---@type string[]
	local lines = {}
	for L in body_chunk:gmatch("([^\n]*)\n?") do
		if L == nil then break end
		local s = (L or ""):gsub("^%s+", "")
		lines[#lines + 1] = s
	end
	while #lines > 0 and lines[#lines]:match("^%s*$") do
		table.remove(lines, #lines)
	end
	return sig, lines
end

-- Search & list --------------------------------------------------------------

--- Return candidates for a fuzzy query; if query is nil, return all from index.
---@param query string|nil
---@return string[] list
local function candidates_for(query)
	local all = ensure_index_cache() or {}
	if not query or query == "" then return all end

	local q = query
	q = q:gsub("^vim%.uv%.", "")
	q = q:gsub("^uv_", "")

	local prefix_map = {
		loop     = "uv_loop_",
		fs       = "uv_fs_",
		fs_event = "uv_fs_event_",
		fs_poll  = "uv_fs_poll_",
		tcp      = "uv_tcp_",
		udp      = "uv_udp_",
		pipe     = "uv_pipe_",
		tty      = "uv_tty_",
		signal   = "uv_signal_",
		timer    = "uv_timer_",
		poll     = "uv_poll_",
		work     = "uv_work_",
		dl       = "uv_dl",  -- both uv_dlopen, uv_dlclose, ...
		process  = "uv_",    -- broad: spawn/kill, etc.
		stream   = "uv_stream_",
	}

	local pref = prefix_map[q]
	if pref then
		local out = {}
		for _, n in ipairs(all) do
			if n:sub(1, #pref) == pref or n:find(pref, 1, true) then
				out[#out + 1] = n
			end
		end
		return out
	end

	local needle = q:lower()
	local out = {}
	for _, n in ipairs(all) do
		if n:lower():find(needle, 1, true) then
			out[#out + 1] = n
		end
	end
	return out
end

--- Open a simple line-based list buffer with cursorline and keymaps.
---@param names string[]
---@param title string
---@param on_enter fun(name:string)
local function open_list(names, title, on_enter)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_name(buf, "libuv-index://" .. (title:gsub("%s+", "_")))
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, names)
	vim.bo[buf].filetype   = "uvdoc-list"
	vim.bo[buf].modifiable = false

	local width            = math.floor(vim.o.columns * 0.5)
	local height           = math.min(math.max(#names, 4) + 2, math.floor(vim.o.lines * 0.7))
	local row              = math.floor((vim.o.lines - height) / 2 - 1)
	local col              = math.floor((vim.o.columns - width) / 2)

	local win              = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = title,
		title_pos = "center",
	})

	vim.wo[win].cursorline = true

	local function current_name()
		local lnum = vim.api.nvim_win_get_cursor(win)[1]
		local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or ""
		return vim.trim(line)
	end

	vim.keymap.set("n", "<CR>", function()
		local name = current_name()
		if name ~= "" then
			vim.api.nvim_win_close(win, true)
			on_enter(name)
		end
	end, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end,
		{ buffer = buf, nowait = true, silent = true })
	vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end,
		{ buffer = buf, nowait = true, silent = true })

	-- yank current name
	vim.keymap.set("n", "y", function()
		local name = current_name()
		if name ~= "" then
			vim.fn.setreg('"', name)
			vim.api.nvim_echo({ { "yanked: " .. name, "ModeMsg" } }, false, {})
		end
	end, { buffer = buf, nowait = true, silent = true })
end

-- Rendering ------------------------------------------------------------------

---@param uvname string
---@param src_url string
---@param sig string
---@param body string[]
local function render_doc(uvname, src_url, sig, body)
	local lines = {
		"# " .. uvname,
		"",
		"C signature",
		"",
		"```c",
		sig,
		"```",
		"",
		"Summary",
		"",
	}
	if #body == 0 then
		lines[#lines + 1] = "(no summary available)"
	else
		for i = 1, #body do
			lines[#lines + 1] = tostring(body[i] or "")
		end
	end
	lines[#lines + 1] = ""
	lines[#lines + 1] = "Source"
	lines[#lines + 1] = ""
	lines[#lines + 1] = src_url

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
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

-- Core fetchers --------------------------------------------------------------

--- Fetch and show doc window for uvname.
---@param uvname string
local function fetch_and_show(uvname)
	local idx = get_genindex()
	if not idx then
		vim.notify("[uvdoc] genindex unavailable; try :h luvref.txt", vim.log.levels.WARN)
		return
	end
	local href = find_uv_href(idx, uvname)
	if not href then
		vim.notify(string.format("[uvdoc] not found in index: %s", uvname), vim.log.levels.WARN)
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

--- Fetch and insert only the C signature at cursor for uvname.
---@param uvname string
local function fetch_and_insert_signature(uvname)
	local idx = get_genindex()
	if not idx then
		vim.notify("[uvdoc] genindex unavailable; try :h luvref.txt", vim.log.levels.WARN)
		return
	end
	local href = find_uv_href(idx, uvname)
	if not href then
		vim.notify(string.format("[uvdoc] not found in index: %s", uvname), vim.log.levels.WARN)
		return
	end
	local rst_url  = BASE .. html_href_to_rst(href)
	local rst, err = http_get(rst_url)
	if not rst then
		vim.notify("[uvdoc] failed to fetch RST: " .. (err or "unknown"), vim.log.levels.WARN)
		return
	end
	local sig = (extract_c_function(rst, uvname))
	if type(sig) ~= "string" or sig == "" then
		vim.notify("[uvdoc] could not extract signature for: " + uvname, vim.log.levels.WARN)
		return
	end
	local block = { "```c", sig, "```" }
	vim.api.nvim_put(block, "l", true, true)
end

-- Public API -----------------------------------------------------------------

--- Show docs for an exact uv_* or fuzzy query.
---@param name string|nil
function M.doc(name)
	local raw = name or vim.fn.expand("<cword>")
	if not raw or raw == "" then
		vim.notify("[uvdoc] no name given", vim.log.levels.WARN)
		return
	end

	-- Exact?
	local looks_exact = raw:match("^uv_%w+$")
			or raw:match("^vim%.uv%.%w+$")
			or raw:match("^vim%.loop%.%w+$")

	if looks_exact then
		fetch_and_show(normalize_to_uv(raw))
		return
	end

	-- Fuzzy
	local cands = candidates_for(raw)
	if #cands == 0 then
		vim.notify("[uvdoc] no matches for query: " .. raw, vim.log.levels.INFO)
	elseif #cands == 1 then
		fetch_and_show(cands[1])
	else
		open_list(cands, "libuv: " .. raw, function(sel) fetch_and_show(sel) end)
	end
end

--- List all or filtered functions and open on <CR>.
---@param query string|nil
function M.list(query)
	local cands = candidates_for(query)
	if #cands == 0 then
		vim.notify("[uvdoc] no matches", vim.log.levels.INFO)
		return
	end
	open_list(cands, "libuv index" .. (query and (" [" .. query .. "]") or ""), function(sel)
		fetch_and_show(sel)
	end)
end

--- Alias to list(all).
function M.pick()
	M.list(nil)
end

--- Insert only the signature at cursor for exact or fuzzy.
---@param name string|nil
function M.here(name)
	local raw = name or vim.fn.expand("<cword>")
	if not raw or raw == "" then
		vim.notify("[uvdoc] no name given", vim.log.levels.WARN)
		return
	end
	local looks_exact = raw:match("^uv_%w+$")
	if looks_exact then
		fetch_and_insert_signature(raw)
		return
	end
	local cands = candidates_for(raw)
	if #cands == 0 then
		vim.notify("[uvdoc] no matches for query: " .. raw, vim.log.levels.INFO)
	elseif #cands == 1 then
		fetch_and_insert_signature(cands[1])
	else
		open_list(cands, "insert signature [" .. raw .. "]", function(sel)
			fetch_and_insert_signature(sel)
		end)
	end
end

--- Clear in-session caches (genindex + function list).
function M.cache_clear()
	GENINDEX_HTML = nil
	INDEX_FUNCTIONS = nil
	vim.notify("[uvdoc] cache cleared", vim.log.levels.INFO)
end

---@param opts UVDocConfig|nil
function M.setup(opts)
	CFG = vim.tbl_deep_extend("force", CFG, opts or {})
end

--------------------
-- Inititalisierung
--------------------

M.setup({ open = "float" })

-- Open docs for an exact or fuzzy name (falls back to a list if ambiguous)
vim.api.nvim_create_user_command("UVDoc", function(cmd)
	if #cmd.args > 0 then M.doc(cmd.args) else M.doc() end
end, { nargs = "?", desc = "Show libuv C signature+summary (fuzzy supported)" })

-- Line-based list UI, optionally filtered (e.g. :UVDocList loop)
vim.api.nvim_create_user_command("UVDocList", function(cmd)
	M.list(#cmd.args > 0 and cmd.args or nil)
end, { nargs = "?", desc = "List libuv functions and open with <CR>" })

-- Full index picker (alias to UVDocList without filter)
vim.api.nvim_create_user_command("UVDocPick", function()
	M.pick()
end, { desc = "Pick a libuv function from the full index" })

-- Insert only the C function signature at cursor (fuzzy allowed)
vim.api.nvim_create_user_command("UVDocHere", function(cmd)
	M.here(#cmd.args > 0 and cmd.args or nil)
end, { nargs = "?", desc = "Insert libuv C signature at cursor" })

vim.api.nvim_create_user_command("UVDocCacheClear", function()
	M.cache_clear()
end, { desc = "Clear uvdoc caches" })

-- After placing lua/uvdoc.lua in your runtimepath:
-- local ok, uvdoc = pcall(require, "uvdoc")
-- if ok then
--   uvdoc.setup({ open = "float" })
--
--   -- Open docs for an exact or fuzzy name (falls back to a list if ambiguous)
--   vim.api.nvim_create_user_command("UVDoc", function(cmd)
--     if #cmd.args > 0 then uvdoc.doc(cmd.args) else uvdoc.doc() end
--   end, { nargs = "?", desc = "Show libuv C signature+summary (fuzzy supported)" })
--
--   -- Line-based list UI, optionally filtered (e.g. :UVDocList loop)
--   vim.api.nvim_create_user_command("UVDocList", function(cmd)
--     uvdoc.list(#cmd.args > 0 and cmd.args or nil)
--   end, { nargs = "?", desc = "List libuv functions and open with <CR>" })
--
--   -- Full index picker (alias to UVDocList without filter)
--   vim.api.nvim_create_user_command("UVDocPick", function()
--     uvdoc.pick()
--   end, { desc = "Pick a libuv function from the full index" })
--
--   -- Insert only the C function signature at cursor (fuzzy allowed)
--   vim.api.nvim_create_user_command("UVDocHere", function(cmd)
--     uvdoc.here(#cmd.args > 0 and cmd.args or nil)
--   end, { nargs = "?", desc = "Insert libuv C signature at cursor" })
-- end


return M
