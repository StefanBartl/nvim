---@module 'custom.mygrep.usercommands'
---@class CommandManager
---@brief Defines user commands for invoking grep tools.
---@description
--- This module registers custom :Mygrep* commands to launch memory-enabled grep tools.
--- The required `open(tool, opts)` function must be passed during setup.
---
---@param open fun(tool: string, opts?: table): boolean|nil The tool-opening function to use
---@return nil

local M = {}

--- Registers all :Mygrep* commands
---@param open fun(tool: string, opts?: table): boolean|nil
---@return nil
function M.setup(open)
  if type(open) ~= "function" then
    vim.notify("[mygrep.usercommands] Invalid .open function provided", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_create_user_command("MygrepLive", function()
    local success = pcall(open, "live_grep", {})
    if not success then
      vim.notify("[MyGrep] Failed to open live_grep", vim.log.levels.ERROR)
    end
  end, { desc = "Launch live_grep tool with memory" })

  vim.api.nvim_create_user_command("MygrepMulti", function()
    local success = pcall(open, "multigrep", {})
    if not success then
      vim.notify("[MyGrep] Failed to open multigrep", vim.log.levels.ERROR)
    end
  end, { desc = "Launch multigrep tool with memory" })
end

return M
