---@module 'config.neotree.trash.commands'
---@brief Register user commands for trash module

local M = {}

---Register all trash-related commands
function M.setup()
  local trash = require("config.neotree.trash")

  vim.api.nvim_create_user_command("NeoTreeTrashStats", function()
    trash.show_stats()
  end, {
    desc = "Show Neo-tree trash statistics",
  })

  vim.api.nvim_create_user_command("NeoTreeTrashDebug", function()
    trash.toggle_debug()
  end, {
    desc = "Toggle trash debug mode",
  })

  vim.api.nvim_create_user_command("NeoTreeTrashDryRun", function()
    trash.toggle_dry_run()
  end, {
    desc = "Toggle trash dry-run mode",
  })
end

return M
