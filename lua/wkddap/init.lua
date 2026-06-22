---@module 'wkddap'
---@brief [[
--- Debug Adapter Protocol (DAP) integration for Neovim.
--- Provides comprehensive debugging support for multiple languages with
--- robust error handling, extensibility, and performance optimization.
---
--- Features:
---   • Multi-language debugging (Lua, JS/TS, C/C++, Go, Python, Rust, Zig, Assembly)
---   • Automatic adapter detection and validation
---   • Rich UI integration (dap-ui, virtual-text, signs)
---   • Extensible architecture for adding new languages
---   • Built-in health checks and diagnostics
---
--- Usage:
---   require('dap').setup({
---     languages = { 'lua', 'javascript', 'go' },
---     ui = { enable = true },
---     keymaps = { enable = true }
---   })
---@brief ]]

local notify = require("lib.nvim.notify").create("[wkddap]")

local M = {}

---@type DapSetupOptions
local default_opts = {
  languages = {}, -- Empty = all available
  ui = {
    enable = true,
    virtual_text = true,
    signs = true,
    highlights = true,
  },
  keymaps = {
    enable = true,
    prefix = "<leader>d",
  },
  commands = {
    enable = true,
    autocmds = true,
  },
  auto_install = false,
  log_level = vim.log.levels.WARN,
}

---@type DapSetupOptions|nil
M._config = nil

---@type boolean
M._initialized = false

--- Setup DAP with provided options
---@param opts? DapSetupOptions Configuration options
---@return boolean success
function M.setup(opts)
  if M._initialized then
    notify.warn("[dap] Already initialized")
    return false
  end

  -- Merge with defaults
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  M._config = opts

  -- Load core modules
  local ok_core, core = pcall(require, "wkddap.core")
  if not ok_core then
    notify.error("[dap] Failed to load core module")
    return false
  end

  -- Initialize core
  local ok_init, err = pcall(core.setup, opts)
  if not ok_init then
    notify.error(string.format("[dap] Core initialization failed: %s", err))
    return false
  end

  -- Load and register adapters
  local ok_adapters, adapters_mod = pcall(require, "wkddap.adapters")
  if ok_adapters and type(adapters_mod) == "table" and type(adapters_mod.register_all) == "function" then
    local adapter_success, adapter_err = pcall(adapters_mod.register_all, opts.languages, opts.adapters or {})
    if not adapter_success then
      notify.warn(string.format("[dap] Adapter registration failed: %s", adapter_err or "unknown"))
    end
  else
    notify.warn("[dap] Failed to load adapters module")
  end

  -- Load configurations
  local ok_configs, configurations_mod = pcall(require, "wkddap.configurations")
  if ok_configs and type(configurations_mod) == "table" and type(configurations_mod.load_all) == "function" then
    local config_success, config_err = pcall(configurations_mod.load_all, opts.languages, opts.configurations or {})
    if not config_success then
      notify.warn(string.format("[dap] Configuration loading failed: %s", config_err or "unknown"))
    end
  else
    notify.warn("[dap] Failed to load configurations module")
  end

  -- Setup UI (only after adapters are registered)
  if opts.ui and opts.ui.enable then
    local ok_ui, ui_mod = pcall(require, "wkddap.ui")
    if ok_ui and type(ui_mod) == "table" and type(ui_mod.setup) == "function" then
      pcall(ui_mod.setup, opts.ui)
    end
  end

  -- Setup keymaps
  if opts.keymaps and opts.keymaps.enable then
    local ok_keymaps, keymaps_mod = pcall(require, "wkddap.keymaps")
    if ok_keymaps and type(keymaps_mod) == "table" and type(keymaps_mod.setup) == "function" then
      pcall(keymaps_mod.setup, opts.keymaps)
    end
  end

  -- Setup commands
  if opts.commands and opts.commands.enable then
    local ok_commands, commands_mod = pcall(require, "wkddap.commands")
    if ok_commands and type(commands_mod) == "table" and type(commands_mod.setup) == "function" then
      pcall(commands_mod.setup, opts.commands)
    end
  end

  M._initialized = true

  -- AUDIT: Implement notify toggle
  -- vim.notify("[dap] Initialized successfully", vim.log.levels.INFO)
  return true
end

--- Get current configuration
---@return DapSetupOptions|nil
function M.get_config()
  return M._config
end

--- Check if DAP is initialized
---@return boolean
function M.is_initialized()
  return M._initialized
end

--- Get available languages
---@return string[]
function M.available_languages()
  local ok, registry = pcall(require, "wkddap.registry")
  if ok and registry then
    return registry.available_languages()
  end
  return {}
end

--- Get enabled languages
---@return string[]
function M.enabled_languages()
  local ok, registry = pcall(require, "wkddap.registry")
  if ok and registry then
    return registry.enabled_languages()
  end
  return {}
end

return M
