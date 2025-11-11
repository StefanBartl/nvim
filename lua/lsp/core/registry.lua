---@module 'lsp.core.registry'

local notify = vim.notify
local levels = vim.log.levels

local M = {}

local desc_tag = "[lsp.registry] "

local ACTIVE = {
	"bashls",
  "lua_ls",
  "ts_ls",
  "gopls",
	"marksman",
	"emmet_ls",
	"html",
  --"clangd",
  --"csharp",
  --"zig",
}

function M.setup_all(shared)
  if type(shared) ~= "table" then return false end
  for _, name in ipairs(ACTIVE) do
    local mod = "lsp.servers." .. name
    local ok, srv = pcall(require, mod)
    if not ok or type(srv) ~= "table" or type(srv.setup) ~= "function" then
      notify((desc_tag .. "server module '%s' unavailable"):format(name), levels.INFO)
    else
      local ok_setup, err = pcall(srv.setup, shared)
      if not ok_setup then
        notify((desc_tag .. "setup failed for '%s': %s"):format(name, err or "?"), levels.WARN)
      end
    end
  end
  return true
end

return M
