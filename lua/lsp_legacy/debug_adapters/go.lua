---@module 'lsp.debug_adapters.go'
--- nvim-dap adapter for Go via delve (`dlv dap`) -- unreachable, same reason
--- as `lsp.debug_adapters.dotnet`.

local dap = require("dap")

-- Adapter for Go-Debugging via Delve (dlv)
dap.adapters.go = {
  type = "server",
  port = "${port}", -- dynamic runtime replacement
  executable = {
    command = "dlv",
    args = { "dap", "-l", "127.0.0.1:${port}" },
  },
}

dap.configurations.go = {
  {
    type = "go",
    name = "Launch file (go via delve)",
    request = "launch",
    program = "${file}",
  },
}
