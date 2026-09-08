---@module 'plugins.workflow'
--- Tools for organizing development workflow (TODOs, annotations, reminders).

local notify = require("lib.nvim.notify").create("[plugins.workflow]")

---@type LazyPluginSpec[]
return {

  {
    "folke/todo-comments.nvim",
    -- The plugin highlights comments inside a buffer, so a buffer existing is
    -- the earliest moment it has anything to do. `lazy = false` cost 37 ms of
    -- startup (plus pulling plenary and nvim-web-devicons in with it) to be
    -- ready for a buffer that, on `nvim` with no file argument, never comes.
    -- On `nvim file.lua` BufReadPost fires during startup anyway, so nothing
    -- is deferred that would have been visible in the first paint.
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    -- A function, not a table: a table literal's `require` calls run during
    -- lazy's spec-import phase -- before the first paint, and regardless of
    -- whether the plugin ever loads. Behind a function they run when the
    -- plugin does.
    opts = function()
      return {
        signs = true,
        keywords = require("config.todo_comments.keywords"),
        colors = require("config.todo_comments.colors.strong"),
      }
    end,
    keys = {
      {
        "<leader>ST",
        function()
          local snacks = require("snacks")
          if snacks and snacks.picker then
            snacks.picker.todo_comments()
          else
            notify.warn("Snacks not loaded")
          end
        end,
        desc = "Todo",
      },
      {
        "<leader>sT",
        function()
          local snacks = require("snacks")
          -- `vim.tbl_keys`, not the table itself: the source's `keywords`
          -- is a list of keyword NAMES, which it filters against
          -- `todo-comments`' own name table. Handed the keyword table, each
          -- entry looked up was a `{ icon, color, alt }` value, nothing
          -- matched, and the search regex was built from an empty list.
          local KEYWORDS = vim.tbl_keys(require("config.todo_comments.keywords"))
          if snacks and snacks.picker and KEYWORDS then
            snacks.picker.todo_comments({ keywords = KEYWORDS })
          else
            notify.warn("Snacks not loaded or custom keywords table does not exist")
          end
        end,
        desc = "Todo/Fix/Fixme",
      },
    },
    config = function(_, opts)
      local ok, mod = pcall(require, "config.todo_comments")
      if ok and type(mod) == "table" and type(mod.setup) == "function" then
        mod.setup(opts)
        return
      end
      -- fallback:
      local todo_ok, todo = pcall(require, "todo-comments")
      if todo_ok then
        todo.setup(opts)
      end
    end,
  },

  {
    "NStefan002/screenkey.nvim",
    cmd = "Screenkey",
    lazy = true,
    version = "*",
  },

  -- translate.nvim replaced by the standalone language.nvim plugin
  -- (see lua/plugins/language.lua). Use :Translate.

  {
    "chrisbra/unicode.vim",
    cmd = {
      "UnicodeName",
      "UnicodeSearch",
      "UnicodeTable",
      "Digraphs",
    },
    keys = {
      { "uni", desc = "Show Unicode character info" },
    },
  },
}
