---@module 'wkddap.adapters.c'
local config = require("dap.config")

local M = {}

function M.setup()
  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then return false end

  local adapter_path = config.get_adapter_path("c")
  if not adapter_path then return false end

  -- Try CodeLLDB first, fallback to lldb-vscode
  dap.adapters.lldb = {
    type = "executable",
    command = adapter_path,
    name = "lldb",
  }

  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = adapter_path,
      args = { "--port", "${port}" },
    },
  }

  return true
end

return M

