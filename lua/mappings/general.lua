---@module 'mappings.general'

local M = {}

function M.setup()
  local map = vim.g.__map_helper
  map("n", "<C-z>", "gg<S-v>G", { desc = "[General] Select all" })
  -- map({ "n", "i", "v", "t" }, "<C-s>", function()
  --   if vim.fn.mode() ~= "n" then
  --     vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  --   end
  --   vim.cmd "silent! w!"
  -- end, { desc = "[General] Save file silently" })

  map({ "n", "i", "v", "t" }, "<C-s>", "<cmd>w<CR>", { desc = "[General] Save file" }) -- C-s in insert mode is lsp.signature_help()
  map({ "i", "v", "t" }, "jk", "<Esc>", { desc = "[General] Exit to normal mode" })

  map("n", "+", "<C-a>", { desc = "[Number] Increment" }) -- AUDIT: EIgenes increment ? cycle...
  map("n", "-", "<C-x>", { desc = "[Number] Decrement" })
  map("n", "x", '"_x', { desc = "[Edit] Delete char without yanking" })
  map("n", "dw", 'vb"_d', { desc = "[Edit] Delete word backwards without yanking" })
  map({ "n", "i", "v", "t", "c" }, "<F1>", "<Nop>", { desc = "[General] Disable F1", silent = true })
end

return M
