---@module 'config.neotree.checkhealth'
---@brief Aggregated checkhealth entry point for neotree config

local M = {}

function M.check()
  require("config.neotree.checkhealth.open_window").check()
end

return M

