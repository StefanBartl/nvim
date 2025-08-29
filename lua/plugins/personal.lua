---@module 'plugins.personal'
--- Personal and local development plugins (myterm, mygrep, cmdlog, etc.)

if not vim.env.REPOS_DIR then
	vim.notify("[PLUGINS PERSONAL] Environment variable 'REPOS_DIR' not set. Personal plugins not available.", 3)
	return {}
end

---@type LazyPluginSpec[]
return {

	{
		"StefanBartl/nvim-cmdlog",
		-- lazy = false,
		cmd = { "CmdlogOpen", "CmdlogSearch" }, -- or map keys
		-- keys = {
		-- 	{ "<leader>cl", "<cmd>CmdlogOpen<cr>", desc = "Cmdlog: Open" },
		-- },
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- do NOT hard-depend on telescope if you also support fzf-lua
      -- load whichever backend on demand in your code
			-- { "nvim-telescope/telescope.nvim" },
			-- { "ibhagwan/fzf-lua",             optional = true },
		},
		config = function()
			require("cmdlog").setup {
		  -- defer backend require until actually used
      picker = "telescope", -- or "fzf-lua"; choose default, load lazily in code
			}
		end,
	},

	-- nvim-containers: Manage container engines from Neovim
	-- {
	--   dir = vim.fs.joinpath(vim.env.REPOS_DIR, "/nvim-containers"),
	--   event = "VeryLazy",
	--   config = function()
	--     require("containers").setup({})
	--   end,
	-- },
	--
	-- nvim-cmdlog: Command history management (remote plugin)
	-- Optional: local dev version of cmdlog
	-- {
	--   dir = repo("nvim-cmdlog"),
	--   cond = exists(repo("nvim-cmdlog")),
	--   config = function()
	--     require("cmdlog").setup({ picker = "telescope" })
	--   end,
	-- },

	--[[

    -- reposcope.nvim: GitHub repo explorer
    {
      dir = repo("reposcope.nvim"),
      cond = exists(repo("reposcope.nvim")),
      name = "reposcope",
      event = "VeryLazy",
      config = function()
        require("reposcope.init").setup({})
      end,
    },

    ]]
	--

	-- myterm.local: Custom terminal interface with layout switching
	--[[
    {
      name = "myterm.local",
      dir = myterm_local_dir(),
      cond = exists(myterm_local_dir()),
      lazy = false,
      config = function()
        require("custom.myterm")
      end,
    },
    ]]
	--

	-- mygrep.nvim: Grep interface with memory, history, favorites
	-- {
	--   dir = repo("mygrep.nvim"),
	--   cond = exists(repo("mygrep.nvim")),
	--   name = "mygrep",
	--   lazy = false,
	--   config = function()
	--     require("mygrep").setup({
	--       tool_picker_style = "ui",
	--     })
	--   end,
	-- },
}
