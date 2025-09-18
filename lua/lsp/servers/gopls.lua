---@module 'lsp.servers.gopls'
---@class GoplsServer

local M = {}

---@param shared table
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  -- AUDIT:
  lspconfig.gopls.setup {
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    settings = {
      gopls = {
        usePlaceholders = true,
        staticcheck = true,
        gofumpt = true,
        analyses = { unusedparams = true, shadow = true },
        memoryMode = "DegradeClosed",
        directoryFilters = { "-**/node_modules", "-**/dist", "-**/.git" },
      },
    },
  }
end

return M
