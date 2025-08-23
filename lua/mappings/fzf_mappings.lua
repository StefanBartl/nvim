---@module 'mappings.fzf'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>com", ":FzfLua commands<CR>", { desc = "[FzfLua] Search Commands" })

  map("n", "<leader>th", ":FzfLua colorschemes<CR>", { desc = "[FzfLua] Colorschemes" })
  map("n", "<leader>fk", ":FzfLua keymaps<CR>", { desc = "[FzfLua] Keymaps" })

  map("n", "<leader>fgs", ":FzfLua git_status<CR>", { desc = "[FzfLua] Git Status" })
  map("n", "<leader>fgc", ":FzfLua git_commits<CR>", { desc = "[FzfLua] Git Commits" })

  -- Diagnostics
  map("n", "<leader>do", ":FzfLua diagnostics_document<CR>", { desc = "[FzfLua] Document Diagnostics" })
  map("n", "<leader>wo", ":FzfLua diagnostics_workspace<CR>", { desc = "[FzfLua] Workspace Diagnostics" })

  -- LSP quick pickers
  map("n", "<leader>flr", ":FzfLua lsp_references<CR>", { desc = "[FzfLua] References" })
  map("n", "<leader>flt", ":FzfLua lsp_typedefs<CR>", { desc = "[FzfLua] Typedefs" })
  map("n", "<leader>fli", ":FzfLua lsp_implementations<CR>", { desc = "[FzfLua] Implementations" })

  -- Registers & changes
  map("n", "<leader><", ":FzfLua registers<CR>", { desc = "[FzfLua] Registers" })

  -- Quickfix & man-pages
  map("n", "<leader>fqf", ":FzfLua quickfix<CR>", { desc = "[Quickfix] Quickfix" })
  map("n", "<leader>man", ":FzfLua man_pages<CR>", { desc = "[FzfLua] Man Pages" })

  -- Search
  map("n", "<leader>flg", ":FzfLua live_grep<CR>", { desc = "[FzfLua] Live Grep" })
  map("n", "<leader>fgp", ":FzfLua grep<CR>", { desc = "[FzfLua] Grep" })
  map("n", "<leader>fbb", "<cmd>FzfLua grep_curbuf<CR>", { desc = "[FzfLua] Grep current buffer" })

  -- Filetypes
  map("n", "<leader>fil", ":FzfLua filetypes<CR>", { desc = "[FzfLua] Filetypes" })
end

return M
