---@meta
---@module 'wkdoptions.hl_config.@types'
---
--- Aggregated type definitions for the hl_config subsystem: pulls in every
--- submodule's @types so the whole module tree resolves from one require.

-- Import all submodule types
require("wkdoptions.hl_config.core.@types")
require("wkdoptions.hl_config.features.@types")
require("wkdoptions.hl_config.breadcrumbs.@types")
require("wkdoptions.hl_config.utils.@types")
require("wkdoptions.hl_config.path_cache.@types")
require("wkdoptions.hl_config.cword_occurrences.@types")

---@class WKDOptions.HL_CFG_Modules
--- Type hierarchy for the Highlight_Cfg subsystem (all visual/UX features:
--- cursorline, mode tinting, flash, breadcrumbs, indent scope, ...).
---@field core_module WKDOptions.HL_CFG.Core # State management + highlight application
---@field features_module WKDOptions.HL_CFG.Features # All feature modules (cursorline, mode_tint, flash, etc.)
---@field breadcrumbs_module WKDOptions.HL_CFG.Breadcrumbs # Winbar rendering + context building
---@field utils_module WKDOptions.HL_CFG.Utils # Shared utilities (winhighlight, large_file, separator, skip)
---@field path_cache_module WKDOptions.HL_CFG.PathCache # Buffer-local repo path caching
---@field cword_occurrences_module WKDOptions.HL_CFG.CwordOccurrences # <cword> occurrences highlighting

---@class WKDOptions.HL_CFG.Main
--- Main module entry point (init.lua).
---@field enable fun(): nil # Enable all features, install autocmds, register commands (call once during wkdoptions.setup)

return {}
