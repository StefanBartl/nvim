---@module 'bindings.mappings.trouble'
--- trouble.nvim keymaps under `<leader>x*`: the diagnostics views (`xx`/`xw`/`xd`)
--- and the `<leader>xl*` LSP list family (references, definitions, type
--- definitions, implementations, symbols).

local notify = require("lib.nvim.notify").create("[bindings.mappings.trouble]")

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  -- Diagnostics views
  map(
    "n",
    "<leader>xt",
    "<cmd>Trouble diagnostics toggle<cr>",
    { desc = "[Trouble] Toggle diagnostics" }
  )
  map("n", "<leader>xx", "<cmd>Trouble diagnostics<cr>", { desc = "[Trouble] All diagnostics" })
  map(
    "n",
    "<leader>xw",
    "<cmd>Trouble diagnostics filter.buf=nil<cr>",
    { desc = "[Trouble] Workspace diagnostics" }
  )
  map(
    "n",
    "<leader>xd",
    "<cmd>Trouble diagnostics filter.buf=0<cr>",
    { desc = "[Trouble] Buffer diagnostics" }
  )

  -- LSP views
  map("n", "<leader>xlr", "<cmd>Trouble lsp_references<cr>", { desc = "[Trouble] References" })
  map("n", "<leader>xld", "<cmd>Trouble lsp_definitions<cr>", { desc = "[Trouble] Definitions" })
  map("n", "<leader>xlt", "<cmd>Trouble lsp_type_definitions<cr>", { desc = "[Trouble] Type Defs" })
  map(
    "n",
    "<leader>xli",
    "<cmd>Trouble lsp_implementations<cr>",
    { desc = "[Trouble] Implementations" }
  )
  map(
    "n",
    "<leader>xls",
    "<cmd>Trouble lsp_document_symbols<cr>",
    { desc = "[Trouble] Document Symbols" }
  )

  -- Lists
  map("n", "<leader>xl", "<cmd>Trouble loclist<cr>", { desc = "[Loclist] Location List" })
  map("n", "<leader>xq", "<cmd>Trouble qflist<cr>", { desc = "[Quickfix] Quickfix List" })

  -- Navigation in lists
  map("n", "[q", "<cmd>cprevious<cr>", { desc = "[Trouble] Prev Quickfix" })
  map("n", "]q", "<cmd>cnext<cr>", { desc = "[Trouble] Next Quickfix" })
  map("n", "[l", "<cmd>lprevious<cr>", { desc = "[Trouble] Prev Location" })
  map("n", "]l", "<cmd>lnext<cr>", { desc = "[Trouble] Next Location" })

  -- -- Navigation in Workspace Diagnostics via Trouble (v3+)
  -- Navigation within an open Trouble diagnostics list.
  -- Requires trouble.nvim v3 (folke/trouble.nvim, version = "*").
  --
  -- trouble.next / trouble.prev jump to the next/previous item inside the
  -- active Trouble window of the given mode without switching focus to it.
  -- { skip_groups = true } skips file-group headers and lands on actual items.
  -- { jump = true }        immediately jumps the cursor to the source location.

  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return
  end

  ---Jump to the next workspace-diagnostic entry.
  ---Falls back to a silent no-op when no Trouble window is open.
  ---@return nil
  local function diag_next()
    if not trouble.is_open({ mode = "diagnostics" }) then
      notify.info("[trouble] diagnostics list not open")
      return
    end
    trouble.next({ mode = "diagnostics", skip_groups = true, jump = true })
  end

  ---Jump to the previous workspace-diagnostic entry.
  ---Falls back to a silent no-op when no Trouble window is open.
  ---@return nil
  local function diag_prev()
    if not trouble.is_open({ mode = "diagnostics" }) then
      notify.info("[trouble] diagnostics list not open")
      return
    end
    trouble.prev({ mode = "diagnostics", skip_groups = true, jump = true })
  end

  -- ]d  – next workspace diagnostic
  -- [d  – previous workspace diagnostic
  --
  -- Chosen to mirror the existing ]q / [q quickfix pattern while staying
  -- consistent with Neovim's built-in ]d / [d diagnostic navigation.
  -- If the built-in ]d / [d are already mapped elsewhere, change the lhs
  -- to e.g. ]D / [D or <leader>]d / <leader>[d.
  map("n", "]w", diag_next, { desc = "[Trouble] Next workspace diagnostic" })
  map("n", "[w", diag_prev, { desc = "[Trouble] Prev workspace diagnostic" })
end

return M
