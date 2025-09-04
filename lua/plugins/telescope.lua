---@module 'plugins.fuzzy_finder'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

---@type LazyPluginSpec[]
return {

	-- Telescope: Main fuzzy finder with extensions (history wrapped in a single block)
	-- In your telescope spec (plugins/fuzzy_finder.lua)

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope-github.nvim",

			-- Install sqlite + smart_history only when it can actually work.
			-- On Windows default to false; allow opt-in via NVIM_SQLITE_FORCE=1.
			{
				"kkharji/sqlite.lua",
				cond = function()
					local is_installed = (vim.fn.executable("sqlite3") == 1)
					if not is_installed then
						return false
					end
					local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
					if is_win then
						vim.g.sqlite_clib_path = [[C:\tools\sqlite\sqlite3.dll]]
						return true
					end
				end,
			},
			{
				"nvim-telescope/telescope-smart-history.nvim",
				cond = function()
					-- local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)
					-- if is_win  and vim.env.NVIM_SQLITE_FORCE ~= "1" then
					-- 	return false
					-- end
					-- If not Windows or explicitly forced, still check that the sqlite module can be required.
					local ok = pcall(require, "sqlite")
					return ok
				end,
			},
		},
		cmd = "Telescope",
		opts = function(_, opts)
			opts = opts or {}
			-- Robust capability check: require('sqlite') must succeed AND
			local has_sqlite = pcall(require, "sqlite")

			-- History block with backend fallback
			local HISTORY = {
				backend    = has_sqlite and "sqlite" or "file",
				dir        = vim.fn.stdpath("data") .. "/databases",
				path       = "",
				limit      = 3000,
				extensions = {},
			}
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

			-- Only load smart_history if sqlite is truly available
			opts.extensions_list = { "fzf", "gh" }
			vim.list_extend(opts.extensions_list, HISTORY.extensions)
			return opts
		end,
		config = function(_, opts)
			local telescope = require("telescope")
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

	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },

		keys = {
			{
				"<leader>.",
				function()
					-- Load extension on demand and open with our defaults from setup()
					local ok, telescope = pcall(require, "telescope")
					if not ok then
						vim.notify("telescope.nvim not available", vim.log.levels.WARN)
						return
					end
					pcall(telescope.load_extension, "file_browser")
					telescope.extensions.file_browser.file_browser()
				end,
				desc = "Telescope File Browser (focus current buffer file)",
			},
		},

		config = function()
			local ok, telescope = pcall(require, "telescope")
			if not ok then return end

			telescope.setup({
				extensions = {
					file_browser = {
						-- Start im Verzeichnis der aktuellen Datei (wird automatisch expandiert)
						path = "%:p:h",
						-- Folder-Browser soll ebenfalls vom 'path' starten (nicht vom CWD)
						cwd_to_path = true,
						-- Aktuelle Datei im Browser selektieren/hervorheben (falls erreichbar)
						select_buffer = true,
						hidden = true,           -- Dotfiles anzeigen
						-- respect_gitignore = true -- Gitignore respektieren
						no_ignore = true, -- alles anzeigen
						follow_symlinks = true,
						display_stat = { date = true, size = true, mode = false },
						use_fd = true, -- perfomance durch fd
						git_status = true,
					},
				},
			})

			pcall(telescope.load_extension, "file_browser")
		end,
	}
}
