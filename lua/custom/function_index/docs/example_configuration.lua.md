-- Example configuration for function_index
-- Place this in your Neovim config (e.g., lua/plugins/function_index.lua)

return {
  "your-username/function_index",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- or "ibhagwan/fzf-lua"
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("custom.function_index").setup({
      -- Cache settings
      cache = {
        enabled = true,
        dir = vim.fn.stdpath("cache") .. "/function_index",
        ttl_seconds = 3600, -- Cache expires after 1 hour
      },

      -- Indexing behavior
      indexing = {
        auto_rebuild_on_save = false, -- Set to true for auto-rebuild (may slow down saves)
        exclude_patterns = {
          "node_modules/",
          ".git/",
          "build/",
          "dist/",
          "target/",
          "__pycache__/",
          "*.min.js",
          "*.min.css",
          ".venv/",
          "vendor/",
        },
        max_file_size_kb = 1024, -- Skip files larger than 1MB
        follow_symlinks = false,
      },

      -- Language support (enable/disable per language)
      languages = {
        lua = true,
        python = true,
        javascript = true,
        typescript = true,
        go = true,
        rust = true,
        c = true,
        cpp = true,
        java = false, -- Disabled by default (enable if needed)
        ruby = false,
        php = false,
      },

      -- UI customization
      ui = {
        show_language_icons = true, -- Requires nerd fonts
        show_function_types = true, -- Show [L], [M], [E], etc.
        group_by_file = false, -- Group entries by filename
        default_picker = "telescope", -- "telescope" or "fzf"
      },
    })

    -- Keymaps
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- Basic pickers
    map("n", "<leader>pf", "<cmd>FunctionIndexTelescope<cr>", vim.tbl_extend("force", opts, {
      desc = "Find functions (Telescope)",
    }))

    map("n", "<leader>ff", "<cmd>FunctionIndexFzfLua<cr>", vim.tbl_extend("force", opts, {
      desc = "Find functions (fzf-lua)",
    }))

    -- Pre-filled searches
    map("n", "<leader>pg", function()
      require("custom.function_index").pick_cword()
    end, vim.tbl_extend("force", opts, {
      desc = "Find function under cursor",
    }))

    map("n", "<leader>pc", function()
      require("custom.function_index").pick_clipboard()
    end, vim.tbl_extend("force", opts, {
      desc = "Find function from clipboard",
    }))

    -- Cache management
    map("n", "<leader>pr", "<cmd>FunctionIndexRebuild<cr>", vim.tbl_extend("force", opts, {
      desc = "Rebuild function index",
    }))

    map("n", "<leader>px", "<cmd>FunctionIndexClearCache<cr>", vim.tbl_extend("force", opts, {
      desc = "Clear function index cache",
    }))

    map("n", "<leader>pi", "<cmd>FunctionIndexStats<cr>", vim.tbl_extend("force", opts, {
      desc = "Show index statistics",
    }))
  end,
}

-- ================================================================
-- Alternative: Manual setup (without lazy.nvim)
-- ================================================================

-- In your init.lua or plugin file:
--
-- require("custom.function_index").setup({
--   -- Your config here
-- })
--
-- -- Add keymaps
-- vim.keymap.set("n", "<leader>pf", "<cmd>FunctionIndexTelescope<cr>", {
--   desc = "Find functions",
-- })

-- ================================================================
-- Health check
-- ================================================================

-- Run :checkhealth function_index to verify setup

-- ================================================================
-- Usage Examples
-- ================================================================

-- 1. Basic search
--    :FunctionIndexTelescope (or :FunctionIndexFzfLua)

-- 2. Search for word under cursor
--    Place cursor on a function name, press <leader>pg

-- 3. Search from clipboard
--    Copy a function name, press <leader>pc

-- 4. Programmatic search
--    :lua require("custom.function_index").pick_with_query("my_function")

-- 5. Rebuild cache
--    :FunctionIndexRebuild

-- 6. Check cache stats
--    :FunctionIndexStats

-- 7. Clear cache
--    :FunctionIndexClearCache
