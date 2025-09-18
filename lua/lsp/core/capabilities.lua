---@module 'lsp.core.capabilities'
--- Build client capabilities from multiple completion stacks (cmp, blink, NvChad).

local M = {}

---@return table
function M.get()
  local caps = vim.lsp.protocol.make_client_capabilities()

  do
    local ok, nvlsp = pcall(require, "nvchad.config.lspconfig")
    if ok and type(nvlsp.capabilities) == "table" then
      caps = vim.tbl_deep_extend("force", caps, nvlsp.capabilities)
    end
  end
  do
    local ok, cmp = pcall(require, "cmp_nvim_lsp")
    if ok and type(cmp.default_capabilities) == "function" then
      caps = vim.tbl_deep_extend("force", caps, cmp.default_capabilities())
    end
  end
  do
    local ok, blink = pcall(require, "blink.cmp")
    if ok and type(blink.get_lsp_capabilities) == "function" then
      caps = vim.tbl_deep_extend("force", caps, blink.get_lsp_capabilities(caps))
    end
  end

  return caps
end

---@nodiscard
---@return nil
function M.apply_globally()
  -- Merge these caps into every named config as a base ("*")
  local caps = M.get()
  if type(vim.lsp.config) == "table" then
    vim.lsp.config("*", { capabilities = caps })
  end
end

return M
