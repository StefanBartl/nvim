---@module 'mappings.telescope'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>os", function() require("search").open() end, { desc = "[Telescope] Multi search UI" })
  map("n", "<leader>ts", ":Telescope<CR>", { desc = "[Telescope] UI" })

  map("n", "<leader>tg", function()
    local ok, tb = pcall(require, "telescope.builtin")
    if not ok then return end
    tb.grep_string({ search = vim.fn.input("Grep > ") })
  end, { desc = "[Telescope] Grep" })

  map("n", "<leader>tlg", "<cmd>Telescope live_grep<CR>", { desc = "[Telescope] Live Grep" })
  map("n", "<leader>tfk", "<cmd>Telescope keymaps<CR>", { desc = "[Telescope] Find keymaps" })
  map("n", "<leader>tbu", "<cmd>Telescope buffers<CR>", { desc = "[Telescope] Buffers" })
  map("n", "<leader>thelp", "<cmd>Telescope help_tags<CR>", { desc = "[Telescope] Help" })
  map("n", "<leader>told", "<cmd>Telescope oldfiles<CR>", { desc = "[Telescope] Oldfiles" })
  map("n", "<leader>tcb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "[Telescope] In Buffer" })
  map("n", "<leader>tff", "<cmd>Telescope find_files<cr>", { desc = "[Telescope] Find Files" })
  map("n", "<leader>tfa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "[Telescope] Find All Files" })
end

return M
