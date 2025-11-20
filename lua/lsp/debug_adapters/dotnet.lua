---@module 'lsp.debug_adapters.dotnet'

local dap = require("dap")

-- set `noshellslash` in windows to get 'netcoredbg' correctly working
local is_windows = vim.loop.os_uname().version:match("Windows")
if is_windows then
  vim.cmd([[set noshellslash]])
end

-- Adapter-Definitions for .NET (C#, F#) with 'netcoredbg'
dap.adapters.coreclr = {
  type = "executable",
  command = "C:/tools/DebugAdapterProtocol/netcoredbg/netcoredbg.exe",
  args = { "--interpreter=vscode" },
}

dap.configurations.cs = {
  {
    type = "coreclr",
    name = "Launch - netcoredbg",
    request = "launch",
    program = function()
      return vim.fn.input("Path to DLL: ", vim.fn.getcwd() .. "\\bin\\Debug\\net9.0\\", "file")
    end,
  },
}
