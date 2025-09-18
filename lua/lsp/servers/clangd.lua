---@module 'lsp.servers.clangd'
--- clangd via native LSP config/enable.

---@class ClangdServer
local M = {}

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  if type(vim.lsp.config) == "table" then
    vim.lsp.config("clangd", {
      cmd = { "clangd" },
      filetypes = { "c", "cpp", "objc", "objcpp" },
      root_markers = { "compile_commands.json", ".git" },
      capabilities = shared.capabilities,
      on_attach = shared.on_attach,
      on_init = shared.on_init,
    })
    if opts.enable ~= false then pcall(vim.lsp.enable, "clangd") end
  end
end

return M
