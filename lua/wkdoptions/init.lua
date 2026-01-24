---@module 'wkdoptions'
--- Entry point that enables the two configuration modules:
---   - wkdoptions/hl_config (visual/UX features & highlight groups)
---   - wkdoptions/options_config   (editor options & global toggles)
--- Public API:
---   require('wkdoptions').setup({ highlights = true, options = true })
--- Notes:
---   * 'higlights' is accepted as alias for 'highlights' (typo-friendly).
---   * Modules register their own user commands and autocmds only when enabled.
---   * All modules are lazy-loaded for optimal startup performance.
---   * Configuration system provides live updates via user commands.

local M = {}

-- Lazy-loaded module references
local config_mod, hl_config_mod, options_config_mod

--- Get config module (lazy)
---@nodiscard
---@return WKDOptions.Config.Module
local function get_config()
  if not config_mod then
    config_mod = require("wkdoptions.config")
  end
  return config_mod
end

--- Get hl_config module (lazy)
---@nodiscard
---@return table
local function get_hl_config()
  if not hl_config_mod then
    hl_config_mod = require("wkdoptions.hl_config")
  end
  return hl_config_mod
end

--- Get options_config module (lazy)
---@nodiscard
---@return table
local function get_options_config()
  if not options_config_mod then
    options_config_mod = require("wkdoptions.options_config")
  end
  return options_config_mod
end

--- Enable selected subsystems.
--- This is the main entry point for wkdoptions initialization.
--- Call once during your Neovim startup.
---@param opts WKDOptions.EnableArgs|nil
---@return nil
function M.setup(opts)
  opts = opts or {}

  -- Handle typo-friendly alias ('higlights' -> 'highlights')
  local enable_hl = (opts.highlights ~= nil) and opts.highlights
    or (opts.higlights ~= nil and opts.higlights or false)
  local enable_opt = (opts.options ~= nil) and opts.options or false

  -- Enable subsystems
  if enable_hl then
    get_hl_config().enable()
  end

  if enable_opt then
    get_options_config().enable()
  end
end

--- Expose config module API for programmatic access
---@type WKDOptions.Config.Module
M.config = setmetatable({}, {
  __index = function(_, key)
    return get_config()[key]
  end,
})

--- Get full configuration (lazy-loaded).
--- Recommended over direct access to ensure initialization.
---@nodiscard
---@return WKDOptions.Config.Data
function M.get_cfg()
  return get_config().get_cfg()
end

--- Parse a string into a typed value (boolean/number/string).
--- Uses memoization for performance with frequently used values.
---@nodiscard
---@param s string|nil
---@return boolean|number|string
function M.parse(s)
  return get_config().parse(s)
end

--- Set a configuration value with validation.
--- Triggers observer callbacks on success.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@param key string # Dot-separated path (e.g., "colors.CursorLine.bg")
---@param value any
---@param toggle_if_bool boolean # If true and value is boolean, toggle instead of setting
---@return boolean success
---@return string|nil error
function M.set(ns, key, value, toggle_if_bool)
  return get_config().set(ns, key, value, toggle_if_bool)
end

--- Get a configuration value by path.
--- Returns nil if key doesn't exist.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@param key string # Dot-separated path
---@return any|nil
function M.get(ns, key)
  return get_config().get(ns, key)
end

--- List all configuration keys for a namespace.
--- Used for command completion.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@return string[] # Sorted list of keys
function M.keys(ns)
  return get_config().keys(ns)
end

--- Register after-set callback for configuration changes.
--- Useful for reactive updates when config changes at runtime.
---@param ns '"highlight"'|'"options"'
---@param fn fun(key:string):nil # Callback receives the changed key
---@return nil
function M.on_after_set(ns, fn)
  return get_config().on_after_set(ns, fn)
end

---@type WKDOptions
return M
