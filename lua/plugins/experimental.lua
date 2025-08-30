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
					clear_in_insert_mode = true,                -- clears all images in insert mode
					only_render_image_at_cursor = true,         -- defaults to false; only renders the image by the cursor
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
}
