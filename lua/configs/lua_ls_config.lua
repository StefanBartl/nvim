local nvlsp = require("nvchad.configs.lspconfig")
local project_root = vim.fn.getcwd()
local lua_root = project_root .. "/lua"

return {
  name = "lua_ls",
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = vim.fn.getcwd(),
  capabilities = nvlsp.capabilities,
  on_attach = function(client, bufnr)
    require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
    if nvlsp.on_attach then
      nvlsp.on_attach(client, bufnr)
    end
  end,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
      diagnostics = { globals = { "vim", "vim.uv" } },
      workspace = {
        checkThirdParty = false,
        library = {
          [vim.fn.expand("$NVIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. "/lua"] = true,
          [lua_root] = true,
        },
      },
      telemetry = { enable = false },
    },
  },
}
