---@module 'custom.dir_picker'
---@brief Entry point: wires configuration, commands, and keymaps.

local M = {}

--- Sets up dir_picker with optional user configuration.
--- Call this once from your lazy.nvim config or init.lua.
---@param opts DirPickerConfig|nil
---@return nil
function M.setup(opts)
  -- Apply user config before any command or keymap is registered
  require("custom.dir_picker.config").apply(opts)
  require("custom.dir_picker.bindings.usercmds").enable()
  require("custom.dir_picker.bindings.keymaps").enable()
end

return M
