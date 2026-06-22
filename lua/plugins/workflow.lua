---@module 'plugins.workflow'
--- Tools for organizing development workflow (TODOs, annotations, reminders).

---@type LazyPluginSpec[]
return {

  {
    "folke/todo-comments.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      signs = true,
      keywords = require("config.todo_comments.keywords"),
      colors = require("config.todo_comments.colors.strong"),
    },
    keys = {
      {
        "<leader>ST",
        function()
          local snacks = require("snacks")
          if snacks and snacks.picker then
            snacks.picker.todo_comments()
          else
            vim.notify("Snacks not loaded", vim.log.levels.WARN)
          end
        end,
        desc = "Todo",
      },
      {
        "<leader>sT",
        function()
          local snacks = require("snacks")
          local KEYWORDS = require("config.todo_comments.keywords")
          if snacks and snacks.picker and KEYWORDS then
            snacks.picker.todo_comments({ keywords = KEYWORDS })
          else
            vim.notify("Snacks not loaded or custom keywords table does not exist", vim.log.levels.WARN)
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

 -- {
 --   "wakatime/vim-wakatime",
 --   lazy = false,
 -- },

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
      require("autolist").setup()

      local map = require("lib.nvim.map")
      -- map("i", "<tab>", "<cmd>AutolistTab<cr>", { desc = "[Autolist] Indent list item" })
      -- map("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>", { desc = "[Autolist] Unindent list item" })
      map(
        "i",
        "<CR>",
        "<CR><cmd>AutolistNewBullet<cr>",
        { desc = "[Autolist] New bullet on next line" }
      )
      map("n", "o", "o<cmd>AutolistNewBullet<cr>", { desc = "[Autolist] New bullet below" })
      map("n", "O", "O<cmd>AutolistNewBulletBefore<cr>", { desc = "[Autolist] New bullet above" })
      map(
        "n",
        "<leader>rc",
        "<cmd>AutolistRecalculate<cr>",
        { desc = "[Autolist] Recalculate ordered list" }
      )
      map(
        "n",
        "<leader>cn",
        require("autolist").cycle_next_dr,
        { desc = "[autolist] Cycle list type forward", expr = true }
      )
      map(
        "n",
        "<leader>cp",
        require("autolist").cycle_prev_dr,
        { desc = "[autolist] Cycle list type backward", expr = true }
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
      end, { desc = "[autolist] Toggle checkbox or insert blank line" })

      -- Auto-renumber before saving supported filetypes
      ---@class AutolistAutoRecalcOpts
      ---@field group_name string  -- augroup name
      local opts = { group_name = "AutolistAutoRecalc" }

      -- ---@type integer
      local augroup = vim.api.nvim_create_augroup(opts.group_name, { clear = true })

      -- Create buffer-local BufWritePre only for autolist filetypes.
      -- Using FileType ensures the buffer has its correct 'filetype' and autolist is loaded.
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        pattern = { "markdown", "text", "tex", "plaintex", "norg" },
        desc = "[autolist] set up pre-save renumbering for this buffer",
        callback = function(ev)
          -- Buffer-local pre-save hook: renumber just before write, so the file on disk is already correct.
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = ev.buf,
            desc = "[autolist] renumber list before saving",
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
