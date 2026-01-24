---@meta
---@module 'wkdoptions.@types'
---
--- Extended type definitions for wkdoptions with new hl_config hierarchy.
--- This extends the existing types with the refactored module structure.

require("wkdoptions.@types.options")
require("wkdoptions.@types.skip")
require("wkdoptions.@types.commands")
require("wkdoptions.hl_config.@types")

---@class WKDOptions.EnableArgs
---@field highlights boolean|nil
---@field higlights boolean|nil # Typo-friendly alias
---@field options boolean|nil

---@class WKDOptions.Config
---@field highlight WKDOptions.HL_CFG
---@field skip WKDOptions.HL_CFG.Utils.SkipCfg
---@field options OptionsCfg

---@class WKDOptions.Modules
--- Top-level wkdoptions module structure (extended with refactored hl_config).
---@field hl_config WKDOptions.HL_CFG # Refactored visual/UX features subsystem
---@field options_config table # Editor options & global toggles (unchanged)
---@field config WKDOptions.Config # Central configuration table (unchanged)
---@field commands table # User command registration (unchanged)
---@field skip table # Skip rules evaluation (unchanged, but consider moving to hl_config.utils)

---@class WKDOptions
--- Main wkdoptions module API.
---@field setup fun(opts: WKDOptions.EnableArgs|nil): nil # Enable selected subsystems (highlights, options)

return {}
