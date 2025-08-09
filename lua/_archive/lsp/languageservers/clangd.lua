---@module "lsp.languageservers.clangd"
---@brief C/C++ language server configuration using clangd with System/Mason auto-detection
---@version 0.1.0

---@alias LspAny any
---@alias Path string

---@class ClangdInitOptions
---@field clangdFileStatus boolean
---@field semanticHighlighting boolean
---@field fallbackFlags? string[]|nil

---@class ClangdConfig
---@field cmd string[]
---@field on_attach fun(client:LspAny, bufnr:integer)
---@field on_init fun(client:LspAny, initialize_result:LspAny)
---@field capabilities table
---@field root_dir fun(fname:Path):Path
---@field init_options ClangdInitOptions

---@diagnostic disable: unused-local
---@nodiscard
---@as ClangdConfig

local attach = require("lsp.attach")
local util = require("lspconfig.util")
local nvlsp = require("nvchad.configs.lspconfig")

-- Resolve clangd from PATH, else from Mason, else fallback name.
local function resolve_cmd()
  local exepath = vim.fn.exepath("clangd")
  if exepath and exepath ~= "" then
    return { exepath }
  end
  local ok, mr = pcall(require, "mason-registry")
  if ok then
    local ok_pkg, pkg = pcall(mr.get_package, "clangd")
    if ok_pkg and pkg:is_installed() then
      local base = pkg:get_install_path()
      local bin = util.path.join(base, "clangd", "bin", "clangd")
      if vim.loop.fs_stat(bin .. ".exe") then return { bin .. ".exe" } end
      if vim.loop.fs_stat(bin) then return { bin } end
    end
  end
  return { "clangd" }
end

local M = {
  cmd = resolve_cmd(),
  on_attach = attach.on_attach,
  on_init = nvlsp.on_init,
  capabilities = attach.capabilities,
  root_dir = function(fname)
    return util.root_pattern("compile_commands.json", "compile_flags.txt", ".clangd")(fname)
        or util.find_git_ancestor(fname)
        or util.path.dirname(fname)
  end,
  init_options = {
    clangdFileStatus = true,
    semanticHighlighting = true,
    -- fallbackFlags = { "-std=c17" },   -- enable for C single-file fallback
    -- fallbackFlags = { "-std=c++20" }, -- enable for C++
  },
}

return M
