---@module 'plugins.misc'

---@type LazyPluginSpec[]
return {

	-- Harpoon: Efficient file and terminal navigation system
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"ibhagwan/fzf-lua",               -- optional, recommended for the <C-h> FZF menu
			"nvim-telescope/telescope.nvim",  -- optional, not required by the hardening layer
		},
		config = function()
			require("config.harpoon.hardening").setup()
			require("config.harpoon.persist_paths").setup({
				target_specs = {
					{ "$REPOS_DIR", "Notes",     "MyNotes",   "Notes.md" },
					{ "$REPOS_DIR", "Notes",     "Neovim",    "Neovim.md" },
					{ "$REPOS_DIR", "Notes",     "MyNotes",   "Wezterm.md" },
					{ "$NVIM_HOME", "lua",       "mynotes",   "spickzettel.md" },
				}
			}
			)
			require("config.harpoon.preview").install_alt_number_maps()
		end,
	},

	{
		"axieax/urlview.nvim",
		lazy = true,
		cmd = { "UrlView" },
		config = function()
			require("config.urlview.open_in_browser_integration").setup()
		end,
	},

	{
		"jghauser/mkdir.nvim",
		lazy = true,
	},
}
