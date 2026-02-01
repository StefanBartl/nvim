---@module 'lsp.servers.sourcekit'
--- SourceKit-LSP for Swift and iOS development.

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

  vim.lsp.config("sourcekit", {
    cmd = { "sourcekit-lsp" },
    filetypes = { "swift", "objective-c", "objective-cpp" },
    root_markers = {
      "Package.swift",
      ".git",
      "compile_commands.json",
    },
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
  })

  if opts.enable ~= false then
    pcall(vim.lsp.enable, "sourcekit")
  end
end

return M
