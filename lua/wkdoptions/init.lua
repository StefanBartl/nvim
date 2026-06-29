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

local lazy = require("lib.lua.lazy")

local M = {}

-- Lazy-loaded module references using lib.lazy
local get_config = lazy.require("wkdoptions.config")
local get_hl_config = lazy.require("wkdoptions.hl_config")

local function normalize_inactice_win_hl()
  vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
      -- Kopiere Normal zu NormalNC (macht sie identisch)
      local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
      vim.api.nvim_set_hl(0, "NormalNC", normal)
    end,
  })

  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  vim.api.nvim_set_hl(0, "NormalNC", normal)
end

-- Define diagnostic signs with modern API and fallback for older versions
local function set_diagnostic_signs()
  local use_modern_signs = vim.fn.has("nvim-0.10") == 1

  local diagnostic_icons = {
    [vim.diagnostic.severity.ERROR] = " ",
    [vim.diagnostic.severity.WARN] = " ",
    [vim.diagnostic.severity.HINT] = " ",
    [vim.diagnostic.severity.INFO] = " ",
  }

  vim.diagnostic.config({
    signs = use_modern_signs and {
      text = diagnostic_icons,
      numhl = {
        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
      },
    } or true,  -- For older versions: just enable signs
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    virtual_text = {
      spacing = 2,
      prefix = "●",
    },
  })

  -- Fallback for Neovim < 0.10: use deprecated sign_define
  if not use_modern_signs then
    local legacy_signs = {
      Error = " ",
      Warn = " ",
      Hint = " ",
      Info = " ",
    }

    for type, icon in pairs(legacy_signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, {
        text = icon,
        texthl = hl,
        numhl = "",
      })
    end
  end
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
    get_hl_config.enable()
  end

  if enable_opt then
    require("wkdoptions.options_config").enable() -- Absichtlich nicht als upvalue
  end

  if opts.italic_keywords then
    require("wkdoptions.italic_keywords").setup()
  end

  require("wkdoptions.qflist")
  normalize_inactice_win_hl()
  set_diagnostic_signs()
  require("wkdoptions.indent_per_ft")
end

--- Expose config module API for programmatic access
---@type WKDOptions.Config.Module
M.config = {
  ---@diagnostic disable-next-line
  cfg = function()
    return M.get_cfg()
  end,

  parse = function(s)
    return M.parse(s)
  end,

  set = function(ns, key, value, toggle_if_bool)
    return M.set(ns, key, value, toggle_if_bool)
  end,

  keys = function(ns)
    return M.keys(ns)
  end,

  on_after_set = function(ns, fn)
    return M.on_after_set(ns, fn)
  end,
}

--- Get full configuration (lazy-loaded).
--- Recommended over direct access to ensure initialization.
---@nodiscard
---@return WKDOptions.Config.Data
function M.get_cfg()
  return get_config.get_cfg()
end

--- Parse a string into a typed value (boolean/number/string).
--- Uses memoization for performance with frequently used values.
---@nodiscard
---@param s string|nil
---@return boolean|number|string
function M.parse(s)
  return get_config.parse(s)
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
  return get_config.set(ns, key, value, toggle_if_bool)
end

--- Get a configuration value by path.
--- Returns nil if key doesn't exist.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@param key string # Dot-separated path
---@return any|nil
function M.get(ns, key)
  -- Use the getter module directly since get_config() doesn't have a .get() method
  local getter = require("wkdoptions.config.core.getter")
  return getter.get_by_path(get_config.get_cfg()[ns], key)
end

--- List all configuration keys for a namespace.
--- Used for command completion.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@return string[] # Sorted list of keys
function M.keys(ns)
  return get_config.keys(ns)
end

--- Register after-set callback for configuration changes.
--- Useful for reactive updates when config changes at runtime.
---@param ns '"highlight"'|'"options"'
---@param fn fun(key:string):nil # Callback receives the changed key
---@return nil
function M.on_after_set(ns, fn)
  return get_config.on_after_set(ns, fn)
end

---@type WKDOptions
return M
