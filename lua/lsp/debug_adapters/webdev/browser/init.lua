---@module 'lsp.debug_adapters.webdev.browser'
--- Browser-basiertes Debugging für Web-Apps

local dap = require("dap")

-- Chrome/Edge Debug Adapter
dap.adapters.chrome = {
  type = "executable",
  command = "node",
  args = {
    vim.fn.stdpath("data") .. "/mason/packages/chrome-debug-adapter/out/src/chromeDebug.js",
  },
}

dap.configurations.typescript = dap.configurations.typescript or {}
dap.configurations.javascript = dap.configurations.javascript or {}
dap.configurations.astro = dap.configurations.astro or {}

local browser_config = {
  {
    type = "chrome",
    request = "attach",
    name = "Attach to Chrome",
    port = 9222,
    webRoot = "${workspaceFolder}",
  },
  {
    type = "chrome",
    request = "launch",
    name = "Launch Chrome",
    url = "http://localhost:3000",
    webRoot = "${workspaceFolder}",
  },
}

for _, lang in ipairs({ "typescript", "javascript", "astro" }) do
  vim.list_extend(dap.configurations[lang], browser_config)
end
