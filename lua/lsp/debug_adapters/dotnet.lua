---@module 'lsp.debug_adapters.dotnet'

local dap = require("dap")

-- set `noshellslash` in windows to get 'netcoredbg' correctly working
local is_windows = vim.uv.os_uname().version:match("Windows")
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
    -- nvim-dap resolves config functions inside coroutine.wrap(), so an
    -- async prompt works via the same yield/resume idiom nvim-dap's own
    -- async pickers use: yield, let kit.input's on_submit resume the
    -- suspended coroutine with the typed value.
    program = function()
      local co = coroutine.running()
      require("lib.nvim.ui.kit").input({
        title = "Path to DLL: ",
        default = vim.fn.getcwd() .. "\\bin\\Debug\\net9.0\\",
        completion = "file",
        on_submit = function(input)
          coroutine.resume(co, input)
        end,
        on_cancel = function()
          coroutine.resume(co, "")
        end,
      })
      return coroutine.yield()
    end,
  },
}
