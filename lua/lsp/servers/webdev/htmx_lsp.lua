---@module 'lsp.servers.webdev.htmx_lsp'
--- HTMX Language Server für HTMX-Attribute

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

  vim.lsp.config("htmx", {
    cmd = { "htmx-lsp", "--stdio" },
    filetypes = { "html", "astro", "htmldjango", "eruby" },
    root_markers = { ".git", "package.json" },
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
  })

  if opts.enable ~= false then
    pcall(vim.lsp.enable, "htmx")
  end
end

return M
