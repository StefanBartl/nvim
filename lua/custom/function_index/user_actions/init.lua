---@module 'custom.function_index.user_actions'
---@brief User-facing commands and keymaps for function_index

local M = {}

---Setup user commands and keymaps based on configuration
---@param config FunctionIndexConfig Configuration from main module
function M.setup(config)
  if config.enable_user_commands then
    require("custom.function_index.user_actions.usercommands").setup()
  end

  if config.enable_keymaps then
    require("custom.function_index.user_actions.keymaps").setup(config.keymaps)
  end
end

return M
