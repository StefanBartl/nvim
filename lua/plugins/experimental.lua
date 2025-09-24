---@module 'plugins.experimental'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {

  {
    "adelarsq/image_preview.nvim",
    event = "VeryLazy",
    config = function()
      require("image_preview").setup()
    end,
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

      -- 2) Your keymaps (unchanged)
      vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
      vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
      vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
      vim.keymap.set("n", "<C-c", "<cmd>AutolistRecalculate<cr>")
      vim.keymap.set("n", "<leader>cn", require("autolist").cycle_next_dr, { expr = true })
      vim.keymap.set("n", "<leader>cp", require("autolist").cycle_prev_dr, { expr = true })

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

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      picker = { enabled = false },
      dim = { enabled = true },
      profiler = { enabled = true },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = false },
    },
  },
}
