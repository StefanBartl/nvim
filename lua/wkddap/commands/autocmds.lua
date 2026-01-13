---@module 'wkddap.commands.autocmds'

local M = {}

function M.setup()
  -- Auto-highlight current line when debugging
  vim.api.nvim_create_autocmd("User", {
    pattern = "DapUIWindowOpen",
    callback = function()
      vim.wo.cursorline = true
    end,
  })

  -- Clean up highlights on exit
  vim.api.nvim_create_autocmd("User", {
    pattern = "DapUIWindowClose",
    callback = function()
      vim.wo.cursorline = false
    end,
  })

  return true
end

return M
