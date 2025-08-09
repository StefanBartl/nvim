---@module 'lsp.servers.gopls'
---@class GoplsServer

local M = {}

---@param shared table
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  lspconfig.gopls.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    settings = {
      gopls = {
        analyses = { unusedparams = true },
        staticcheck = true,
      },
    },
  })
end

return M
