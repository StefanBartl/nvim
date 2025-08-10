---@module 'mappings.git'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "[Diffview] Open" })
  map("n", "<leader>dc", ":DiffviewClose<CR>", { desc = "[Diffview] Close" })
  map("n", "<leader>dh", ":DiffviewFileHistory<CR>", { desc = "[Diffview] File History" })
end

return M
