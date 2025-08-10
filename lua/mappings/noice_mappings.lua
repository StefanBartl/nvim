---@module 'mappings.noice'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map({ "n", "i", "s" }, "<A-k>", function()
    local ok, noice_lsp = pcall(require, "noice.lsp")
    if not ok or not noice_lsp.scroll(4) then return "<c-f>" end
  end, { silent = true, expr = true, desc = "[Noice] LSP Scroll forward" })

  map({ "n", "i", "s" }, "<A-j>", function()
    local ok, noice_lsp = pcall(require, "noice.lsp")
    if not ok or not noice_lsp.scroll(-4) then return "<c-b>" end
  end, { silent = true, expr = true, desc = "[Noice] LSP Scroll backward" })

  map({ "n", "i" }, "<A-x>", function()
    local ok, noice = pcall(require, "noice")
    if ok then noice.cmd("dismiss") end
  end, { desc = "[Noice] Dismiss UI" })
end

return M
