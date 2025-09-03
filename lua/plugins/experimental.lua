---@module 'plugins.experimental'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {

	{
		"3rd/image.nvim",
		opts = {
			backend = "wezterm",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = true,           -- clears all images in insert mode
					only_render_image_at_cursor = true,    -- defaults to false; only renders the image by the cursor
					only_render_image_at_cursor_mode = "popup", -- "popup" or "inline", defaults to "popup"
				},
			}
		},
	},

	{
		'adelarsq/image_preview.nvim',
		event = 'VeryLazy',
		config = function()
			require("image_preview").setup()
		end
	},

	-- Automatic list continuation and formatting for neovim, powered by lua (NOT only for markdown)
	{
		"gaoDean/autolist.nvim",
		ft = {
			"markdown",
			"text",
			"tex",
			"plaintex",
			"norg",
		},
		config = function()
			require("autolist").setup()

			vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
			vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
			vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
			vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
			vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
			vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<cr><CR>")
			vim.keymap.set("n", "<C-r>", "<cmd>AutolistRecalculate<cr>")
			-- cycle list types with dot-repeat
			vim.keymap.set("n", "<leader>cn", require("autolist").cycle_next_dr, { expr = true })
			vim.keymap.set("n", "<leader>cp", require("autolist").cycle_prev_dr, { expr = true })
		end,
	},
}
