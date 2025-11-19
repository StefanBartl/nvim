---@module 'plugins.experimental'
--- Plugins curently in test phase

---@type LazyPluginSpec[]
return {

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
      map("i", "<tab>", "<cmd>AutolistTab<cr>", { desc = "[Autolist] Indent list item" })
      map("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>", { desc = "[Autolist] Unindent list item" })
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

  {
    "ellisonleao/glow.nvim",
    cmd = "Glow",
    ft = { "markdown", "md" },
    config = function()
      ---@diagnostic disable-next-line "incomplete setup"
      require("glow").setup({
        glow_path = vim.fn.exepath("glow"), -- auto-detect from PATH
        border = "shadow",
        style = "dark",
        width = 120,
      })
    end,
  },

  {
    "chrisbra/unicode.vim",
    -- Optional: lazy loading configuration
    cmd = {
      "UnicodeName",
      "UnicodeSearch",
      "UnicodeTable",
      "Digraphs",
    },
    keys = {
      { "ga", desc = "Show Unicode character info" },
    },
    -- Optional: configuration function
    config = function()
      -- Custom keymaps or settings can be added here
      -- vim.g.Unicode_no_default_mappings = 1  -- Disable default mappings if needed
    end,
  },

  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Uncomment whichever supported plugin(s) you use
      -- "nvim-tree/nvim-tree.lua",
      "nvim-neo-tree/neo-tree.nvim",
      -- "simonmclean/triptych.nvim"
    },
    config = function()
      local lsp_file_ops = require("lsp-file-operations")
      lsp_file_ops.setup()

      -- Initialize global LSP capabilities
      local default_capabilities = vim.lsp.protocol.make_client_capabilities()
      -- Merge in the capabilities provided by nvim-lsp-file-operations
      local file_ops_capabilities = require("lsp-file-operations").default_capabilities()
      -- Deep merge both tables
      local merged_capabilities = vim.tbl_deep_extend("force", default_capabilities, file_ops_capabilities)
      -- Store the merged capabilities in the global vim.lsp config
      vim.lsp.protocol.make_client_capabilities = function()
        return merged_capabilities
      end

      vim.api.nvim_create_user_command("LspFileOpsRename", function()
        lsp_file_ops.rename()
      end, { desc = "Rename current file via LSP" })

      vim.api.nvim_create_user_command("LspFileOpsRemove", function()
        lsp_file_ops.remove()
      end, { desc = "Delete current file via LSP" })

      vim.api.nvim_create_user_command("LspFileOpsCreate", function()
        lsp_file_ops.create()
      end, { desc = "Create new file via LSP" })

      vim.api.nvim_create_user_command("LspFileOpsMove", function()
        lsp_file_ops.move()
      end, { desc = "Move current file via LSP" })
    end,
  },

  {
    "nvim-mini/mini.icons",
    version = "*",
    config = function()
      require("mini.icons").setup()
    end,
  },
}
