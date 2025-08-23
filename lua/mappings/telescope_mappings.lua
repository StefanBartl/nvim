---@module 'mappings.telescope'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>ts", ":Telescope<CR>", { desc = "[Telescope] UI" })

  -- Prompted grep
  map("n", "<leader>gs", function()
    local ok, tb = pcall(require, "telescope.builtin")
    if not ok then return end
    tb.grep_string({ search = vim.fn.input("Grep > ") })
  end, { desc = "[Telescope] Grep" })

  -- Insert-mode meta shortcuts (kept as in source)
  map("i", "<M-p>", function() pcall(require("telescope.builtin").find_files) end, { desc = "[Telescope] Prev cat" })
  map("i", "<M-n>", function() pcall(require("telescope.builtin").find_files) end, { desc = "[Telescope] Next cat" })

  map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "[Telescope] Live Grep" })
  map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "[Telescope] Find keymaps" })
  map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "[Telescope] Buffers" })
  map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "[Telescope] Help" })
  map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "[Telescope] Oldfiles" })
  map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "[Telescope] In Buffer" })
  map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "[Telescope] Git Commits" })
  map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "[Telescope] Git Status" })
  map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "[Telescope] Find Files" })
  map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "[Telescope] Find All Files" })

  map("n", "<leader>os", function() require("search").open() end, { desc = "[Telescope] Multi search UI" })
end

return M
