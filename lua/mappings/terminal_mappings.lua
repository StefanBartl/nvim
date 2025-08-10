---@module 'mappings.terminal'

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  map("t", "<Esc>", "<C-\\><C-n>", { desc = "[Terminals] Exit terminal mode" })
  map("t", "<C-c>", "<C-\\><C-n>", { desc = "[Terminals] Exit terminal mode" })
end

return M
