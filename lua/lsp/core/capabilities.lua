---@module 'lsp.core.capabilities'
---@class LspCapabilities
---@field value lsp.ClientCapabilities

local M = {}

---@return lsp.ClientCapabilities
function M.get()
  do
    local ok, nvlsp = pcall(require, "nvchad.configs.lspconfig")
    if ok and type(nvlsp) == "table" and type(nvlsp.capabilities) == "table" then
      return nvlsp.capabilities
    end
  end
  do
    local ok, cmp = pcall(require, "cmp_nvim_lsp")
    if ok and type(cmp.default_capabilities) == "function" then
      return cmp.default_capabilities()
    end
  end
  local caps = vim.lsp.protocol.make_client_capabilities()
  return caps
end

return M
