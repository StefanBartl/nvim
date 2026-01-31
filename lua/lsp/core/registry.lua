---@module 'lsp.core.registry'

local notify = require("lib.notify").create("[lsp.core.registry]")

local M = {}

local desc_tag = "[lsp.registry] "

local ACTIVE = {
  "bashls",
  "lua_ls",
  "ts_ls",
  "gopls",
  "marksman",
  -- "emmet_ls",
  "html",
  --"clangd",
  --"csharp",
  --"zig",

  -- Mobile development servers
  "jdtls", -- Java (Android)
  "kotlin_language_server", -- Kotlin (Android)
  "dartls", -- Dart/Flutter
}

function M.setup_all(shared)
  if type(shared) ~= "table" then
    return false
  end

  -- on ios add sourcekit
  if require("lib.cross.platform.is_macos")() then
    ACTIVE[#ACTIVE + 1] = "sourcekit"
  end

  for _, name in ipairs(ACTIVE) do
    local mod = "lsp.servers." .. name
    local ok, srv = pcall(require, mod)
    if not ok or type(srv) ~= "table" or type(srv.setup) ~= "function" then
      notify.info((desc_tag .. "server module '%s' unavailable"):format(name))
    else
      local ok_setup, err = pcall(srv.setup, shared)
      if not ok_setup then
        notify.warn((desc_tag .. "setup failed for '%s': %s"):format(name, err or "?"))
      end
    end
  end
  return true
end

return M
