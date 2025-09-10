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

	-- {
	-- 	dir = [[E:\repos\objtrack]], -- Repo-Root mit lua/ darunter
	-- 	name = "objtrack",
	-- 	main = "objtrack",         -- lädt lua/objtrack/init.lua als Haupteinstieg
	-- 	lazy = false,              -- fürs Debuggen: hart beim Start laden
	-- 	config = function()
	-- 		require("objtrack").setup({
	-- 			view_mode = "float",
	-- 			prefer_telescope = true,
	-- 			auto_rescan = false,
	-- 			border = "rounded",
	-- 			max_preview_lines = 5000,
	-- 			blacklist_filetypes = { "help", "TelescopePrompt", "neo-tree", "lazy" },
	-- 			keymaps = { pick = "<leader>op", rescan = "<leader>os" },
	-- 		})
	-- 	end,
	-- },

	{
		-- dir = vim.fn.expand(vim.env.REPOS_DIR .. '/replacer'),
		"StefanBartl/replacer",
		lazy = true,
		cmd = "Replace",
		name = "replacer.nvim",
		main = "replacer",
		opts = {
			engine = "fzf",    -- "fzf" | "telescope"
			write_changes = true, -- true: sofort speichern, false: nur Buffer modifizieren
			confirm_all = true, -- vor "All" bestätigen
			preview_context = 3,
			hidden = true,
			exclude_git_dir = true,
			literal = true,
			smart_case = true,
			fzf = { winopts = { width = 0.85, height = 0.70 } },
			telescope = { layout_config = { width = 0.85, height = 0.70 } },
		},
	},


	{
		dir = vim.env.REPOS_DIR .. "/gopath.nvim", -- or "wkdsteve/gopath.nvim"
		opts = {
			-- Modi: "builtin" | "treesitter" | "lsp" | "hybrid"
			mode = "hybrid",

			-- Provider-Reihenfolge für "hybrid":
			-- 1) Treesitter-Pass (inkl. value_origin ⇒ springt zur Initialisierung)
			-- 2) LSP-Definition
			-- 3) Builtin (cfile, require-Pfad)
			order = { "treesitter", "lsp", "builtin" },

			-- LSP Sync Timeout in ms (kurz halten, um UI nie zu blocken)
			lsp_timeout_ms = 200,

			-- Sprachen: wenn `resolvers` fehlt/nil -> es werden ALLE Resolver für die Sprache genutzt.
			languages = {
				lua = {
					enable = true,
					-- resolvers = nil,  -- nil = alle (require_path, binding_index, alias_index, chain,
					--        value_origin, symbol_locator)
				},
				-- Beispiel für spätere Sprachen:
				-- typescript = { enable = true, resolvers = nil },
			},
		},
		cmd = { "GopathResolve", "GopathOpen", "GopathCopy", "GopathDebugUnderCursor" },
		keys = {
			{ "gP",  function() require("gopath").commands.resolve_and_open("edit") end,   desc = "gopath: open here" },
			{ "g|",  function() require("gopath").commands.resolve_and_open("window") end, desc = "gopath: open in split" },
			{ "g\\", function() vim.cmd("GopathOpen window_vsplit") end,                   desc = "gopath: open in vsplit" },
			{ "g}",  function() require("gopath").commands.resolve_and_open("tab") end,    desc = "gopath: open in tab" },
			{ "gY",  function() vim.cmd("GopathCopy") end,                                 desc = "gopath: copy path:line:col" },
			{ "g?",  function() vim.cmd("GopathDebugUnderCursor") end,                     desc = "gopath: debug under cursor" },
		},
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
