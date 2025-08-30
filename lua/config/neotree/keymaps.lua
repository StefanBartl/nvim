---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.
--- Split into:
---   1) Window mappings (Neo-tree-only, require `state`)
---   2) Source-specific mappings (filesystem/buffers/git/document_symbols)
---   3) Extra buffer-local bindings applied on `NeoTreeBufferEnter` (e.g. <C-o>)
---
--- All mappings are applied only to the Neo-tree buffer and defined late,
--- ensuring they take precedence over plugin defaults.

local M = {}

local uv = vim.uv or vim.loop

-- ========= Shared helpers (used by both commands and window mappings) =========

--- Check if an executable is available in $PATH.
---@param bin string
---@return boolean
local function has_exec(bin)
	return vim.fn.executable(bin) == 1
end

--- Compute a window-scoped temp PNG path; avoids clashes across multiple Neo-tree windows.
---@param winid integer
---@return string
local function tmp_png_for(winid)
	local cache = vim.fn.stdpath("cache") -- portable cache dir
	return ("%s/neotree_pdf_preview_%d.png"):format(cache, winid)
end

--- Return true if file path seems to be an image file supported by image_preview.nvim.
---@param p string
---@return boolean
local function is_image_file(p)
	local exts = { ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp" }
	p = (p or ""):lower()
	for _, ext in ipairs(exts) do
		if p:sub(- #ext) == ext then
			return true
		end
	end
	return false
end

--- Return true if file is a PDF.
---@param p string
---@return boolean
local function is_pdf_file(p)
	p = (p or ""):lower()
	return p:sub(-4) == ".pdf"
end

--- Render a specific page of a PDF to a PNG file.
--- Tries ImageMagick 'convert' first, then poppler 'pdftoppm'.
---@param pdf_path string
---@param page integer  -- zero-based page index
---@param out_png string
---@return boolean ok, string|nil errmsg
local function render_pdf_page(pdf_path, page, out_png)
	-- Prefer ImageMagick
	if has_exec("convert") then
		-- -density 150 for readable text; '[N]' to select page N (0-based)
		local cmd = { "convert", "-density", "150", ("%s[%d]"):format(pdf_path, page), out_png }
		local _ = vim.fn.system(cmd)
		if vim.v.shell_error == 0 then return true end
		return false, "convert failed"
	end

	-- Fallback: poppler (pdftoppm outputs without extension; we want PNG)
	if has_exec("pdftoppm") then
		local base = out_png:gsub("%.png$", "")
		local cmd = { "pdftoppm", "-png", "-f", tostring(page + 1), "-l", tostring(page + 1), pdf_path, base }
		local _ = vim.fn.system(cmd)
		if vim.v.shell_error == 0 and vim.fn.filereadable(base .. ".png") == 1 then
			return true
		end
		return false, "pdftoppm failed"
	end

	return false, "no renderer (need convert or pdftoppm)"
end

--- Read total page count for a PDF.
--- Prefers ImageMagick 'identify', falls back to poppler 'pdfinfo'.
---@param pdf_path string
---@return integer|nil
local function read_pdf_page_count(pdf_path)
	if has_exec("identify") then
		-- "%n" prints number of images/pages in the file
		local result = vim.fn.systemlist({ "identify", "-format", "%n", pdf_path })
		if vim.v.shell_error == 0 and result[1] then
			local n = tonumber(result[1])
			if n and n > 0 then return n end
		end
	end
	if has_exec("pdfinfo") then
		local lines = vim.fn.systemlist({ "pdfinfo", pdf_path })
		if vim.v.shell_error == 0 then
			for _, line in ipairs(lines) do
				-- Example: "Pages:          12"
				local n = line:match("^Pages:%s+(%d+)$")
				n = tonumber(n)
				if n and n > 0 then return n end
			end
		end
	end
	return nil
end

--- Set a window-local statusline showing the current PDF page/total on the right.
--- We keep a backup to restore later.
---@param winid integer
---@param pdf_path string
---@param page integer  -- zero-based
---@param total integer
local function set_pdf_statusline(winid, pdf_path, page, total)
	-- Save previous statusline once per window
	if vim.w[winid].__pdf_stl_saved == nil then
		vim.w[winid].__pdf_stl_saved = vim.wo[winid].statusline
	end
	-- Keep it simple; left shows file basename; right shows "PDF X/Y".
	local basename = vim.fn.fnamemodify(pdf_path, ":t")
	-- "%=" splits left/right; trailing spaces keep a bit of padding.
	local stl = (" %s %%= PDF %d/%d "):format(basename, page + 1, total)
	vim.wo[winid].statusline = stl
end

--- Clear the window-local statusline override, restoring previous (e.g. lualine).
---@param winid integer
local function clear_pdf_statusline(winid)
	local prev = vim.w[winid].__pdf_stl_saved
	if prev ~= nil then
		vim.wo[winid].statusline = prev
	else
		-- Empty string => fallback to global 'statusline'
		vim.wo[winid].statusline = ""
	end
	vim.w[winid].__pdf_stl_saved = nil
end

--- Exported so you can call it from other mappings (e.g. on <Esc>).
---@param winid integer
function M.clear_pdf_statusline_for_window(winid)
	clear_pdf_statusline(winid)
end

---@return string
local function cwd()
	return uv.cwd() or vim.fn.getcwd()
end

local function hide_preview_safe(_)
	pcall(function()
		require("neo-tree.sources.common.preview").hide()
	end)
end

function M.window()
	return {
		-- basic
		["q"]             = "close_window",
		["?"]             = "noop",
		["g?"]            = "show_help",
		["<leader>"]      = "noop",

		["<Esc>"]         = function(state)
			require("neo-tree.sources.filesystem").reset_search(state, true)
			require("neo-tree.sources.filesystem.lib.filter_external").cancel()
			pcall(function() require("neo-tree.sources.common.preview").hide() end)
			vim.cmd("nohlsearch")
			-- also clear any PDF statusline override for this window
			local winid = state.winid or vim.api.nvim_get_current_win()
			require("config.neotree.keymaps").clear_pdf_statusline_for_window(winid)
		end,

		-- open/close (safe variants)
		["<2-LeftMouse>"] = "open",

		["<CR>"]          = function(state)
			local node = state.tree:get_node()
			if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
				state.commands.toggle_node(state)
				return
			end
			hide_preview_safe(state)
			if pcall(require, "window-picker") then
				state.commands.open_with_window_picker(state)
			else
				state.commands.open(state)
			end
		end,

		["SV"]            = function(state)
			hide_preview_safe(state)
			if pcall(require, "window-picker") then
				state.commands.split_with_window_picker(state)
			else
				state.commands.open_split(state)
			end
		end,

		["SG"]            = function(state)
			hide_preview_safe(state)
			if pcall(require, "window-picker") then
				state.commands.vsplit_with_window_picker(state)
			else
				state.commands.open_vsplit(state)
			end
		end,

		["l"]             = function(state)
			local node = state.tree:get_node()
			if node.type == "directory" or (node:has_children() and not node:is_expanded()) then
				state.commands.toggle_node(state)
			else
				state.commands.open(state)
			end
		end,
		["h"]             = "close_node",
		["C"]             = "close_node",
		["z"]             = "close_all_nodes",
		["<C-r>"]         = "refresh",

		-- splits/tabs
		["s"]             = "noop",
		["sv"]            = "open_split",
		["sg"]            = "open_vsplit",
		["st"]            = "open_tabnew",

		-- source switching
		["<S-Tab>"]       = "prev_source",
		-- ["<Tab>"] = "next_source", -- intentionally not used here, reserved for preview

		-- file ops via neo-tree clipboard
		["c"]             = "copy_to_clipboard",
		["x"]             = "cut_to_clipboard",
		["p"]             = "paste_from_clipboard",
		["r"]             = "rename",

		-- create/delete
		["dd"]            = "delete",
		["a"]             = { "add", nowait = true, config = { show_path = "relative" } },
		["A"]             = { "add_directory", config = { show_path = "relative" } },
		-- ["m"] = { "move", config = { show_path = "relative" } },

		-- preview: Tab toggles floating preview
		["<Tab>"]         = "smart_preview",
		-- Page-wise scrolling on PageDown/PageUp
		["<PageDown>"]    = { "scroll_preview", config = { direction = -10 } }, -- page down (~10 lines)
		["<PageUp>"]      = { "scroll_preview", config = { direction = 10 } }, -- page up   (~10 lines)
		-- Fine-grained scrolling on <C-f>/<C-b>
		["<C-f>"]         = { "scroll_preview", config = { direction = -1 } }, -- down one line
		["<C-b>"]         = { "scroll_preview", config = { direction = 1 } }, -- up one line
		-- bigger steps on Shift+PageDown/Shift+PageUp
		-- ["<S-PageDown>"]  = { "scroll_preview", config = { direction = -30 } },
		-- ["<S-PageUp>"]    = { "scroll_preview", config = { direction = 30 } },

		-- PDF scrolling
		["<S-PageDown>"]  = "pdf_next_page",
		["<S-PageUp>"]    = "pdf_prev_page",


		-- helpers: copy paths to system clipboard
		["[p"] = {
			function(state)
				local node = state.tree:get_node()
				local path = node and (node.path or node:get_id()) or ""
				if path == "" then
					vim.notify("no path", vim.log.levels.WARN)
					return
				end
				vim.fn.setreg("+", path, "c")
				vim.notify(("copied: %s"):format(path), vim.log.levels.INFO)
			end,
			desc = "Copy absolute path (+)",
		},

		["]p"] = {
			function(state)
				local node = state.tree:get_node()
				local path = node and (node.path or node:get_id()) or ""
				if path == "" then
					vim.notify("no path", vim.log.levels.WARN)
					return
				end
				local base = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
				vim.fn.setreg("+", base, "c")
				vim.notify(("copied: %s"):format(base), vim.log.levels.INFO)
			end,
			desc = "Copy base (dir) path (+)",
		},

		-- resize helper
		["w"]  = function(state)
			local normal = state.window.width
			local large = normal * 1.9
			local small = math.floor(normal / 1.6)
			local cur_width = state.win_width
			local new_width = normal
			if cur_width > normal then
				new_width = small
			elseif cur_width == normal then
				new_width = large
			end
			vim.cmd(new_width .. " wincmd |")
		end,

		["Y"]  = {
			function(state)
				local node = state.tree:get_node()
				local path = node:get_id()
				vim.fn.setreg("+", path, "c")
			end,
			desc = "Copy Path to Clipboard",
		},

		["O"]  = {
			function(state)
				require("lazy.util").open(state.tree:get_node().path, { system = true })
			end,
			desc = "Open with System Application",
		},

		["M"]  = {
			function(state)
				local is_wsl = require "lib.is_wsl"

				local mod
				if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
					mod = "config.neotree.open_fm.win"
				elseif is_wsl() then
					mod = "config.neotree.open_fm.wsl"
				else
					mod = "config.neotree.open_fm.unix"
				end

				local ok, fm = pcall(require, mod)
				if not ok then
					vim.notify("open_fm module not found: " .. mod, vim.log.levels.ERROR)
					return
				end
				fm.open(state)
			end,
			desc = "Open in system file manager",
		},

		["+"]  = {
			function(state)
				local node = state.tree:get_node()
				local path = node and (node.path or node:get_id()) or ""
				if path == "" then
					vim.notify("no path under cursor", vim.log.levels.WARN)
					return
				end
				local dir = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
				local ok, err = pcall(vim.api.nvim_set_current_dir, dir)
				if not ok then
					vim.notify(("cd failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
					return
				end
				local ok_cmd, _ = pcall(require, "neo-tree.command")
				if ok_cmd then
					require("neo-tree.command").execute { source = "filesystem", dir = dir, reveal = true }
				end
				vim.notify(("cwd → %s"):format(dir), vim.log.levels.INFO)
			end,
			desc = "Set Neovim cwd to node and focus Neo-tree there",
		},

		["-"]  = {
			function(state)
				local current_root = state.path
				if not current_root or current_root == "" then
					local node = state.tree:get_node()
					local path = node and (node.path or node:get_id()) or ""
					if path == "" then
						vim.notify("no path under cursor", vim.log.levels.WARN)
						return
					end
					current_root = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
				end
				local parent = vim.fn.fnamemodify(current_root, ":h")
				if parent == current_root or parent == "" then
					vim.notify("already at top-level directory", vim.log.levels.WARN)
					return
				end
				local ok, err = pcall(vim.api.nvim_set_current_dir, parent)
				if not ok then
					vim.notify(("cd failed: %s"):format(tostring(err)), vim.log.levels.ERROR)
					return
				end
				local ok_cmd, cmd = pcall(require, "neo-tree.command")
				if ok_cmd and cmd then
					cmd.execute { source = "filesystem", dir = parent, reveal = true }
				end
				vim.notify(("cwd → %s"):format(parent), vim.log.levels.INFO)
			end,
			desc = "Up one level: set cwd to parent and focus Neo-tree there",
		},

		["G"]  = {
			function(state)
				require("config.neotree.fzf_grep_picker").live_grep_node_dir(state)
			end,
			desc = "fzf-lua: live_grep in node directory (Windows/WSL/macOS/Linux)",
		},
	}
end

-- ========= Commands exposed to Neo-tree =========

--- Commands table for Neo-tree's `opts.commands`.
---@return table<string, fun(state: table)>
function M.commands()
	return {
		--- Smart preview:
		--- * Images → show via image_preview.nvim (WezTerm inline)
		--- * PDFs   → render current page and show; expose per-window page state
		--- * Other  → fallback to the source's toggle_preview
		---@param state table
		smart_preview = function(state)
			local node = state.tree:get_node()
			local path = node and (node.path or node:get_id()) or ""
			local winid = state.winid or vim.api.nvim_get_current_win()

			if node and node.type == "file" and is_image_file(path) then
				-- Image: directly preview and clear any PDF statusline from previous previews
				clear_pdf_statusline(winid)
				require("image_preview").PreviewImage(path)
				return
			end

			if node and node.type == "file" and is_pdf_file(path) then
				-- Initialize per-buffer PDF state if missing
				if not vim.b.pdf_page_count or not vim.b.pdf_src or vim.b.pdf_src ~= path then
					vim.b.pdf_src = path
					vim.b.pdf_page = 0
					vim.b.pdf_page_count = read_pdf_page_count(path) or 1
				end

				local png = tmp_png_for(winid)
				local ok, err = render_pdf_page(path, vim.b.pdf_page, png)
				if not ok then
					clear_pdf_statusline(winid)
					vim.notify(("PDF render failed (%s)"):format(err or "unknown"), vim.log.levels.ERROR)
					return
				end

				-- Show image and update statusline
				require("image_preview").PreviewImage(png)
				set_pdf_statusline(winid, path, vim.b.pdf_page, vim.b.pdf_page_count)
				return
			end

			-- Non-PDF/Non-image: restore statusline and defer to the current source preview
			clear_pdf_statusline(winid)
			local source = state.source or "filesystem"
			local ok, mod = pcall(require, "neo-tree.sources." .. source .. ".commands")
			if ok and mod.toggle_preview then
				mod.toggle_preview(state, { use_float = true })
			else
				vim.notify(("No preview available for source: %s"):format(source), vim.log.levels.WARN)
			end
		end,

		--- Next PDF page (clamped to last page).
		---@param state table
		pdf_next_page = function(state)
			local node = state.tree:get_node()
			if not node or not is_pdf_file(node.path) then return end
			local winid = state.winid or vim.api.nvim_get_current_win()

			local total = vim.b.pdf_page_count or read_pdf_page_count(node.path) or 1
			local nextp = math.min((vim.b.pdf_page or 0) + 1, total - 1)
			if nextp == (vim.b.pdf_page or 0) then
				-- Already at last page; still refresh statusline to be explicit.
				set_pdf_statusline(winid, node.path, nextp, total)
				return
			end

			vim.b.pdf_page = nextp
			local png = tmp_png_for(winid)
			local ok = select(1, render_pdf_page(node.path, vim.b.pdf_page, png))
			if ok then
				require("image_preview").PreviewImage(png)
				set_pdf_statusline(winid, node.path, vim.b.pdf_page, total)
			end
		end,

		--- Previous PDF page (clamped to zero).
		---@param state table
		pdf_prev_page = function(state)
			local node = state.tree:get_node()
			if not node or not is_pdf_file(node.path) then return end
			local winid = state.winid or vim.api.nvim_get_current_win()

			local total = vim.b.pdf_page_count or read_pdf_page_count(node.path) or 1
			local prevp = math.max((vim.b.pdf_page or 0) - 1, 0)
			if prevp == (vim.b.pdf_page or 0) then
				-- Already at first page; still refresh statusline to be explicit.
				set_pdf_statusline(winid, node.path, prevp, total)
				return
			end

			vim.b.pdf_page = prevp
			local png = tmp_png_for(winid)
			local ok = select(1, render_pdf_page(node.path, vim.b.pdf_page, png))
			if ok then
				require("image_preview").PreviewImage(png)
				set_pdf_statusline(winid, node.path, vim.b.pdf_page, total)
			end
		end,
	}
end

function M.filesystem()
	return {
		["d"] = "noop",
		["/"] = "noop",
		["f"] = "filter_on_submit",
		["F"] = "fuzzy_finder",
		["<C-c>"] = "clear_filter",
	}
end

function M.buffers()
	return {
		["dd"] = "buffer_delete",
	}
end

function M.git_status()
	return {
		["d"] = "noop",
		["dd"] = "delete",
	}
end

function M.document_symbols()
	return {
		["/"] = "noop",
		["F"] = "filter",
	}
end

-- Extra buffer-local bindings applied after Neo-tree buffer is ready.
-- These use `neo-tree.command` and do not require `state`.
function M.setup_autocmds()
	vim.api.nvim_create_autocmd("User", {
		pattern = "NeoTreeBufferEnter",
		callback = function(ev)
			local bufnr = ev.buf
			local ok_cmd, neo_cmd = pcall(require, "neo-tree.command")
			if not ok_cmd then
				return
			end

			local Root = require "utils.lv_project_root"

			local function reveal_at_root()
				neo_cmd.execute { source = "filesystem", dir = Root.get(0), reveal = true }
			end
			local function reveal_at_cwd()
				neo_cmd.execute { source = "filesystem", dir = cwd(), reveal = true }
			end

			-- Only in Neo-tree buffer; defined late → override plugin’s binds if duplicated.
			vim.keymap.set("n", "<C-o>", reveal_at_root, {
				buffer = bufnr,
				silent = true,
				nowait = true,
				desc = "Neo-tree: Reveal at project root",
			})

			-- GUIs may support <C-S-o>; terminals often don't.
			vim.keymap.set("n", "<C-S-o>", reveal_at_cwd, {
				buffer = bufnr,
				silent = true,
				nowait = true,
				desc = "Neo-tree: Reveal at cwd",
			})
		end,
	})
end

return M
