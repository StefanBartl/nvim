---@module 'plugins.fzf'
--- Fuzzy finding tools based on Telescope, fzf-lua, and optional tabbed UI (search.nvim)

---@type LazyPluginSpec[]
return {

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
