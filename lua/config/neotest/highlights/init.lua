---@module 'config.neotest.highlights'
---@brief Neotest highlight groups setup

local M = {}

function M.setup()
  -- Define highlight groups
  vim.api.nvim_set_hl(0, "NeotestPassed", { fg = "#9ece6a", bold = true })
  vim.api.nvim_set_hl(0, "NeotestFailed", { fg = "#f7768e", bold = true })
  vim.api.nvim_set_hl(0, "NeotestRunning", { fg = "#e0af68", bold = true })
  vim.api.nvim_set_hl(0, "NeotestSkipped", { fg = "#565f89", italic = true })
  vim.api.nvim_set_hl(0, "NeotestTest", { fg = "#7aa2f7" })
  vim.api.nvim_set_hl(0, "NeotestNamespace", { fg = "#bb9af7" })
  vim.api.nvim_set_hl(0, "NeotestFile", { fg = "#7dcfff" })
  vim.api.nvim_set_hl(0, "NeotestDir", { fg = "#7dcfff" })
end

return M
