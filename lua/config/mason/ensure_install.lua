---@module 'config.mason.ensure_install'
--- Ensure-install facade around mason.nvim (and its registry) for LSPs, DAP adapters,
--- linters and formatters. The module exposes granular entry points
--- (`enable_lsp`, `enable_dap`, `enable_linters`, `enable_formatters`) plus a
--- high-level `enable(cfg)` orchestrator.
---
--- Design goals:
---   • Pure mason-registry usage, no hard dependency on mason-lspconfig/mason-nvim-dap/etc.
---   • Per-tool on/off switches (boolean map) with safe defaults for Linux/macOS.
---   • External dependency guards (e.g., dotnet/mvn) with clear warnings instead of failing installs.
---   • Robust logging and defensive error handling; no hard errors on missing packages.
---
--- How to use:
---   require('config.mason.ensure_install').enable({
---     lsp = true,       -- enable/disable the whole LSP batch (default: true)
---     dap = true,       -- enable/disable DAP batch (default: true)
---     linters = true,   -- enable/disable linters batch (default: true)
---     formatters = true,-- enable/disable formatters batch (default: true)
---     overrides = {
---       lsp = { ['java-language-server'] = false },           -- disable a single tool
---       dap = { ['node-debug2-adapter'] = false },            -- disable deprecated/legacy
---       linters = { ['eslint_d'] = true },                    -- ensure enabled even if default false
---       formatters = { ['prettier'] = true },                 -- ditto
---     },
---   })

-- Optional: if you prefer to run categories ad-hoc, you can call the granular APIs:
-- require('config.mason.ensure_install').enable_lsp()
-- require('config.mason.ensure_install').enable_dap({ ["js-debug-adapter"] = true })
-- require('config.mason.ensure_install').enable_linters()
-- require('config.mason.ensure_install').enable_formatters()

-- Notes/Guidance:
-- • On Linux/macOS, many tools will “just install”. For Java/C# stacks you likely need:
--   - Java: JDK and Apache Maven (“mvn”) available in PATH for the java-language-server family.
--   - C# : dotnet SDK in PATH for omnisharp/netcoredbg.
-- • Deprecated adapters:
--   - node-debug2-adapter is deprecated; prefer js-debug-adapter.
-- • If you also use mason-lspconfig / mason-nvim-dap / mason-null-ls:
--   - This module remains compatible; it only ensures packages exist in the mason registry.
--   - You can keep your existing LSP/DAP/null-ls setups for actual configuration/attach.

---@class MasonEnsure
local M = {}

local api = vim.api

-- Lazy require with pcall so this module can load even if mason isn't yet set up.
---@return boolean, table
local function req(mod)
  local ok, m = pcall(require, mod)
  return ok, m
end

-- -------------------------------------------------------------------------------------
-- Tool sets (defaults): true = ensure install, false = ignore
-- Note: Some tools require system deps. We detect common ones and warn.
-- -------------------------------------------------------------------------------------

---@type MasonEnsureMap
local LSP_DEFAULTS = {
  -- Likely/problematic (guarded below):
  ["java-language-server"]    = false,  -- requires: mvn (Maven) → set true if mvn is available
  ["csharp-language-server"]  = false,  -- older csharp LSP (OmniSharp alternatives below)
  -- Installed/desired:
  ["zls"]                      = true,
  ["vue-language-server"]      = true,
  ["yaml-language-server"]     = true,
  ["vim-language-server"]      = true,
  ["ts_query_ls"]              = true,
  ["sqlls"]                    = true,
  ["systemd-language-server"]  = true,
  ["svelte-language-server"]   = true,
  ["svlangserver"]             = true,
  ["pbls"]                     = true,
  ["python-lsp-server"]        = true,
  ["powershell-editor-services"]= true,
  ["perlnavigator"]            = true,
  ["phpactor"]                 = true,
  -- ["omnisharp"]                = true,  -- requires dotnet; if missing, install will fail → guarded below
  ["omnisharp-mono"]           = false, -- legacy; keep off by default
  ["nginx-language-server"]    = true,
  ["markdown-oxide"]           = true,
  ["m68k-lsp-server"]          = true,
  ["htmx-lsp"]                 = true,
  ["lua-language-server"]      = true,
  ["jsonld-lsp"]               = true,
  ["graphql-language-service-cli"] = true,
  ["html-lsp"]                 = true,
  ["hoon-language-server"]     = true,
  ["gopls"]                    = true,
  ["golangci-lint-langserver"] = true,
  ["asm-lsp"]                  = true,
  ["docker-compose-language-service"] = true,
  ["dockerfile-language-server"] = true,
  ["docker-language-server"]   = true,
  ["sqls"]                     = true,
  ["cmake-language-server"]    = true,
  ["ast-grep"]                 = true,  -- appears as tool too; mason package is "ast-grep"
  ["typescript-language-server"]= true,
  ["tailwindcss-language-server"]= true,
  ["bash-language-server"]     = true,
  ["css-lsp"]                  = true,
  ["eslint-lsp"]               = true,
  ["json-lsp"]                 = true,
  ["marksman"]                 = true,
}

---@type MasonEnsureMap
local DAP_DEFAULTS = {
  -- Problematic/legacy:
  ["node-debug2-adapter"] = false,  -- deprecated; modern is js-debug-adapter
  ["java-language-server"] = false, -- requires mvn
  -- Installed/desired:
  ["php-debug-adapter"]    = true,
  ["netcoredbg"]           = true,  -- requires dotnet; guarded below
  ["js-debug-adapter"]     = true,
  ["java-test"]            = true,
  ["java-debug-adapter"]   = true,
  ["firefox-debug-adapter"]= true,
  ["go-debug-adapter"]     = true,
  ["bash-debug-adapter"]   = true,
}

---@type MasonEnsureMap
local LINTER_DEFAULTS = {
  ["yamllint"]              = true,
  ["systemdlint"]           = true,
  ["swiftlint"]             = true,
  ["sqlfluff"]              = true,
  ["pymarkdownlnt"]         = true, -- note: mason id is "pymarkdownlnt" (PyMarkdown Linter)
  ["phpcs"]                 = true,
  ["phpmd"]                 = true,
  ["markuplint"]            = true,
  ["markdownlint-cli2"]     = true,
  ["luacheck"]              = true,
  ["jsonlint"]              = true,
  ["htmlhint"]              = true,
  ["golangci-lint"]         = true,
  ["eslint_d"]              = true,
  ["cmakelint"]             = true,
  ["cmakelang"]             = true,
  ["ast-grep"]              = true,
  ["markdownlint"]          = true,
}

---@type MasonEnsureMap
local FORMATTER_DEFAULTS = {
  ["luaformatter"]           = true,
  ["yamlfix"]                = true,
  ["yamlfmt"]                = true,
  ["xmlformatter"]           = true,
  ["sqlfmt"]                 = true,
  ["rustfmt"]                = true,
  ["php-cs-fixer"]           = true,
  ["pgformatter"]            = true,
  ["ormolu"]                 = true,
  ["phpcbf"]                 = true,
  ["nginx-config-formatter"] = true,
  ["markdownlint-cli2"]      = true,
  ["htmlbeautifier"]         = true,
  ["gotests"]                = true,
  ["golines"]                = true,
  ["goimports"]              = true,
  ["goimports-reviser"]      = true,
  ["gofumpt"]                = true,
  ["cmakelang"]              = true,
  ["ast-grep"]               = true,
  ["asmfmt"]                 = true,
  ["prettier"]               = true,
  ["sql-formatter"]          = true,
  ["markdown-toc"]           = true,
  ["markdownlint"]           = true,
  ["mdformat"]               = true,
}

-- -------------------------------------------------------------------------------------
-- Dependency guards and name helpers
-- -------------------------------------------------------------------------------------

---@return boolean
function M.has_dotnet()
  return vim.fn.executable("dotnet") == 1
end

---@return boolean
local function has_maven()
  return vim.fn.executable("mvn") == 1
end

--- Apply external dependency heuristics to avoid failing installs.
---@param name string
---@return boolean allowed, string? reason
local function gate_by_system_deps(name)
  if name == "omnisharp" or name == "netcoredbg" or name == "csharp-language-server" then
    if not M.has_dotnet() then
      return false, "requires 'dotnet' on PATH"
    end
  end
  if name == "java-language-server" or name == "java-debug-adapter" or name == "java-test" then
    if not has_maven() then
      return false, "requires 'mvn' (Apache Maven) on PATH"
    end
  end
  if name == "node-debug2-adapter" then
    return false, "deprecated; prefer 'js-debug-adapter'"
  end
  return true
end

-- -------------------------------------------------------------------------------------
-- Core ensure logic (mason-registry)
-- -------------------------------------------------------------------------------------

---@param tools MasonEnsureMap
---@param log_prefix string
local function ensure_tools(tools, log_prefix)
  local ok_reg, registry = req("mason-registry")
  if not ok_reg then
    vim.notify(("%s: mason-registry not available; aborting"):format(log_prefix), vim.log.levels.ERROR)
    return
  end

  -- Refresh package index first to get the latest names.
  local refreshed = false
  registry.refresh(function()
    refreshed = true
  end)
  if not refreshed then
    -- If mason is already initialized, refresh may be synchronous; continue regardless.
  end

  for name, want in pairs(tools) do
    if not want then
      goto continue
    end

    local allowed, reason = gate_by_system_deps(name)
    if not allowed then
      vim.notify(("%s: skip '%s' → %s"):format(log_prefix, name, reason), vim.log.levels.WARN)
      goto continue
    end

    local ok_pkg, pkg = pcall(registry.get_package, name)
    if not ok_pkg then
      vim.notify(("%s: unknown package '%s' (not in registry?)"):format(log_prefix, name), vim.log.levels.WARN)
      goto continue
    end

    if pkg:is_installed() then
      -- Already installed; no-op.
      goto continue
    end

    -- Install asynchronously; report result.
    pkg:install()
    pkg:on("install:success", function()
      vim.schedule(function()
        vim.notify(("%s: installed '%s'"):format(log_prefix, name), vim.log.levels.INFO)
      end)
    end)
    pkg:on("install:failed", function()
      vim.schedule(function()
        vim.notify(("%s: FAILED to install '%s'"):format(log_prefix, name), vim.log.levels.ERROR)
      end)
    end)

    ::continue::
  end
end

--- Merge user overrides on top of defaults.
---@param defaults MasonEnsureMap
---@param overrides MasonEnsureMap|nil
---@return MasonEnsureMap
local function merge(defaults, overrides)
  if not overrides then return vim.deepcopy(defaults) end
  local out = vim.deepcopy(defaults)
  for k, v in pairs(overrides) do
    out[k] = not not v
  end
  return out
end

-- -------------------------------------------------------------------------------------
-- Public category entry points
-- -------------------------------------------------------------------------------------

--- Ensure all configured LSP servers exist (installed via mason).
---@param overrides MasonEnsureMap|nil
---@param log_prefix string|nil
---@return nil
function M.enable_lsp(overrides, log_prefix)
  ensure_tools(merge(LSP_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".lsp")
end

--- Ensure all configured DAP adapters exist.
---@param overrides MasonEnsureMap|nil
---@param log_prefix string|nil
---@return nil
function M.enable_dap(overrides, log_prefix)
  ensure_tools(merge(DAP_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".dap")
end

--- Ensure all configured linters exist.
---@param overrides MasonEnsureMap|nil
---@param log_prefix string|nil
---@return nil
function M.enable_linters(overrides, log_prefix)
  ensure_tools(merge(LINTER_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".linters")
end

--- Ensure all configured formatters exist.
---@param overrides MasonEnsureMap|nil
---@param log_prefix string|nil
---@return nil
function M.enable_formatters(overrides, log_prefix)
  ensure_tools(merge(FORMATTER_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".formatters")
end

-- -------------------------------------------------------------------------------------
-- Orchestrator
-- -------------------------------------------------------------------------------------

--- High-level entry point. Installs the selected categories.
---@param cfg MasonEnsureCfg|nil
---@return nil
function M.enable(cfg)
  cfg = cfg or {}
  local do_lsp        = (cfg.lsp ~= false)
  local do_dap        = (cfg.dap ~= false)
  local do_linters    = (cfg.linters ~= false)
  local do_formatters = (cfg.formatters ~= false)
  local prefix        = cfg.log_prefix or "mason.ensure"
  local ov            = cfg.overrides or {}

  -- Mason bootstrap: safe itialization without relying on mason.is_setup().
  do
    local ok_mason, mason = pcall(require, "mason")
    if ok_mason and type(mason.setup) == "function" then
      -- Protected call; silently ignores "already setup" cases or differing configs.
      pcall(mason.setup, {})
    end
  end

  if do_lsp        then M.enable_lsp(ov.lsp,         prefix) end
  if do_dap        then M.enable_dap(ov.dap,         prefix) end
  if do_linters    then M.enable_linters(ov.linters, prefix) end
  if do_formatters then M.enable_formatters(ov.formatters, prefix) end
end

return M

