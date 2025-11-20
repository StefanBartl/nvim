---@module 'lsp.servers.csharp'
--- Omnisharp via native LSP config/enable (Neovim ≥ 0.11).

local lsp = vim.lsp
local executable = vim.fn.executable

---@class CsharpServer
local M = {}

---@return string|nil
local function find_omnisharp()
  if executable("omnisharp") == 1 then
    return "omnisharp"
  end
  local ok, mason_registry = pcall(require, "mason-registry")
  if ok then
    local ok_pkg, pkg = pcall(mason_registry.get_package, "omnisharp")
    if ok_pkg and pkg and pkg.is_installed and pkg:is_installed() then
      local exe = pkg:get_install_path() .. "/omnisharp"
      if executable(exe) == 1 then
        return exe
      end
    end
  end
  return nil
end

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  shared = shared or {}
  opts = opts or {}

  local cmd = find_omnisharp()
  if not cmd then
    vim.notify("C#: Omnisharp not found; skipping LSP", vim.log.levels.INFO)
    return
  end

  -- Define config
  if type(lsp.config) == "table" then
    lsp.config("omnisharp", {
      cmd = { cmd },
      filetypes = { "cs" },
      capabilities = shared.capabilities,
      on_attach = shared.on_attach,
      on_init = shared.on_init,
      enable_roslyn_analyzers = true,
      organize_imports_on_format = true,
      root_markers = { ".git", ".sln", ".csproj" },
    })
    if opts.enable ~= false then
      pcall(lsp.enable, "omnisharp")
    end
  end
end

return M
