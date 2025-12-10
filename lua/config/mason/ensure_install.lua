---@module 'config.mason.ensure_install'
--- Ensure-install facade around mason.nvim (and its registry) for LSPs, DAP adapters,
--- linters and formatters. The module exposes granular entry points
--- (`enable_lsp`, `enable_dap`, `enable_linters`, `enable_formatters`) plus a
--- high-level `enable(cfg)` orchestrator.
--- De-duplicate installs across categories to avoid concurrent install
--- attempts of the same Mason package (fixes "Package is already installing.").
---
--- Now with aggregated summary: instead of per-package notifications, a single
--- summary is shown after all install attempts have completed.
---
--- Design goals:
---   • Pure mason-registry usage, no hard dependency on mason-lspconfig/mason-nvim-dap/etc.
---   • Per-tool on/off switches (boolean map) with safe defaults for Linux/macOS.
---   • External dependency guards (e.g., dotnet/mvn) with clear warnings instead of failing installs.
---   • Robust logging and defensive error handling; no hard errors on missing packages.
---
--- How to use:
---   require('config.mason.ensure_install').enable({
---     lsp = true,
---     dap = true,
---     linters = true,
---     formatters = true,
---     overrides = {
---       lsp = { ['java-language-server'] = false },
---       dap = { ['node-debug2-adapter'] = false },
---       linters = { ['eslint_d'] = true },
---       formatters = { ['prettier'] = true },
---     },
---   })

local M = {}

-- =====================================================================================
-- Aggregated summary session
-- =====================================================================================

---@class MasonEnsureSession
---@field open boolean
---@field pending integer
---@field results table<string, table<string,string[]>>   -- results[kind][category] = { "name (reason)", ... }
---@field installed table<string,string[]>
---@field already table<string,string[]>

local SESSION ---@type MasonEnsureSession
SESSION = {
  open = false,
  pending = 0,
  results = {
    failed = { lsp = {}, dap = {}, linters = {}, formatters = {}, other = {} },
    skipped = { lsp = {}, dap = {}, linters = {}, formatters = {}, other = {} },
    unknown = { lsp = {}, dap = {}, linters = {}, formatters = {}, other = {} },
  },
  installed = { lsp = {}, dap = {}, linters = {}, formatters = {}, other = {} },
  already = { lsp = {}, dap = {}, linters = {}, formatters = {}, other = {} },
}

--- Begin a new aggregation session (idempotent).
local function session_begin()
  if SESSION.open then
    return
  end
  SESSION.open = true
  SESSION.pending = 0
  for k, buckets in pairs(SESSION.results) do
    for cat, _ in pairs(buckets) do
      SESSION.results[k][cat] = {}
    end
  end
  for cat, _ in pairs(SESSION.installed) do
    SESSION.installed[cat] = {}
  end
  for cat, _ in pairs(SESSION.already) do
    SESSION.already[cat] = {}
  end
end

--- Render and show the final summary (only when all pending tasks finished).
local function flush_summary_if_done()
  if not SESSION.open or SESSION.pending > 0 then
    return
  end

  local lines = { "[mason.ensure] Summary" }

  local function add_block(title, tbl)
    local any = false
    for cat, list in pairs(tbl) do
      if #list > 0 then
        if not any then
          lines[#lines + 1] = ""
          lines[#lines + 1] = title .. ":"
          any = true
        end
        lines[#lines + 1] = ("  [%s] %s"):format(cat, table.concat(list, ", "))
      end
    end
  end

  add_block("installed", SESSION.installed)
  add_block("already-installed", SESSION.already)
  add_block("skipped", SESSION.results.skipped)
  add_block("unknown", SESSION.results.unknown)
  add_block("failed", SESSION.results.failed)

  local msg = table.concat(lines, "\n")
  local level = vim.log.levels.INFO
  for _, list in pairs(SESSION.results.failed) do
    if #list > 0 then
      level = vim.log.levels.ERROR
      break
    end
  end

  vim.schedule(function()
    vim.notify(msg, level)
  end)
  SESSION.open = false
end

--- End the session; will flush if there are no pending tasks.
local function session_end()
  flush_summary_if_done()
end

-- =====================================================================================
-- Tool sets (defaults): true = ensure install, false = ignore
-- =====================================================================================

---@type MasonEnsureMap
local LSP_DEFAULTS = {
  ["copilot-language-server"] = true,
  ["java-language-server"] = false,
  ["csharp-language-server"] = false,
  ["zls"] = true,
  ["vue-language-server"] = true,
  ["yaml-language-server"] = true,
  ["vim-language-server"] = true,
  ["ts_query_ls"] = true,
  ["sqlls"] = true,
  ["systemd-language-server"] = true,
  ["svelte-language-server"] = true,
  ["svlangserver"] = true,
  ["pbls"] = true,
  ["python-lsp-server"] = true,
  ["powershell-editor-services"] = true,
  ["perlnavigator"] = false,
  ["phpactor"] = true,
  ["omnisharp-mono"] = false,
  ["nginx-language-server"] = true,
  ["markdown-oxide"] = true,
  ["m68k-lsp-server"] = true,
  ["htmx-lsp"] = true,
  ["lua-language-server"] = true,
  ["jsonld-lsp"] = true,
  ["graphql-language-service-cli"] = true,
  ["html-lsp"] = true,
  ["hoon-language-server"] = true,
  ["gopls"] = true,
  ["golangci-lint-langserver"] = true,
  ["asm-lsp"] = true,
  ["docker-compose-language-service"] = true,
  ["dockerfile-language-server"] = true,
  ["docker-language-server"] = true,
  ["sqls"] = true,
  ["cmake-language-server"] = true,
  ["ast-grep"] = true,
  ["typescript-language-server"] = true,
  ["tailwindcss-language-server"] = true,
  ["bash-language-server"] = true,
  ["css-lsp"] = true,
  ["eslint-lsp"] = true,
  ["json-lsp"] = true,
  ["marksman"] = true,
}

---@type MasonEnsureMap
local DAP_DEFAULTS = {
  ["node-debug2-adapter"] = false,
  ["java-language-server"] = false,
  ["php-debug-adapter"] = true,
  ["netcoredbg"] = true,
  ["js-debug-adapter"] = true,
  ["java-test"] = true,
  ["java-debug-adapter"] = true,
  ["firefox-debug-adapter"] = true,
  ["go-debug-adapter"] = true,
  ["bash-debug-adapter"] = true,
}

---@type MasonEnsureMap
local LINTER_DEFAULTS = {
  ["yamllint"] = true,
  ["systemdlint"] = true,
  ["swiftlint"] = true,
  ["sqlfluff"] = true,
  ["pymarkdownlnt"] = true,
  ["phpcs"] = true,
  ["phpmd"] = true,
  ["markuplint"] = true,
  ["markdownlint-cli2"] = true,
  ["luacheck"] = true,
  ["jsonlint"] = true,
  ["htmlhint"] = true,
  ["golangci-lint"] = true,
  ["eslint_d"] = true,
  ["cmakelint"] = true,
  ["cmakelang"] = true,
  ["ast-grep"] = true,
  ["markdownlint"] = true,
}

---@type MasonEnsureMap
local FORMATTER_DEFAULTS = {
  ["luaformatter"] = true,
  ["yamlfix"] = true,
  ["yamlfmt"] = true,
  ["xmlformatter"] = true,
  ["sqlfmt"] = true,
  ["rustfmt"] = true,
  ["php-cs-fixer"] = true,
  ["pgformatter"] = false,
  ["ormolu"] = false,
  ["phpcbf"] = false,
  ["nginx-config-formatter"] = true,
  ["markdownlint-cli2"] = true,
  ["htmlbeautifier"] = false,
  ["gotests"] = true,
  ["golines"] = true,
  ["goimports"] = true,
  ["goimports-reviser"] = true,
  ["gofumpt"] = true,
  ["cmakelang"] = true,
  ["ast-grep"] = true,
  ["asmfmt"] = true,
  ["prettier"] = true,
  ["sql-formatter"] = true,
  ["markdown-toc"] = true,
  ["markdownlint"] = true,
  ["mdformat"] = true,
}

-- =====================================================================================
-- Dependency guards and name helpers
-- =====================================================================================

---@return boolean
function M.has_dotnet()
  return vim.fn.executable("dotnet") == 1
end

---@return boolean
local function has_maven()
  return vim.fn.executable("mvn") == 1
end

--- Apply external dependency heuristics to avoid failing installs.
--- Aggregation-aware: returns a reason string used in the summary.
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
      return false, "requires 'mvn' on PATH"
    end
  end
  if name == "node-debug2-adapter" then
    return false, "deprecated; prefer 'js-debug-adapter'"
  end
  return true
end

-- =====================================================================================
-- Core ensure logic (mason-registry) with aggregation and de-dup
-- =====================================================================================

--- Internal ensure logic with per-session de-duplication and aggregated summary.
--- Keeps the public API unchanged.
--- @param tools MasonEnsureMap
--- @param log_prefix string
--- @param seen table<string, boolean>|nil
local function ensure_tools(tools, log_prefix, seen)
  local ok_reg, registry = pcall(require, "mason-registry")
  if not ok_reg then
    vim.notify(("%s: mason-registry not available; aborting"):format(log_prefix), vim.log.levels.ERROR)
    return
  end

  -- begin aggregation if not already open
  session_begin()

  -- derive category from log_prefix suffix: ".lsp" | ".dap" | ".linters" | ".formatters"
  local category = (log_prefix:match("%.([^.]+)$") or "other")
  if not SESSION.results.failed[category] then
    category = "other"
  end

  -- shared de-dup set
  seen = seen or {}

  -- refresh index (async, non-blocking)
  pcall(registry.refresh, function() end)

  for name, want in pairs(tools) do
    if not want then
      goto continue
    end
    if seen[name] then
      goto continue
    end
    seen[name] = true

    -- gate by system deps
    local allowed, reason = (function()
      local ok_gate, gate = pcall(require, "config.mason.ensure_install") -- self-require is safe
      if ok_gate and type(gate.gate_by_system_deps) == "function" then
        return gate.gate_by_system_deps(name)
      end
      return gate_by_system_deps(name)
    end)()
    if allowed == false then
      table.insert(SESSION.results.skipped[category], ("%s (%s)"):format(name, reason or "skipped"))
      goto continue
    end

    -- resolve package
    local ok_pkg, pkg = pcall(registry.get_package, name)
    if not ok_pkg or not pkg then
      table.insert(SESSION.results.unknown[category], name .. " (not in registry)")
      goto continue
    end

    -- already installed → record and continue
    if pkg.is_installed and pkg:is_installed() then
      table.insert(SESSION.already[category], name)
      goto continue
    end

    -- attempt install; aggregate events (no per-package notify)
    local ok_install, err = pcall(function()
      SESSION.pending = SESSION.pending + 1
      pkg:install()

      pkg:on("install:success", function()
        table.insert(SESSION.installed[category], name)
        SESSION.pending = SESSION.pending - 1
        flush_summary_if_done()
      end)

      pkg:on("install:failed", function()
        table.insert(SESSION.results.failed[category], name .. " (install:failed)")
        SESSION.pending = SESSION.pending - 1
        flush_summary_if_done()
      end)
    end)

    if not ok_install then
      -- Typical race: "Package is already installing." → treat as skipped with reason
      table.insert(SESSION.results.skipped[category], ("%s (%s)"):format(name, tostring(err)))
    end

    ::continue::
  end
end

--- Merge user overrides on top of defaults.
---@param defaults MasonEnsureMap
---@param overrides MasonEnsureMap|nil
---@return MasonEnsureMap
local function merge(defaults, overrides)
  if not overrides then
    return vim.deepcopy(defaults)
  end
  local out = vim.deepcopy(defaults)
  for k, v in pairs(overrides) do
    out[k] = not not v
  end
  return out
end

-- =====================================================================================
-- Public category entry points (session-aware)
-- =====================================================================================

--- Ensure all configured LSP servers exist (installed via mason).
--- Starts a short session when called standalone; in orchestrated runs the outer
--- session is used.
--- @param overrides MasonEnsureMap|nil
--- @param log_prefix string|nil
--- @param seen table<string, boolean>|nil
function M.enable_lsp(overrides, log_prefix, seen)
  local outer = SESSION.open
  if not outer then
    session_begin()
  end
  ensure_tools(merge(LSP_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".lsp", seen)
  if not outer then
    session_end()
  end
end

--- Ensure all configured DAP adapters exist.
--- @param overrides MasonEnsureMap|nil
--- @param log_prefix string|nil
--- @param seen table<string, boolean>|nil
function M.enable_dap(overrides, log_prefix, seen)
  local outer = SESSION.open
  if not outer then
    session_begin()
  end
  ensure_tools(merge(DAP_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".dap", seen)
  if not outer then
    session_end()
  end
end

--- Ensure all configured linters exist.
--- @param overrides MasonEnsureMap|nil
--- @param log_prefix string|nil
--- @param seen table<string, boolean>|nil
function M.enable_linters(overrides, log_prefix, seen)
  local outer = SESSION.open
  if not outer then
    session_begin()
  end
  ensure_tools(merge(LINTER_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".linters", seen)
  if not outer then
    session_end()
  end
end

--- Ensure all configured formatters exist.
--- @param overrides MasonEnsureMap|nil
--- @param log_prefix string|nil
--- @param seen table<string, boolean>|nil
function M.enable_formatters(overrides, log_prefix, seen)
  local outer = SESSION.open
  if not outer then
    session_begin()
  end
  ensure_tools(merge(FORMATTER_DEFAULTS, overrides), (log_prefix or "mason.ensure") .. ".formatters", seen)
  if not outer then
    session_end()
  end
end

-- =====================================================================================
-- Orchestrator (opens one session for all categories)
-- =====================================================================================

--- High-level orchestrator with shared de-duplication set and aggregated summary.
--- @param cfg { lsp?:boolean, dap?:boolean, linters?:boolean, formatters?:boolean, log_prefix?:string, overrides?:{lsp?:MasonEnsureMap, dap?:MasonEnsureMap, linters?:MasonEnsureMap, formatters?:MasonEnsureMap} }|nil
function M.enable(cfg)
  cfg = cfg or {}
  local do_lsp = (cfg.lsp ~= false)
  local do_dap = (cfg.dap ~= false)
  local do_linters = (cfg.linters ~= false)
  local do_formatters = (cfg.formatters ~= false)
  local prefix = cfg.log_prefix or "mason.ensure"
  local ov = cfg.overrides or {}

  -- Bootstrap Mason once.
  local ok_mason, mason = pcall(require, "mason")
  if ok_mason and type(mason.setup) == "function" then
    pcall(mason.setup, {})
  end

  -- One shared seen-set across all categories in this run.
  local seen = {}

  -- one aggregated session
  session_begin()
  if do_lsp then
    M.enable_lsp(ov.lsp, prefix, seen)
  end
  if do_dap then
    M.enable_dap(ov.dap, prefix, seen)
  end
  if do_linters then
    M.enable_linters(ov.linters, prefix, seen)
  end
  if do_formatters then
    M.enable_formatters(ov.formatters, prefix, seen)
  end
  session_end()
end

-- Optional export if one wants to call the guards elsewhere
M.gate_by_system_deps = gate_by_system_deps

return M
