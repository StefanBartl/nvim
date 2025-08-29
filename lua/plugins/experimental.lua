---@module 'plugins.experimental'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {

	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
		-- optional: lazy-load with Telescope command
		keys = {
			{
				"<leader>tfb",
				function()
					-- ensure telescope is loaded, then load extension and open it
					local ok, telescope = pcall(require, "telescope")
					if not ok then
						vim.notify("telescope.nvim not available", vim.log.levels.WARN)
						return
					end
					pcall(telescope.load_extension, "file_browser")
					telescope.extensions.file_browser.file_browser()
				end,
				desc = "Telescope File Browser"
			},
		},
		config = function()
			-- safe to call repeatedly; pcall prevents hard errors
			local ok, telescope = pcall(require, "telescope")
			if ok then pcall(telescope.load_extension, "file_browser") end
		end,
	},

	{
		"otavioschwanck/fzf-lua-explorer.nvim",
		dependencies = { "ibhagwan/fzf-lua" },
		keys = {
			{ "<leader>.", "<cmd>lua require('fzf-lua-explorer').explorer()<cr>", desc = "Explorer" }
		},
		config = function()
			require("fzf-lua-explorer").setup()
		end
	},

}
