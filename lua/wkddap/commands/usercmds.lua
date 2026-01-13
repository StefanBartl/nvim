---@module 'wkddap.commands.usercmds'

local M = {}

function M.setup()
  vim.api.nvim_create_user_command("DapContinue", function()
    require("dap").continue()
  end, { desc = "[DAP] Continue" })

  vim.api.nvim_create_user_command("DapToggleBreakpoint", function()
    require("dap").toggle_breakpoint()
  end, { desc = "[DAP] Toggle Breakpoint" })

  vim.api.nvim_create_user_command("DapTerminate", function()
    require("dap").terminate()
  end, { desc = "[DAP] Terminate" })

  vim.api.nvim_create_user_command("DapToggleUI", function()
    require("dapui").toggle()
  end, { desc = "[DAP] Toggle UI" })
end

return M
