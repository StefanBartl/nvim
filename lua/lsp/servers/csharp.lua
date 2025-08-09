---@module 'lsp.servers.csharp'
---@class CsharpServer

local M = {}

---@return string|nil
local function find_omnisharp()
  if vim.fn.executable("omnisharp") == 1 then
    return "omnisharp"
  end
  local ok, mason_registry = pcall(require, "mason-registry")
  if ok then
    local ok_pkg, pkg = pcall(mason_registry.get_package, "omnisharp")
    if ok_pkg and pkg and pkg.is_installed and pkg:is_installed() then
      local exe = pkg:get_install_path() .. "/omnisharp"
      if vim.fn.executable(exe) == 1 then return exe end
    end
  end
  return nil
end

---@param shared table
---@return nil
function M.setup(shared)
  if type(shared) ~= "table" then return end
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then return end

  local cmd = find_omnisharp()
  if not cmd then
    vim.notify("C#: Omnisharp not found; skipping LSP", vim.log.levels.INFO)
    return
  end

  lspconfig.omnisharp.setup({
    capabilities = shared.capabilities,
    on_attach = shared.on_attach,
    on_init = shared.on_init,
    cmd = { cmd },
    enable_roslyn_analyzers = true,
    organize_imports_on_format = true,
  })
end

return M
