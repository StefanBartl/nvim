--==================================================
--=== COPILOT (GitHub Copilot) =====================
--==================================================

local map = vim.keymap.set

map("i", "<C-y>", 'copilot#Accept("<CR>")',
  { silent = true, expr = true, noremap = true, desc = "Accept Copilot suggestion" })
map("i", "<C-l>", "<Plug>(copilot-accept-word)", { noremap = false, desc = "Accept next word of suggestion" })
map("i", "<C-k>", "<Plug>(copilot-accept-line)", { noremap = false, desc = "Accept next line of suggestion" })
map("i", "<C-r>", "<Plug>(copilot-dismiss)", { noremap = false, desc = "Dismiss Copilot suggestion" })
map("i", "<C-n>", "<Plug>(copilot-next)", { noremap = false, desc = "Cycle to next Copilot suggestion" })
map("i", "<C-p>", "<Plug>(copilot-previous)", { noremap = false, desc = "Cycle to previous Copilot suggestion" })
map("i", "<C-s>", "<Plug>(copilot-suggest)", { noremap = false, desc = "Explicitly request a new suggestion" })
