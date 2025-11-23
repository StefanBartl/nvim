---@module 'plugins.workflow'
--- Tools for organizing development workflow (TODOs, annotations, reminders).

local KEYWORDS = require("config.todo_comments.keywords")

---@type LazyPluginSpec[]
return {

  -- Highlights TODO, FIX, HACK, etc. with signcolumn and Telescope support
  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Provide the opts here; lazy will hand them to the config function below.
    opts = {
      signs = true,
      colors = {
        audit = { "DiagnosticHint", "Type", "#00BFA5" },
      },
      keywords = KEYWORDS,
    },
    config = function(_, opts)
      local ok, mod = pcall(require, "config.todo_comments.setup")
      if ok and type(mod) == "table" and type(mod.setup) == "function" then
        mod.setup(opts)
        return
      end
      -- fallback: call todo.setup directly
      local todo_ok, todo = pcall(require, "todo-comments")
      if todo_ok then
        todo.setup(opts)
      end
    end,
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
