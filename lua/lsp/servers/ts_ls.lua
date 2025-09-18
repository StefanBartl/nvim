---@module 'lsp.servers.ts_ls'
---@class TsLsServer

local M = {}

---@param shared table
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  lspconfig.ts_ls.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    settings = {
      javascript = { preferences = { includeCompletionsForModuleExports = true } },
      typescript = {
        preferences = {
          includeInlayParameterNameHints = "literals",
          includeInlayFunctionLikeReturnTypeHints = true,
        },
      },
    },
  })
end

return M
