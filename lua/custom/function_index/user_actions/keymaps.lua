---@module 'custom.function_index.user_actions.keymaps'

local M = {}

function M.attach()
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
end

return M
