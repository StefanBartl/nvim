local nvlsp = require("nvchad.configs.lspconfig")
local project_root = vim.fn.getcwd()
local lua_root = project_root .. "/lua"
local diagfilter = require("configs.lsp_filter")

vim.diagnostic.handlers.virtual_text = {
  show = diagfilter.filter_diagnostics,
  hide = vim.diagnostic.handlers.virtual_text.hide,
  update = diagfilter.filter_diagnostics,
}

local nvlsp = require("nvchad.configs.lspconfig")

-- Aktuelles Projektverzeichnis
local project_root = vim.fn.getcwd()
-- Lua-Code des Projekts
local lua_root = project_root .. "/lua"

-- Hilfsfunktion: Runtime-Dateien automatisch laden
local function get_nvim_runtime_libs()
  local libs = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/vim/**/*.lua", true)) do
    libs[path] = true
  end
  return libs
end

return {
  name = "lua_ls",
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = project_root,
  capabilities = nvlsp.capabilities,
  on_attach = function(client, bufnr)
    require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
    if nvlsp.on_attach then
      nvlsp.on_attach(client, bufnr)
    end
  end,
  settings = {
    Lua = {
      runtime = {
        -- LuaJIT, wie von Neovim verwendet
        version = "LuaJIT",
        -- Pfade für require() etc.
        path = vim.split(package.path, ";"),
      },
      diagnostics = {
        -- Erlaubte globale Variablen (vim, vim.fn, vim.uv, etc.)
        globals = { "vim", "vim.uv", "vim.fn", "vim.inspect", "vim.loop" },
      },
      workspace = {
        -- Keine Abfrage externer Module wie node_modules etc.
        checkThirdParty = false,
        -- Manuelle und dynamisch erkannte Pfade
        library = vim.tbl_extend("force", {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. "/lua"] = true,
          [lua_root] = true,
        }, get_nvim_runtime_libs()),
      },
      telemetry = {
        enable = false,
      },
      completion = {
        callSnippet = "Replace",
      },
    },
  },
}
