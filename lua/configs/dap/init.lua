---@module 'config.dap'

local M = {}

require("dap").set_log_level("DEBUG")

require("configs.dap.node")
require("configs.dap.go")
require("configs.dap.dotnet")

return M
