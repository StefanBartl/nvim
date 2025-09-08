---@module 'mappings.lsp'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  --Buffer wide rename
  map("n", "grn", vim.lsp.buf.rename, { desc = "[LSP] Rename" })
  map("n", "<leader>name", function()
    local curr = vim.fn.expand "<cword>"
    local newn = vim.fn.input("Rename '" .. curr .. "' to: ", curr)
    if newn ~= "" and newn ~= curr then
      vim.lsp.buf.rename(newn)
    end
  end, { desc = "[LSP] Rename via cmdline" })

  -- Code actions
  map("n", "gra", vim.lsp.buf.code_action, { desc = "[LSP] Code Action" })
  map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "[LSP] Code Action" })

  -- Goto & symbols
  map("n", "lsr", vim.lsp.buf.references, { desc = "[LSP] References" })
  map("n", "lsi", vim.lsp.buf.implementation, { desc = "[LSP] Implementations" })
  map("n", "lss", vim.lsp.buf.document_symbol, { desc = "[LSP] Document Symbols" })
  map("n", "lsd", vim.lsp.buf.definition, { desc = "[LSP] Go to Definition" })
  map("n", "lsD", vim.lsp.buf.declaration, { desc = "[LSP] Go to Declaration" })
  map("n", "lst", vim.lsp.buf.type_definition, { desc = "[LSP] Type Definition" })

  -- Format
  map("n", "gq", function()
    vim.lsp.buf.format { async = true }
  end, { desc = "[LSP] Format (line/doc)" })

  -- Diagnostics
  -- Quickfix-List
  map("n", "<leader>tq", vim.diagnostic.setqflist, { desc = "[Quickfix] To Quickfix List" })
  map("n", "]q", ":cnext<CR>", { desc = "[Quickfix]Next in Quickfix List" })
  map("n", "[q", ":cprev<CR>", { desc = "[Quickfix] Prev in Quickfix List" })

  map("n", "]d", function()
    vim.diagnostic.jump { count = 1, float = true }
  end, { desc = "[Diagnostics] Next", silent = true })
  map("n", "[d", function()
    vim.diagnostic.jump { count = -1, float = true }
  end, { desc = "[Diagnostics] Prev", silent = true })

  map("n", "<leader>lf", vim.diagnostic.open_float, { desc = "[Loclist] Diagnostic popup" })
  map("n", "<leader>ls", vim.diagnostic.setloclist, { desc = "[Loclist] Diagnostic loclist" })
  map("n", "<leader>lo", function()
    vim.diagnostic.setloclist()
    vim.cmd "lopen"
  end, { desc = "[Loclist] Diagnostic loclist (open)" })

  -- === FORMATTING ===
  -- Silent toggles for format-on-save and one-shot format
  -- No notifications, no echo messages; descriptions for which-key/help

  map("n", "<leader>tf", function()
    -- Prefer a cached/shared API if present
    if vim.g._formatter_api and type(vim.g._formatter_api.toggle) == "function" then
      vim.g._formatter_api.toggle()
      return
    end

    -- Build a temporary API (and cache it for subsequent uses)
    local ok, mod = pcall(require, "lsp.formatter.init") -- fixed path
    if ok and mod and type(mod.build) == "function" then
      vim.g._formatter_api = mod.build { format_on_save = false, timeout_ms = 1500 }
      vim.g._formatter_api.toggle()
    end
  end, { desc = "[LSP] Toggle format-on-save (silent)", silent = true })

  map("n", "<leader>ft", function()
    if vim.g._formatter_api and type(vim.g._formatter_api.format) == "function" then
      vim.g._formatter_api.format(0)
      return
    end
    local ok, mod = pcall(require, "lsp.formatter.init") -- fixed path
    if ok and mod and type(mod.build) == "function" then
      local api = mod.build { format_on_save = false, timeout_ms = 1500 }
      api.format(0)
    end
  end, { desc = "[LSP] Format current buffer once (silent)", silent = true })
end

return M
