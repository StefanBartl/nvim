---@module 'config.neotree.usercmds'

local M = {}

---@return nil
function M.enable_usercmds(opts)
  opts = opts or {}

  if opts and opts.debug then
    vim.api.nvim_create_user_command(
      "NeoTreeForceReset",
      require("config.neotree.open.window.debug").force_reset_state,
      {
        desc = "[Neo-tree] Force-reset all state and close buffers",
      }
    )

    vim.api.nvim_create_user_command(
      "NeoTreeDebugState",
      require("config.neotree.open.window.debug").show_debug_state,
      {
        desc = "[Neo-tree] Show current state for debugging",
      }
    )
  end

  vim.api.nvim_create_user_command("NeoTreeSemaphoreStatus", function()
    local sem = require("config.neotree.open.window.controller.semaphore")
    local status = sem.status()
    vim.print(status)
  end, {})

  vim.api.nvim_create_user_command("NeoTreeClearSemaphore", function()
    require("config.neotree.open.window.controller").clear_semaphore()
  end, {})

  vim.api.nvim_create_user_command("NeoTreeErrorStats", function()
    local handler = require("config.neotree.open.window.controller.error_handler")
    vim.print(handler.get_stats())
  end, {})

  vim.api.nvim_create_user_command("NeoTreeExportEvents", function()
    require("config.neotree.open.window.observability").export_events()
  end, {})
end

return M
