local dap = require("dap")

-- Konfiguration für pwa-node Adapter
dap.adapters["pwa-node"] = {
  type = "executable",
  command = "node",
  args = { vim.fn.stdpath("data") .. "/vscode-js-debug/out/src/jsDebug.js" },
}
require("dap").set_log_level("DEBUG")


-- Konfigurationen für TypeScript und JavaScript
for _, language in ipairs({ "typescript", "javascript" }) do
  dap.configurations[language] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "node",
    },
  }
end
