---@module 'lsp.servers.clangd'
---@class ClangdServer

local M = {}

---@param shared table
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  lspconfig.clangd.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    cmd = { "clangd" },
  })
end

return M
