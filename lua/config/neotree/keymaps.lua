---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.
--- Adds smart image/PDF preview with opaque backgrounds and PDF page navigation.
--- This file fixes:
---   1) Neo-tree mapping shape (no nested `window = { mappings = { ... } }` inside mappings)
---   2) PDF previews rendered with a non-transparent background (flattened to Normal.bg or fallback)
---
--- Requirements:
---   - Terminal that supports kitty/wezterm image protocol (e.g. WezTerm)
---   - image_preview.nvim plugin
---   - ImageMagick (`convert`,`identify`) or Poppler (`pdftoppm`,`pdfinfo`)

local M = {}

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

--- Get editor background color from `Normal` highlight (hex like "#1e1e2e"); fallback if unset.
---@param opt? "white"|"black"
---@return string
local function get_normal_bg_hex(opt)
	if opt == "white" then return "#ffffff" end
	if opt == "black" then return "#111111" end
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
	if ok and hl and hl.bg then
		local r = bit.rshift(bit.band(hl.bg, 0xFF0000), 16)
		local g = bit.rshift(bit.band(hl.bg, 0x00FF00), 8)
		local b = bit.band(hl.bg, 0x0000FF)
		return string.format("#%02x%02x%02x", r, g, b)
	end
	return "#111111"
end

--- Render a specific page of a PDF to PNG with an OPAQUE background.
---@param pdf_path string
---@param page integer  -- zero-based
---@param out_png string
---@return boolean ok, string|nil errmsg
local function render_pdf_page(pdf_path, page, out_png)
  -- English comments: prefer Poppler naming base-<page>.png and use proper concatenation.
  local bg = get_normal_bg_hex("white")
  local density = "150"

  -- Decide ImageMagick binary (Windows uses 'magick')
  local function convert_bin()
    local os = vim.loop.os_uname().sysname
    if os == "Windows_NT" and has_exec("magick") then return "magick" end
    return has_exec("convert") and "convert" or nil
  end

  -- Try ImageMagick first (works cross-platform if 'magick' is used on Windows)
  local conv = convert_bin()
  if conv then
    local cmd = {
      conv,
      "-density", density,
      string.format("%s[%d]", pdf_path, page), -- 0-based page index for IM
      "-background", bg, "-alpha", "remove", "-alpha", "off",
      "-flatten", "-strip",
      string.format("PNG24:%s", out_png),
    }
    local _ = vim.fn.system(cmd)
    if vim.v.shell_error == 0 then return true end
  end

  -- Fallback: Poppler
  if has_exec("pdftoppm") then
    local base = out_png:gsub("%.png$", "")
    local cmd = { "pdftoppm", "-png", "-f", tostring(page + 1), "-l", tostring(page + 1), pdf_path, base }
    local _ = vim.fn.system(cmd)
    -- pdftoppm names output as "<base>-<pagenum>.png"
    local produced = string.format("%s-%d.png", base, page + 1)
    if vim.v.shell_error ~= 0 or vim.fn.filereadable(produced) ~= 1 then
      return false, "pdftoppm failed"
    end
    if conv then
      local fix = {
        conv, produced,
        "-background", bg, "-alpha", "remove", "-alpha", "off",
        "-flatten", "-strip", string.format("PNG24:%s", out_png),
      }
      local _ = vim.fn.system(fix)
      if vim.v.shell_error == 0 then return true end
      vim.fn.rename(produced, out_png) -- fall back to pdftoppm result
      return true
    else
      vim.fn.rename(produced, out_png)
      return true
    end
  end

  return false, conv and "convert failed" or "no renderer (need convert/magick or pdftoppm)"
end

--- Read total page count for a PDF.
--- Prefers ImageMagick 'identify', falls back to Poppler 'pdfinfo'.
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
				local n = tonumber(line:match("^Pages:%s+(%d+)$"))
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
	if vim.w[winid].__pdf_stl_saved == nil then
		vim.w[winid].__pdf_stl_saved = vim.wo[winid].statusline
	end
	local basename = vim.fn.fnamemodify(pdf_path, ":t")
	local stl = (" %s %%= PDF %d/%d "):format(basename, page + 1, total) -- "%=" splits left/right
	vim.wo[winid].statusline = stl
end

--- Clear the window-local statusline override, restoring previous (e.g. lualine).
---@param winid integer
local function clear_pdf_statusline(winid)
	local prev = vim.w[winid].__pdf_stl_saved
	if prev ~= nil then
		vim.wo[winid].statusline = prev
	else
		vim.wo[winid].statusline = "" -- fallback to global 'statusline'
	end
	vim.w[winid].__pdf_stl_saved = nil
end

--- Exported so you can call it from other mappings (e.g. on <Esc>).
---@param winid integer
function M.clear_pdf_statusline_for_window(winid)
	clear_pdf_statusline(winid)
end

--- Safe hide of Neo-tree's floating preview, ignoring errors.
---@param _ any
local function hide_preview_safe(_)
	pcall(function()
		require("neo-tree.sources.common.preview").hide()
	end)
end

-- ========= Window mappings (no nested tables; every key maps to a function/command) =========

---@return table<string, any>
function M.window()
	return {
		-- basics
		["q"]             = "close_window",
		["?"]             = "show_help",
		["g?"]            = "noop",
		["<leader>"]      = "noop",
    ["P"] = "image_wezterm",
		-- clear filter, preview and search highlight
		["<Esc>"]         = function(state)
			require("neo-tree.sources.filesystem").reset_search(state, true)
			require("neo-tree.sources.filesystem.lib.filter_external").cancel()
			hide_preview_safe(state)
			vim.cmd("nohlsearch")
			local winid = state.winid or vim.api.nvim_get_current_win()
			require("config.neotree.keymaps").clear_pdf_statusline_for_window(winid)
		end,

		["<2-LeftMouse>"] = "open",

		["<CR>"]          = function(state)
			local node = state.tree:get_node()

			-- 1) expand/collapse directories
			if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
				state.commands.toggle_node(state)
				return
			end

			hide_preview_safe(state)

			-- 2) PDFs: open via pdf_preview module (own split/buffer)
			local handled = false
			do
				local ok, pp = pcall(require, "config.image_preview.pdf.buffer")
				if ok and pp and type(pp.open_from_neotree) == "function" then
					handled = pp.open_from_neotree(state) -- returns true if it opened a PDF preview
				end
			end
			if handled then
				return
			end

			-- 3) non-PDFs: normal open (prefer window-picker if present)
			if pcall(require, "window-picker") then
				state.commands.open_with_window_picker(state)
			else
				state.commands.open(state)
			end
		end,

		-- background buffer add (no focus change, Neo-tree stays)
    ["<S-CR>"] = "open_badd",
    -- Fallback, falls <S-CR> im Terminal nicht erkannt wird:
    ["gb"]     = "open_badd",

		-- splits/tabs
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

		-- splits/tabs shorthand
		["s"]             = "noop",
		["sv"]            = "open_split",
		["sg"]            = "open_vsplit",
		["st"]            = "open_tabnew",

		-- source switching
		["<S-Tab>"]       = "prev_source",

		-- file ops via neo-tree clipboard
		["c"]             = "copy_to_clipboard",
		["x"]             = "cut_to_clipboard",
		["p"]             = "paste_from_clipboard",
		["r"]             = "rename",

		-- create/delete
		["dd"]            = "delete",
		["a"]             = { "add", nowait = true, config = { show_path = "relative" } },
		["A"]             = { "add_directory", config = { show_path = "relative" } },

		-- preview toggle + scrolling (Neo-tree preview)
		["<Tab>"]         = "smart_preview",
		["<PageDown>"]    = { "scroll_preview", config = { direction = -10 } },
		["<PageUp>"]      = { "scroll_preview", config = { direction = 10 } },
		["<C-f>"]         = { "scroll_preview", config = { direction = -1 } },
		["<C-b>"]         = { "scroll_preview", config = { direction = 1 } },

		-- PDF page navigation (Shift+PageUp/Down)
		["<S-PageDown>"]  = "pdf_next_page",
		["<S-PageUp>"]    = "pdf_prev_page",

		-- helpers: copy paths to system clipboard
		["[p"]            = {
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

		["]p"]            = {
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

		["]r"]            = {
			--- Copy the node's relative path to the system clipboard (+).
			--- Base preference: project root (utils.lv_project_root) → fallback to current working directory.
			---@param state table
			function(state)
				local node = state.tree:get_node()
				local path = node and (node.path or node:get_id()) or ""
				if path == "" then
					vim.notify("no path", vim.log.levels.WARN)
					return
				end
				local base = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
				local ok_root, Root = pcall(require, "utils.lv_project_root")
				if ok_root and type(Root.get) == "function" then
					base = Root.get(0) or base
				end
				local rel = vim.fn.relpath(path, base)
				vim.fn.setreg("+", rel, "c")
				vim.notify(("copied: %s"):format(rel), vim.log.levels.INFO)
			end,
			desc = "Copy relative path (+) (root→node or cwd→node)",
		},

		["[r"]            = {
			--- Copy the node's base directory (relative) to the system clipboard (+).
			--- Base preference: project root (utils.lv_project_root) → fallback to current working directory.
			---@param state table
			function(state)
				local node = state.tree:get_node()
				local path = node and (node.path or node:get_id()) or ""
				if path == "" then
					vim.notify("no path", vim.log.levels.WARN)
					return
				end
				local dir = (vim.fn.isdirectory(path) == 1) and path or vim.fn.fnamemodify(path, ":h")
				local base = (vim.uv or vim.loop).cwd() or vim.fn.getcwd()
				local ok_root, Root = pcall(require, "utils.lv_project_root")
				if ok_root and type(Root.get) == "function" then
					base = Root.get(0) or base
				end
				local rel = vim.fn.relpath(dir, base)
				vim.fn.setreg("+", rel, "c")
				vim.notify(("copied: %s"):format(rel), vim.log.levels.INFO)
			end,
			desc = "Copy relative base dir (+) (root→dir or cwd→dir)",
		},

		-- resize helper
		["w"]             = function(state)
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

		["Y"]             = {
			function(state)
				local node = state.tree:get_node()
				local path = node:get_id()
				vim.fn.setreg("+", path, "c")
			end,
			desc = "Copy Path to Clipboard",
		},

		["O"]             = {
			function(state)
				require("lazy.util").open(state.tree:get_node().path, { system = true })
			end,
			desc = "Open with System Application",
		},

		["M"]             = {
			function(state)
				local is_wsl = require "lib.is_wsl"
				local mod
				if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
					mod = "config.neotree.open_fm.win"
				elseif is_wsl() then
					mod = "config.neotree.open_fm.wsl"
				else
					mod = "config.neotree.open_fm.unix_ubuntu"
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

		["+"]             = {
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

		["-"]             = {
			function(state)
				require("config.neotree.updir").up_one_level(state)
			end,
			desc = "Up one level (in-place) and adjust CWD",
		},

		["grep"]          = {
			function(state)
				require("config.neotree.fzf_grep_picker").live_grep_node_dir(state)
			end,
			desc = "fzf-lua: live_grep in node directory (Windows/WSL/macOS/Linux)",
		},
	}
end

-- ========= Commands exposed to Neo-tree (register via opts.commands = KM.commands()) =========

--- Commands table for Neo-tree's `opts.commands`.
---@return table<string, fun(state: table)>
function M.commands()
	return {
		image_wezterm = function(state)
        local node = state.tree:get_node()
        if node.type == "file" then
          require("image_preview").PreviewImage(node.path)
        end
      end,
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
				clear_pdf_statusline(winid)
				require("image_preview").PreviewImage(path)
				return
			end

			if node and node.type == "file" and is_pdf_file(path) then
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

		--- Open the selected file into the buffer list without leaving Neo-tree.
		--- * Files: :badd + bufload + buflisted=true
		---@param state table
		open_badd = function(state)
			local node = state.tree:get_node()
			if not node then return end

			if node.type ~= "file" then
				-- Keep directory UX consistent (expand/collapse) and stay in Neo-tree
				state.commands.toggle_node(state)
				return
			end

			local path = node.path or node:get_id()
			if not path or path == "" then
				vim.notify("No path under cursor", vim.log.levels.WARN)
				return
			end

			-- Add buffer silently and load it so it shows up in buffer pickers immediately
			local bufnr = vim.fn.bufadd(path) -- creates buffer if needed, does not display it
			pcall(vim.fn.bufload, bufnr)    -- read file into the buffer
			pcall(function() vim.bo[bufnr].buflisted = true end)

			-- Optional: small notification (can be removed)
			vim.notify(("Buffered: %s"):format(vim.fn.fnamemodify(path, ":t")), vim.log.levels.INFO)
		end,

		--- Open file in a window but immediately jump focus back to Neo-tree.
		--- Use this variant if man wants the file to be shown in its window, yet keep the tree focused.
		---@param state table
		open_keep_focus = function(state)
			local node = state.tree:get_node()
			if not node then return end
			if node.type ~= "file" then
				state.commands.toggle_node(state)
				return
			end
			local win = state.winid or vim.api.nvim_get_current_win()
			if pcall(require, "window-picker") then
				state.commands.open_with_window_picker(state)
			else
				state.commands.open(state)
			end
			vim.schedule(function()
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_set_current_win(win) -- return focus to Neo-tree window
				end
			end)
		end,
	}
end

-- ========= Source-specific extra mappings (unchanged) =========

---@return table<string, any>
function M.filesystem()
	return {
		["d"]     = "noop",
		["/"]     = "noop",
		["f"]     = "filter_on_submit",
		["F"]     = "fuzzy_finder",
		["<C-c>"] = "clear_filter",
	}
end

---@return table<string, any>
function M.buffers()
	return {
		["dd"] = "buffer_delete",
	}
end

---@return table<string, any>
function M.git_status()
	return {
		["d"]  = "noop",
		["dd"] = "delete",
	}
end

---@return table<string, any>
function M.document_symbols()
	return {
		["/"] = "noop",
		["F"] = "filter",
	}
end

return M
