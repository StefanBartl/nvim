---@module 'mappings.git'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "[Diffview] Open" })
  map("n", "<leader>dc", ":DiffviewClose<CR>", { desc = "[Diffview] Close" })
  map("n", "<leader>dh", ":DiffviewFileHistory<CR>", { desc = "[Diffview] File History" })
  map('n', '<Leader>bf', function()
    vim.cmd('windo diff' .. (vim.wo.diff and 'off' or 'this'))
  end, { desc = 'Diff Windows in Tab' })
end

return M
