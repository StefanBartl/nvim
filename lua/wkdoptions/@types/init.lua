---@meta
---@module 'wkdoptions.@types'

---@class WKDOptions.EnableArgs
---@field highlights boolean|nil # Enable visual/UX features subsystem
---@field higlights boolean|nil # Typo-friendly alias for 'highlights'
---@field options boolean|nil # Enable editor options subsystem
---@field italic_keywords boolean|nil # Enable italic keywords

---@class WKDOptions.Modules
--- Top-level wkdoptions module structure (extended with refactored hl_config).
---@field hl_config WKDOptions.HL_CFG.Main # Refactored visual/UX features subsystem
---@field options_config { enable: fun(): nil } # Editor options & global toggles
---@field config WKDOptions.Config.Module # Central configuration system
---@field commands WKDOptions.Commands # User command registration

---@class WKDOptions
--- Main wkdoptions module API with extended configuration access.
--- All configuration is lazy-loaded for optimal startup performance.
---@field setup fun(opts: WKDOptions.EnableArgs|nil): nil # Enable selected subsystems (highlights, options). Call once during init.
---@field config WKDOptions.Config.Module # Central configuration module (lazy-loaded)
---@field get_cfg fun(): WKDOptions.Config.Data # Get full configuration (ensures lazy initialization)
---@field parse fun(s: string|nil): boolean|number|string # Parse string to typed value (memoized for performance)
---@field set fun(ns: '"highlight"'|'"options"', key: string, value: any, toggle_if_bool: boolean): boolean, string|nil # Set config value with type validation and observer notification
---@field get fun(ns: '"highlight"'|'"options"', key: string): any|nil # Get config value by dot-separated path (safe, returns nil if not found)
---@field keys fun(ns: '"highlight"'|'"options"'): string[] # List all config keys for completion (sorted alphabetically)
---@field on_after_set fun(ns: '"highlight"'|'"options"', fn: fun(key:string):nil): nil # Register after-set callback for reactive updates

return {}
