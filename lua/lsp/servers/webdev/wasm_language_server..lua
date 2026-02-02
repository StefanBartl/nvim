---@module 'lsp.servers.webdev.wasm_language_server'
--- WebAssembly Language Server (WASM)

local M = {}

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  if type(vim.lsp.config) ~= "table" then
    return
  end

  vim.lsp.config("wasm_language_server", {
    cmd = { "wasm-language-server" },
    filetypes = { "wasm", "wat" },
    root_markers = { ".git", "Cargo.toml" },
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
  })

  if opts.enable ~= false then
    pcall(vim.lsp.enable, "wasm_language_server")
  end
end

return M
