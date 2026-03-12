---@module 'lsp.servers.csharp'
--- Omnisharp via native LSP config/enable (Neovim ≥ 0.11).

local notify = require("lib.notify").create("[lsp.servers.csharp]")

local lsp = vim.lsp
local executable = vim.fn.executable

---@class CsharpServer
local M = {}

---@return string|nil
local function find_omnisharp()
  -- 1. EINFACHSTE LÖSUNG: omnisharp ist bereits im PATH!
  --    Das Debug-Script zeigt: "1. omnisharp in PATH: ✓ YES"
  if executable("omnisharp") == 1 then
    -- notify.info("C#: Using omnisharp from PATH")
    return "omnisharp"
  end

  -- 2. FALLBACK: Mason bin directory (Windows-kompatibel)
  local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
  local candidates = {
    mason_bin .. "/omnisharp.CMD",  -- Windows
    mason_bin .. "/omnisharp.cmd",  -- Windows (lowercase)
    mason_bin .. "/omnisharp",      -- Linux/Mac
  }

  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      notify.info("C#: Using omnisharp from Mason: " .. path)
      return path
    end
  end

  -- 3. LETZTER FALLBACK: Mason packages (alter Pfad)
  local mason_pkg = vim.fn.stdpath("data") .. "/mason/packages/omnisharp"
  local old_candidates = {
    mason_pkg .. "/omnisharp.CMD",
    mason_pkg .. "/omnisharp",
  }

  for _, path in ipairs(old_candidates) do
    if vim.fn.executable(path) == 1 then
      notify.info("C#: Using omnisharp from packages: " .. path)
      return path
    end
  end

  notify.warn("C#: omnisharp not found in PATH or Mason")
  return nil
end

---@param shared {capabilities?:table,on_attach?:fun(client,bufnr),on_init?:fun(client,init_result):boolean}|nil
---@param opts { enable?: boolean }|nil
---@return nil
function M.setup(shared, opts)
  -- notify.info("🔧 C# Setup: Starting...") -- DEBUG

  shared = shared or {}
  opts = opts or {}

  local cmd = find_omnisharp()
  if not cmd then
    notify.warn("C#: Omnisharp not found; skipping LSP")
    return
  end

  -- notify.info("🔧 C# Setup: Found cmd = " .. cmd) -- DEBUG

  -- Define config
  if type(lsp.config) == "table" then
    -- notify.info("🔧 C# Setup: lsp.config available") -- DEBUG

    local config_ok, config_err = pcall(function()
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
    end)

    if not config_ok then
      notify.error("🔧 C# Setup: Config failed: " .. tostring(config_err))
      return
    end

    -- notify.info("🔧 C# Setup: Config registered") -- DEBUG

    if opts.enable ~= false then
      local enable_ok, enable_err = pcall(lsp.enable, "omnisharp")
      if not enable_ok then
        notify.error("🔧 C# Setup: Enable failed: " .. tostring(enable_err))
      else
        -- notify.info("🔧 C# Setup: LSP enabled ✓") -- DEBUG
      end
    end
  else
    notify.error("🔧 C# Setup: lsp.config NOT available!")
  end
end
return M
