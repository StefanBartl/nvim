---@module 'mappings.trouble'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Diagnostics views
  map("n", "<leader>xt", "<cmd>Trouble diagnostics toggle<cr>", { desc = "[Trouble] Toggle diagnostics" })
  map("n", "<leader>xx", "<cmd>Trouble diagnostics<cr>", { desc = "[Trouble] All diagnostics" })
  map("n", "<leader>xw", "<cmd>Trouble diagnostics filter.buf=nil<cr>", { desc = "[Trouble] Workspace diagnostics" })
  map("n", "<leader>xd", "<cmd>Trouble diagnostics filter.buf=0<cr>", { desc = "[Trouble] Buffer diagnostics" })

  -- LSP views
  map("n", "<leader>xlr", "<cmd>Trouble lsp_references<cr>", { desc = "[Trouble] References" })
  map("n", "<leader>xld", "<cmd>Trouble lsp_definitions<cr>", { desc = "[Trouble] Definitions" })
  map("n", "<leader>xlt", "<cmd>Trouble lsp_type_definitions<cr>", { desc = "[Trouble] Type Defs" })
  map("n", "<leader>xli", "<cmd>Trouble lsp_implementations<cr>", { desc = "[Trouble] Implementations" })
  map("n", "<leader>xls", "<cmd>Trouble lsp_document_symbols<cr>", { desc = "[Trouble] Document Symbols" })

  -- Lists
  map("n", "<leader>xl", "<cmd>Trouble loclist<cr>", { desc = "[Loclist] Location List" })
  map("n", "<leader>xq", "<cmd>Trouble qflist<cr>", { desc = "[Quickfix] Quickfix List" })

  -- Navigation in lists
  map("n", "[q", "<cmd>cprevious<cr>", { desc = "[Trouble] Prev Quickfix" })
  map("n", "]q", "<cmd>cnext<cr>", { desc = "[Trouble] Next Quickfix" })
  map("n", "[l", "<cmd>lprevious<cr>", { desc = "[Trouble] Prev Location" })
  map("n", "]l", "<cmd>lnext<cr>", { desc = "[Trouble] Next Location" })
end

return M
