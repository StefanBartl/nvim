---@module 'wkddap.adapters.python'
local config = require("wkddap.config")

local M = {}

function M.setup()
  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then return false end

  local adapter_path = config.get_adapter_path("python")
  if not adapter_path then return false end

  dap.adapters.python = {
    type = "executable",
    command = adapter_path,
    args = { "-m", "debugpy.adapter" },
  }

  return true
end

return M
