---@module 'wkdoptions.commands'
--- User command registration system for WKDOptions (refactored).
--- All commands use vim.api.nvim_create_user_command with proper completion.

local M = {}

-- Lazy-load registration module
local register_mod

--- Get registration module (lazy)
---@nodiscard
---@return table
local function get_register()
  if not register_mod then
    register_mod = require("wkdoptions.commands.register")
  end
  return register_mod
end

--- Register highlight-related user commands.
---@param spec WKDOptions.Commands.HL_Spec
---@return nil
function M.register_highlight_commands(spec)
  get_register().register_highlight(spec)
end

--- Register options-related user commands.
---@param spec WKDOptions.Commands.Opt_Spec
---@return nil
function M.register_options_commands(spec)
  get_register().register_options(spec)
end

--- Register diff profile command.
---@return nil
function M.register_diff_profile()
  get_register().register_diff_profile()
end

--- Register debug command for breadcrumb context.
---@param opts WKDOptions.Commands.Debug_Opts|nil
---@return nil
function M.register_highlight_debug_command(opts)
  get_register().register_debug(opts)
end

--- Register all commands at once (convenience).
---@return nil
function M.register_all()
  get_register().register_all()
end

return M
