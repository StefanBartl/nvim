---@module 'config.snacks.picker.actions'
---@brief Custom actions for snacks picker
---@description
--- Provides custom actions for snacks.nvim picker:
--- - create_file: Create files/folders with <C-a>
--- - open_background: Open files in background with <S-CR> or <C-o>

local M = {}

local create_file_mod = require("config.snacks.picker.actions.create_file")
local open_background_mod = require("config.snacks.picker.actions.open_background")

---Get all custom actions
---@return table<string, function> actions
function M.get_actions()
  return {
    create_file = create_file_mod.create_file,
    open_background = open_background_mod.open_background,
  }
end

return M
