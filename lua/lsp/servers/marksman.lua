---@module 'lsp.servers.marksman'
--- LSP setup for the Marksman Markdown language server.

---@class MarksmanServer
local M = {}

---@param shared {capabilities: table, on_attach: fun(client,bufnr), on_init: fun(client,init_result):boolean}
---@return nil
function M.setup(shared)
  -- Defensive checks for the shared table and lspconfig presence
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  -- marksman defaults to cmd = { "marksman", "server" } in lspconfig.
  -- We pass through your shared capabilities/on_attach/on_init.
  lspconfig.marksman.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    -- Explicit filetypes are optional; included for clarity and MDX support.
    filetypes = { "markdown", "markdown.mdx" },
    -- Optionally fine-tune root_dir (marksman works well with .git by default).
    -- root_dir = lspconfig.util.root_pattern("marksman.toml", ".git"),
    settings = {},
  })
end

return M
