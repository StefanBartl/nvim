---@module 'custom.picker_fd_depth'
---@brief Entry point orchestrating user commands and keymaps for depth-based picking.

local M = {}

--- Initializes user commands and keymaps according to the module configuration.
---@return nil
function M.setup()
  require("custom.picker_fd_depth.usercmds").enable()
  require("custom.picker_fd_depth.keymaps").enable()
end

return M
