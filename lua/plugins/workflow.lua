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
      -- 1) Basic setup
      require("autolist").setup()

      -- 2) Your keymaps
      local map = require("lib.map")
      -- map("i", "<tab>", "<cmd>AutolistTab<cr>", { desc = "[Autolist] Indent list item" })
      -- map("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>", { desc = "[Autolist] Unindent list item" })
      map("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>", { desc = "[Autolist] New bullet on next line" })
      map("n", "o", "o<cmd>AutolistNewBullet<cr>", { desc = "[Autolist] New bullet below" })
      map("n", "O", "O<cmd>AutolistNewBulletBefore<cr>", { desc = "[Autolist] New bullet above" })
      map("n", "<leader>rc", "<cmd>AutolistRecalculate<cr>", { desc = "[Autolist] Recalculate ordered list" })
      map(
        "n",
        "<leader>cn",
        require("autolist").cycle_next_dr,
        { desc = "[Autolist] Cycle list type forward", expr = true }
      )
      map(
        "n",
        "<leader>cp",
        require("autolist").cycle_prev_dr,
        { desc = "[Autolist] Cycle list type backward", expr = true }
      )
      map("n", "<CR>", function()
        local line = vim.api.nvim_get_current_line()

        if line:match("%[[ x]%]") then
          vim.cmd("AutolistToggleCheckbox")
        else
          -- Original mapping: 0i<CR><Esc>k
          local keys = vim.api.nvim_replace_termcodes("0i<CR><Esc>k", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end
      end, { desc = "[Autolist] Toggle checkbox or insert blank line" })

      -- 3) Auto-renumber before saving supported filetypes
      ---@class AutolistAutoRecalcOpts
      ---@field group_name string  -- augroup name
      local opts = { group_name = "AutolistAutoRecalc" }

      ---@type integer
      local augroup = vim.api.nvim_create_augroup(opts.group_name, { clear = true })

      -- Create buffer-local BufWritePre only for autolist filetypes.
      -- Using FileType ensures the buffer has its correct 'filetype' and autolist is loaded.
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = { "markdown", "text", "tex", "plaintex", "norg" },
        desc = "autolist.nvim: set up pre-save renumbering for this buffer",
        callback = function(ev)
          -- Buffer-local pre-save hook: renumber just before write, so the file on disk is already correct.
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = ev.buf,
            desc = "autolist.nvim: renumber list before saving",
            callback = function()
              -- Use the user command; 'silent!' avoids noise if not applicable.
              vim.cmd([[silent! AutolistRecalculate]])
            end,
          })
        end,
      })
    end,
  },
}
