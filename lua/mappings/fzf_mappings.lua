---@module 'mappings.fzf'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Commands & history
  map("n", "<leader>fza", ":FzfLua commands<CR>", { desc = "[FzfLua] Search Commands" })
  map("n", "<leader>fhc", ":FzfLua command_history<CR>", { desc = "[FzfLua] Command History" })
  map("n", "<leader>fb", ":FzfLua builtin<CR>", { desc = "[FzfLua] Builtins" })
  map("n", "<leader>fsh", ":FzfLua search_history<CR>", { desc = "[FzfLua] Search History" })

  -- Files & buffers
  map("n", "<leader>fze", ":FzfLua files<CR>", { desc = "[FzfLua] Files" })
  map("n", "<leader>fzn", ":FzfLua quickfix_stack<CR>", { desc = "[Quickfix] Quickfix Stack" })
  map("n", "<leader>old", ":FzfLua oldfiles<CR>", { desc = "[FzfLua] Oldfiles" })

  -- Colors & keymaps
  map("n", "<leader>color", ":FzfLua colorschemes<CR>", { desc = "[FzfLua] Colorschemes" })
  map("n", "<leader>key", ":FzfLua keymaps<CR>", { desc = "[FzfLua] Keymaps" })

  -- Git
  map("n", "<leader>fgs", ":FzfLua git_status<CR>", { desc = "[FzfLua] Git Status" })
  map("n", "<leader>fgc", ":FzfLua git_commits<CR>", { desc = "[FzfLua] Git Commits" })
  map("n", "<leader>fgf", ":FzfLua git_files<CR>", { desc = "[FzfLua] Git Files" })

  -- Diagnostics
  map("n", "<leader>fdo", ":FzfLua diagnostics_document<CR>", { desc = "[FzfLua] Document Diagnostics" })
  map("n", "<leader>fwo", ":FzfLua diagnostics_workspace<CR>", { desc = "[FzfLua] Workspace Diagnostics" })

  -- LSP quick pickers
  map("n", "<leader>fzv", ":FzfLua lsp_code_actions<CR>", { desc = "[FzfLua] Code Actions" })
  map("n", "<leader>fzw", ":FzfLua lsp_document_diagnostics<CR>", { desc = "[FzfLua] Document Diagnostics" })
  map("n", "<leader>fzx", ":FzfLua lsp_finder<CR>", { desc = "[FzfLua] LSP Finder" })
  map("n", "<leader>fzy", ":FzfLua lsp_references<CR>", { desc = "[FzfLua] References" })
  map("n", "<leader>fzz", ":FzfLua lsp_typedefs<CR>", { desc = "[FzfLua] Typedefs" })
  map("n", "<leader>fz0", ":FzfLua lsp_implementations<CR>", { desc = "[FzfLua] Implementations" })

  -- Registers & changes
  map("n", "<", ":FzfLua registers<CR>", { desc = "[FzfLua] Registers" })
  map("n", "<leader>fzr", ":FzfLua changes<CR>", { desc = "[FzfLua] Changes" })

  -- Quickfix & man-pages
  map("n", "<leader>fqf", ":FzfLua quickfix<CR>", { desc = "[Quickfix] Quickfix" })
  map("n", "<leader>man", ":FzfLua man_pages<CR>", { desc = "[FzfLua] Man Pages" })

  -- Search
  map("n", "<leader>lgp", ":FzfLua live_grep<CR>", { desc = "[FzfLua] Live Grep" })
  map("n", "<leader>fgp", ":FzfLua grep<CR>", { desc = "[FzfLua] Grep" })
  map("n", "<leader>fzb", "<cmd>FzfLua grep_curbuf<CR>", { desc = "[FzfLua] Grep current buffer" })
  map("n", "<leader>fzl", "<cmd>FzfLua live_grep_curbuf<CR>", { desc = "[FzfLua] Live Grep current buffer" })

  -- Filetypes
  map("n", "<leader>fil", ":FzfLua filetypes<CR>", { desc = "[FzfLua] Filetypes" })

  -- Short aliases
  map("n", "<leader>do", ":FzfLua diagnostics_document<CR>", { desc = "[FzfLua] Document Diagnostics" })
  map("n", "<leader>wo", ":FzfLua diagnostics_workspace<CR>", { desc = "[FzfLua] Workspace Diagnostics" })
end

return M
