---@module 'config.neotree.keymaps'
--- Centralized, buffer-local Neo-tree keymaps that override defaults consistently.

local M = {}

-- ========= Shared helpers (used by both commands and window mappings) =========

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
		-- clear filter, preview and search highlight
		["<Esc>"]         = function(state)
			require("neo-tree.sources.filesystem").reset_search(state, true)
			require("neo-tree.sources.filesystem.lib.filter_external").cancel()
			hide_preview_safe(state)
			vim.cmd("nohlsearch")
		end,
		["<Tab>"]   = "toggle_preview",
		["<2-LeftMouse>"] = "open",

		["<CR>"]          = function(state)
			local node = state.tree:get_node()

			-- 1) expand/collapse directories
			if node and (node.type == "directory" or (node:has_children() and not node:is_expanded())) then
				state.commands.toggle_node(state)
				return
			end

			hide_preview_safe(state)

			-- 2) normal open (prefer window-picker if present)
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
		["<PageDown>"]    = { "scroll_preview", config = { direction = -10 } },
		["<PageUp>"]      = { "scroll_preview", config = { direction = 10 } },
		["<C-f>"]         = { "scroll_preview", config = { direction = -1 } },
		["<C-b>"]         = { "scroll_preview", config = { direction = 1 } },

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
