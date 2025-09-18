---@module 'lsp.servers.ts_ls'
--- TypeScript/JavaScript server via native LSP config/enable.

---@class TsLsServer
local M = {}

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  if type(vim.lsp.config) == "table" then
    vim.lsp.config("ts_ls", {
      cmd = { "typescript-language-server", "--stdio" },
      filetypes = { "typescript", "typescriptreact", "tsx", "javascript", "javascriptreact" },
      root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
      capabilities = shared.capabilities,
      on_attach = function(client, bufnr)
        if type(shared.on_attach) == "function" then shared.on_attach(client, bufnr) end
        -- Per-buffer diagnostic tuning can be set globally elsewhere via vim.diagnostic.config
      end,
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
    if opts.enable ~= false then pcall(vim.lsp.enable, "ts_ls") end
  end
end

return M
