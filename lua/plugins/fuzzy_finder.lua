---@module 'plugins.fuzzy_finder'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

---@type LazyPluginSpec[]
return {

	-- Telescope: Main fuzzy finder with extensions (history wrapped in a single block)
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope-github.nvim",

			-- === HISTORY BLOCK (dependencies, optional but recommended) ===
			-- SQLite-backed prompt history (smart, per-cwd/picker aware).
			-- Remove these two lines if you prefer a plain text file backend.
			{ "nvim-telescope/telescope-smart-history.nvim", lazy = true },
			{ "kkharji/sqlite.lua",                          lazy = true },
			-- === END HISTORY BLOCK =======================================
		},
		cmd = "Telescope",
		opts = function(_, opts)
			opts = opts or {}

			-- Detect sqlite capability once
			local has_sqlite = pcall(require, "sqlite")

			-- === HISTORY BLOCK (begin) ===================================
			---@class TelescopeHistoryBlock
			---@field backend '"sqlite"'|'"file"'   -- Switch storage backend
			---@field dir string                    -- Base directory for history files
			---@field path string                   -- Concrete file path (resolved by ensure())
			---@field limit integer                 -- Max history items
			---@field extensions string[]           -- Extensions to load for this backend
			local HISTORY = {
				backend    = has_sqlite and "sqlite" or "file",
				dir        = vim.fn.stdpath("data") .. "/databases",
				path       = "",
				limit      = 3000,
				extensions = {},
			}

			---Ensure the history path exists and set extension list accordingly.
			---@return string path
			function HISTORY.ensure()
				if HISTORY.backend == "sqlite" then
					if vim.fn.isdirectory(HISTORY.dir) == 0 then vim.fn.mkdir(HISTORY.dir, "p") end
					HISTORY.path = HISTORY.dir .. "/telescope_history.sqlite3"
					HISTORY.extensions = { "smart_history" }
				else
					local pdir = vim.fn.stdpath("data") .. "/picker-history"
					if vim.fn.isdirectory(pdir) == 0 then vim.fn.mkdir(pdir, "p") end
					HISTORY.path = pdir .. "/_global.txt"
					HISTORY.extensions = {}
				end
				return HISTORY.path
			end

			-- Merge defaults exactly once; no call to non-existent HISTORY.defaults()
			local actions = require("telescope.actions")
			opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
				history = { path = HISTORY.ensure(), limit = HISTORY.limit },
				sorting_strategy = "ascending",
				layout_config = { prompt_position = "top" },
				mappings = {
					i = {
						["<C-p>"] = actions.cycle_history_prev,
						["<C-n>"] = actions.cycle_history_next,
					},
				},
			})

			-- Extensions to load; add history-related ones if sqlite is available
			opts.extensions_list = { "fzf", "gh" }
			vim.list_extend(opts.extensions_list, HISTORY.extensions)

			return opts
		end,
		config = function(_, opts)
			local telescope = require "telescope"
			telescope.setup(opts)
			for _, ext in ipairs(opts.extensions_list or {}) do
				pcall(telescope.load_extension, ext)
			end
		end,
	},

	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = (function()
			if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
				-- Windows: use CMake build
				return table.concat({
					"cmake -S. -B build -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release",
					"cmake --build build --config Release",
					"cmake --install build --prefix build",
				}, " && ")
			else
				-- POSIX: just use make
				return "make"
			end
		end)(),
	},

	-- search.nvim: Telescope UI
	{
		"FabianWirth/search.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			local search = require "search"
			local builtin = require "telescope.builtin"
			local all_drives = require("utils.search_all_drives").build_tabs(builtin) -- <-- NEW

			search.setup {
				mappings = { next = "<Tab>", prev = "<S-Tab>" },

				append_tabs = {
					{
						"Commits",
						builtin.git_commits,
						available = function()
							return vim.fn.isdirectory ".git" == 1
						end,
					},
				},

				tabs = vim.list_extend({
					{
						"Files",
						function(opts)
							opts = opts or {}
							if vim.fn.isdirectory ".git" == 1 then
								builtin.git_files(opts)
							else
								builtin.find_files(opts)
							end
						end,
					},
					{ name = "All Files", tele_func = builtin.find_files, tele_opts = { no_ignore = true, hidden = true } },
					{ name = "Grep",      tele_func = builtin.live_grep },
					{ name = "Buffers",   tele_func = builtin.buffers },
				}, all_drives),

				collections = {
					git = {
						initial_tab = 1,
						tabs = {
							{ name = "Branches", tele_func = builtin.git_branches },
							{ name = "Commits",  tele_func = builtin.git_commits },
							{ name = "Stashes",  tele_func = builtin.git_stash },
						},
					},
				},
			}
		end,
	},

	-- fzf-lua: Alternative fuzzy finder based on fzf
	{
		"ibhagwan/fzf-lua",
		lazy = true,
		opts = {
			keymap = {
				fzf = {
					["ctrl-p"] = "next-history",
					["ctrl-n"] = "prev-history",
				},
			},
			fzf_opts = {
				["--history"] = vim.fn.stdpath "data" .. "/fzf-history",
			},
		},
	},
}
