---@module 'lsp.servers.lua_ls'
---@class LuaLsServer

local M = {}

---@param shared table
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  local settings = {
    Lua = {
      completion = { callSnippet = "Replace" },
      workspace = { checkThirdParty = false },
      diagnostics = { globals = { "vim" } },
      hint = { enable = true },
      runtime = { version = "LuaJIT" },
    },
  }

  lspconfig.lua_ls.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    settings = settings,
  })
end

return M
