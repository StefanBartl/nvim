---@module 'wkddap.adapters.zig'
local config = require("wkddap.config")

local M = {}

function M.setup()
  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then return false end

  local adapter_path = config.get_adapter_path("zig")
  if not adapter_path then return false end

  dap.adapters.lldb = dap.adapters.lldb or {
    type = "executable",
    command = adapter_path,
    name = "lldb",
  }

  return true
end

return M
