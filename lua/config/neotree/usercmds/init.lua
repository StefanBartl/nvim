---@module 'config.neotree.usercmds'

local api = vim.api
local nvim_create_user_command = api.nvim_create_user_command

local M = {}

---@return nil
function M.enable()
  nvim_create_user_command("NeoTreeCheckHealth", function()
    require("config.neotree.checkhealth").check()
  end, {
    desc = "Run Neo-tree config health checks",
  })

  nvim_create_user_command("NeoTreeDebugSources", function()
    require("config.neotree.sources.switcher").debug_sources()
  end, { desc = "[Neo-tree] Debug source detection" })
end

return M
