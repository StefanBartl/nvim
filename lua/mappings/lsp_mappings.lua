---@module 'mappings.lsp'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Rename
  map("n", "grn", vim.lsp.buf.rename, { desc = "[LSP] Rename" })
  map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[LSP] Rename" })
  map("n", "<leader>nam", function()
    local curr = vim.fn.expand("<cword>")
    local newn = vim.fn.input("Rename '" .. curr .. "' to: ", curr)
    if newn ~= "" and newn ~= curr then vim.lsp.buf.rename(newn) end
  end, { desc = "[LSP] Rename via cmdline" })

  -- Code actions
  map("n", "gra", vim.lsp.buf.code_action, { desc = "[LSP] Code Action" })
  map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "[LSP] Code Action" })

  -- Goto & symbols
  map("n", "grr", vim.lsp.buf.references, { desc = "[LSP] References" })
  map("n", "gri", vim.lsp.buf.implementation, { desc = "[LSP] Implementations" })
  map("n", "gO", vim.lsp.buf.document_symbol, { desc = "[LSP] Document Symbols" })
  map("n", "gd", vim.lsp.buf.definition, { desc = "[LSP] Go to Definition" })
  map("n", "gD", vim.lsp.buf.declaration, { desc = "[LSP] Go to Declaration" })
  map("n", "gt", vim.lsp.buf.type_definition, { desc = "[LSP] Type Definition" })

  -- Format
  map("n", "gq", function() vim.lsp.buf.format({ async = true }) end, { desc = "[LSP] Format (line/doc)" })

  -- Diagnostics
  -- Quickfix-List
  map("n", "<leader>qs", vim.diagnostic.setqflist, { desc = "[Quickfix] To Quickfix List" })
  map("n", "]q", ":cnext<CR>", { desc = "[Quickfix]Next in Quickfix List" })
  map("n", "[q", ":cprev<CR>", { desc = "[Quickfix] Prev in Quickfix List" })

  -- Location List
  map("n", "[l", vim.diagnostic.goto_prev, { desc = "[Loclist] Prev Diagnostic" })
  map("n", "]l", vim.diagnostic.goto_next, { desc = "[Loclist] Next Diagnostic" })
  map("n", "<leader>lf", vim.diagnostic.open_float, { desc = "[Loclist] Diagnostic popup" })
  map("n", "<leader>ls", vim.diagnostic.setloclist, { desc = "[Loclist] Diagnostic loclist" })
  map("n", "<leader>lo", function()
    vim.diagnostic.setloclist()
    vim.cmd("lopen")
  end, { desc = "[Loclist] Diagnostic loclist (open)" })
end

return M
