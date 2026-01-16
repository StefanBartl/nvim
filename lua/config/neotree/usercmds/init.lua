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
end

return M
