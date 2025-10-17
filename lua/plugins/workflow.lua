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
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        INFO = { icon = " ", color = "info" },
        DEBUG = { icon = " ", color = "hint" },
        TODO = { icon = " ", color = "info" },
        ROADMAP = { icon = " ", color = "info" },
        AUDIT = {
          icon = " ",
          color = "audit",
          alt = { "VERIFY", "REVIEW", "DOUBLECHECK", "QC", "CHECK", "CHECKIT", "RECHECK", "VALIDATE" },
        },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
        EXP = { icon = "🔬", color = "test", alt = { "EXPERIMENT", "EXPERIMENTAL" } },
        REF = { icon = "󰁨 ", color = "hint", alt = { "REFACTOR", "REWRITE", "CLEANUP", "IMPROVE", "RESTRUCTURE" } },
        ADD = { icon = " ", color = "info", alt = { "EXT", "NEXT", "FUTURE", "ENHANCE", "HOOK" } },
        WATCH = { icon = " ", color = "warning", alt = { "MONITOR", "OBSERVE", "TRACK", "INSPECT", "SURVEILLANCE" } },
      },

			-- BUG: wird nicht mehr gehighlgihted wenn ich das benutze
		--   highlight = {
    --     multiline = true,
    --     pattern = [[\b(KEYWORDS):]], -- default for code
    --     comments_only = true, -- default for code
    --     keyword = "wide",
    --     after = "fg",
    --     max_line_len = 400,
    --     exclude = {},
    --   },
    --   search = {
    --     command = "rg",
    --     args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
    --     pattern = [[\b(KEYWORDS):]],
    --   },
    -- },
    --
    -- config = function(_, opts)
    --   -- initial setup for code files
    --   require("todo-comments").setup(opts)
    --
    --   -- prepare markdown-specific options
    --   local md_opts = vim.deepcopy(opts)
    --   md_opts.highlight = md_opts.highlight or {}
    --   md_opts.search = md_opts.search or {}
    --
    --   -- relax comment-only restriction
    --   md_opts.highlight.comments_only = false
    --   -- highlight whole keyword and apply foreground color
    --   md_opts.highlight.keyword = "wide"
    --   md_opts.highlight.after = "fg"
    --   -- match keywords optionally followed by colon or blockquote note style
    --   md_opts.highlight.pattern = [[\b(KEYWORDS)\b:?\|\>\s*\[\!(KEYWORDS)\]]
    --   md_opts.search.pattern = [[\b(KEYWORDS)\b:?]]
    --
    --   local group = vim.api.nvim_create_augroup("TodoCommentsMarkdown", { clear = true })
    --
    --   -- apply markdown-specific setup when opening markdown files
    --   vim.api.nvim_create_autocmd({ "FileType" }, {
    --     group = group,
    --     pattern = { "markdown", "md" },
    --     callback = function()
    --       require("todo-comments").setup(md_opts)
    --     end,
    --   })
    --
    --   -- restore defaults when leaving markdown buffers
    --   vim.api.nvim_create_autocmd({ "BufWinLeave", "BufUnload" }, {
    --     group = group,
    --     pattern = { "*.md", "*.markdown" },
    --     callback = function()
    --       require("todo-comments").setup(opts)
    --     end,
    --   })
    -- end,
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

  {
    "uga-rosa/translate.nvim",
    lazy = false,
    config = function()
      require("config.translate")
    end,
  },
}
