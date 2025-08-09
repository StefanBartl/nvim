---@module "lsp.languageservers.lua_ls"
---@brief lua-language-server config + optional setup()

local M = {}

-- Optional NvChad defaults (capabilities/on_init), guarded
local ok_nv, nvlsp = pcall(require, "nvchad.configs.lspconfig")

-- Your diagnostic filter integration
local diagfilter = require("lsp.filter")

-- Root resolution: prefer current working dir to keep your previous behavior
local project_root = vim.fn.getcwd()
local lua_root = project_root .. "/lua"

-- Install filtered virtual_text handler
vim.diagnostic.handlers.virtual_text = {
  show = diagfilter.filter_diagnostics,
  hide = vim.diagnostic.handlers.virtual_text.hide,
  update = diagfilter.filter_diagnostics,
}

---Collect Neovim runtime lua library files as a set(path->true).
---@return table<string, boolean>
local function get_nvim_runtime_libs()
  local libs = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/vim/**/*.lua", true)) do
    libs[path] = true
  end
  return libs
end

-- Compose capabilities with fallbacks (NvChad -> cmp_nvim_lsp -> vanilla)
local function compute_capabilities()
  if ok_nv and type(nvlsp.capabilities) == "table" then
    return nvlsp.capabilities
  end
  local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp and type(cmp.default_capabilities) == "function" then
    return cmp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

---@class LuaLsConfig
---@field name string
---@field cmd string[]
---@field filetypes string[]
---@field root_dir string
---@field capabilities table
---@field on_attach fun(client,lsp.Client,bufnr:integer)
---@field on_init fun(client,lsp.Client,initialize_result:table)
---@field settings table

---The actual configuration table, usable for both lspconfig.setup(...) and vim.lsp.start(...)
M.config = {
  name = "lua_ls",
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = project_root,
  capabilities = compute_capabilities(),
  on_init = function(client, initialize_result)
    if ok_nv and type(nvlsp.on_init) == "function" then
      pcall(nvlsp.on_init, client, initialize_result)
    end
  end,
  on_attach = function(client, bufnr)
    -- Workspace diagnostics (guarded)
    pcall(function()
      require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
    end)
    -- Forward to NvChad on_attach if present
    if ok_nv and type(nvlsp.on_attach) == "function" then
      pcall(nvlsp.on_attach, client, bufnr)
    end
  end,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        -- Keep your extended search path; last element merges package.path
        path = { "lua/?.lua", "lua/?/init.lua", "@types/?.lua", vim.split(package.path, ";") },
      },
      diagnostics = {
        globals = { "vim", "vim.uv", "vim.fn", "vim.inspect", "vim.loop" },
      },
      workspace = {
        checkThirdParty = false,
        library = vim.tbl_extend("force", {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.stdpath("config") .. "/lua"] = true,
          [lua_root] = true,
        }, get_nvim_runtime_libs()),
      },
      telemetry = { enable = false },
      completion = { callSnippet = "Replace" },
    },
  },
}

-- Idempotent setup() for lspconfig
local _did_setup = false

---Call lspconfig.lua_ls.setup(...) once. Safe to call multiple times.
---@return nil
function M.setup()
  if _did_setup then return end
  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if not ok_lsp then return end
  lspconfig.lua_ls.setup(M.config)
  _did_setup = true
end

return M
