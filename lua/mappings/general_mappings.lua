---@module 'mappings.general'
-- General purpose keymaps (F1 disable, save, esc helpers).

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  for _, mode in ipairs({ "n", "i", "v", "t", "c" }) do
    map(mode, "<F1>", "<Nop>", { desc = "[General] Disable F1" })
  end

  map("n", "<leader><Esc>", ":qa!<CR>", { desc = "[General] Force quit all" })
  map({ "n", "i", "v", "t" }, "<C-s>", "<cmd>w<CR>", { desc = "[General] Save file" })
  map({ "i", "v", "t" }, "jk", "<Esc>", { desc = "[General] Exit to normal mode" })
end

return M
