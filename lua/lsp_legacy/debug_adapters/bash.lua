---@module 'lsp.debug_adapters.bash'
--- Bash debugging via bash-debug-adapter (DAP).
--- Requires: Mason 'bash-debug-adapter'.

local adapters = require("dap").adapters
local configurations = require("dap").configurations

-- Adapter definition (node-based adapter started by Mason)
adapters.bashdb = {
  type = "executable",
  command = vim.fn.exepath("bash-debug-adapter"),
  args = {},
}

configurations.sh = {
  {
    type = "bashdb",
    request = "launch",
    name = "Debug current shell script",
    program = "${file}", -- current buffer
    cwd = "${workspaceFolder}",
    pathBash = vim.fn.exepath("bash"), -- ensure bash exists
    pathBashdb = vim.fn.exepath("bashdb"), -- optional; adapter can bundle one
    pathBashdbLib = "", -- optional; leave empty to use defaults
    trace = false,
    args = {}, -- runtime args to your script
    env = {}, -- environment vars
    terminalKind = "integrated", -- "integrated" | "external"
  },
}

-- Reuse same config for bash/zsh/ksh by aliasing
configurations.bash = configurations.sh
configurations.zsh = configurations.sh
configurations.ksh = configurations.sh
