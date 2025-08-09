---@module 'lsp.core.registry'
---@class SharedCtx
---@field capabilities lsp.ClientCapabilities
---@field on_attach fun(client:lsp.Client, bufnr:integer)
---@field on_init   fun(client:lsp.Client, _):boolean
---@field formatter table

local M = {}

local ACTIVE = {
  "lua_ls",
  "ts_ls",
  "gopls",
  "clangd",
  "csharp",
  "zig",
}

---@param shared SharedCtx
---@return boolean ok
function M.setup_all(shared)
  if type(shared) ~= "table" then return false end
  for _, name in ipairs(ACTIVE) do
    local mod = "lsp.servers." .. name
    local ok, srv = pcall(require, mod)
    if not ok or type(srv) ~= "table" or type(srv.setup) ~= "function" then
      vim.notify(("LSP: server module '%s' unavailable"):format(name), vim.log.levels.INFO)
    else
      local ok_setup, err = pcall(srv.setup, shared)
      if not ok_setup then
        vim.notify(("LSP: setup failed for '%s': %s"):format(name, err or "?"), vim.log.levels.WARN)
      end
    end
  end
  return true
end

return M
