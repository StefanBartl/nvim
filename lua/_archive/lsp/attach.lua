---@module "lsp.attach"
local M = {}

-- Prefer NvChad capabilities; fallback to cmp_nvim_lsp or vanilla.
local function compute_capabilities()
  local ok_nv, nvlsp = pcall(require, "nvchad.configs.lspconfig")
  if ok_nv and type(nvlsp.capabilities) == "table" then
    return nvlsp.capabilities
  end
  local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp and type(cmp.default_capabilities) == "function" then
    return cmp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

---Advertised client capabilities used by all servers.
M.capabilities = compute_capabilities()

---Optional forward of on_init to NvChad if present.
function M.on_init(client, initialize_result)
  local ok_nv, nvlsp = pcall(require, "nvchad.configs.lspconfig")
  if ok_nv and type(nvlsp.on_init) == "function" then
    pcall(nvlsp.on_init, client, initialize_result)
  end
end

---Shared on_attach: workspace diagnostics + format-on-save (Conform if present).
function M.on_attach(client, bufnr)
  -- Populate workspace diagnostics if plugin exists
  pcall(function()
    require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
  end)

  -- Format on save if server supports it
  if client.supports_method and client:supports_method("textDocument/formatting") then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      desc = "Format on save via Conform (fallback to LSP)",
      callback = function()
        local ok_conf, conform = pcall(require, "conform")
        if ok_conf then
          conform.format({ bufnr = bufnr })
        else
          pcall(vim.lsp.buf.format, { bufnr = bufnr })
        end
      end,
    })
  end

  -- Forward to NvChad on_attach if available
  local ok_nv, nvlsp = pcall(require, "nvchad.configs.lsponfig")
  if ok_nv and type(nvlsp.on_attach) == "function" then
    pcall(nvlsp.on_attach, client, bufnr)
  end
end

return M
