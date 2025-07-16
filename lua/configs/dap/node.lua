---@module 'configs.dap.node'

local dap = require("dap")

dap.adapters["pwa-node"] = {
  type = "executable",
  command = "node",
  args = {
    vim.fn.stdpath("data") .. "/vscode-js-debug/out/src/jsDebug.js"
  },
}

for _, language in ipairs({ "javascript", "typescript" }) do
  dap.configurations[language] = {
    {
      type = "pwa-node",
      request = "launch",                  -- startmode alternative "attach"
      name = "Launch file (via node.js)",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "node"
    }
  }
end
