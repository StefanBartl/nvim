---@module 'mappings.fzf'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>com", ":FzfLua commands<CR>", { desc = "[FzfLua] Search Commands" })

  map("n", "<leader>th", ":FzfLua colorschemes<CR>", { desc = "[FzfLua] Colorschemes" })
  map("n", "<leader>fk", ":FzfLua keymaps<CR>", { desc = "[FzfLua] Keymaps" })

  map("n", "<leader>fgs", ":FzfLua git_status<CR>", { desc = "[FzfLua] Git Status" })

  map("n", "<leader>do", ":FzfLua diagnostics_document<CR>", { desc = "[FzfLua] Document Diagnostics" })
  map("n", "<leader>wo", ":FzfLua diagnostics_workspace<CR>", { desc = "[FzfLua] Workspace Diagnostics" })

  map("n", "<leader>fq", ":FzfLua quickfix<CR>", { desc = "[Quickfix] Quickfix" })
  map("n", "<leader>man", ":FzfLua man_pages<CR>", { desc = "[FzfLua] Man Pages" })

  map("n", "<leader><leader>", ":FzfLua live_grep<CR>", { desc = "[FzfLua] Live Grep" })
  map("n", "<leader>fg", ":FzfLua grep<CR>", { desc = "[FzfLua] Grep" })
  map("n", "<leader>fb", "<cmd>FzfLua grep_curbuf<CR>", { desc = "[FzfLua] Grep current buffer" })

  map("n", "<leader>ff", ":FzfLua files<CR>", { desc = "[FzfLua] Files" })
end

return M
