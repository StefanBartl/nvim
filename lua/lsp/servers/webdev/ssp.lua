---@module 'lsp.servers.webdev.ssp'
--- Server-Side Processing / Template Language Support

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

  -- Falls SSP = Server-Side Processing mit HTML/PHP/ERB
  -- Verwende html + emmet für grundlegendes Templating
  vim.lsp.config("html", {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html", "ssp", "ejs", "erb" },
    root_markers = { ".git", "package.json" },
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
  })

  if opts.enable ~= false then
    pcall(vim.lsp.enable, "html")
  end
end

return M
