---@module 'plugins.workflow'
--- Tools for organizing development workflow (TODOs, annotations, reminders).

---@type LazyPluginSpec[]
return {

	-- Highlights TODO, FIX, HACK, etc. with signcolumn and Telescope support
	{
		"folke/todo-comments.nvim",
		lazy = false,
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			signs = true,
			colors = {
				audit = { "DiagnosticHint", "Type", "#00BFA5" },
			},
			keywords = {
				FIX     = {
					icon = " ",
					color = "error",
					alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
				},
				INFO    = { icon = " ", color = "info" },
				DEBUG   = { icon = " ", color = "hint" },
				TODO    = { icon = " ", color = "info" },
				AUDIT= {
					icon = " ",
					color = "audit",
					alt = { "VERIFY", "REVIEW", "DOUBLECHECK", "QC", "CHECK", "CHECKIT", "RECHECK", "VALIDATE" },
				},
				HACK    = { icon = " ", color = "warning" },
				WARN    = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
				PERF    = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
				NOTE    = { icon = " ", color = "hint", alt = { "INFO" } },
				TEST    = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
				EXP     = { icon = "🔬", color = "test", alt = { "EXPERIMENT", "EXPERIMENTAL" } },
				REF     = { icon = "󰁨 ", color = "hint", alt = { "REFACTOR", "REWRITE", "CLEANUP", "IMPROVE", "RESTRUCTURE" } },
				ADD     = { icon = " ", color = "info", alt = { "EXT", "NEXT", "FUTURE", "ENHANCE", "HOOK" } },
				WATCH   = { icon = " ", color = "warning", alt = { "MONITOR", "OBSERVE", "TRACK", "INSPECT", "SURVEILLANCE" } },
			},
		},
	},

	{
		"wakatime/vim-wakatime",
		lazy = false,
	},


  {
    "NStefan002/screenkey.nvim",
		cmd = "Screenkey",
    lazy = true,
    version = "*",
  },
}
