---@module 'config.dap'
---@see 'configs.dap.node'
---@see 'configs.dap.go'
---@see 'configs.dap.dotnet'

local M = {}

require("dap").set_log_level("DEBUG")

require("configs.dap.node")
require("configs.dap.go")
require("configs.dap.dotnet")

return M
