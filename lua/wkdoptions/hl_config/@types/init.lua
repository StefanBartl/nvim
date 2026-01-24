---@meta
---@module 'wkdoptions.hl_config.@types'
---
--- Aggregated type definitions for the entire hl_config subsystem.
--- Consolidates all submodules (core, features, breadcrumbs, utils, etc.) into a single class hierarchy.
---
--- Usage:
---   Local imports work as usual:
---     local State = require("wkdoptions.hl_config.core.state")
---     State.is_enabled("breadcrumbs")
---
---   This file provides IDE autocomplete for the entire module tree without runtime overhead.

-- Import all submodule types
require("wkdoptions.hl_config.core.@types")
require("wkdoptions.hl_config.features.@types")
require("wkdoptions.hl_config.breadcrumbs.@types")
require("wkdoptions.hl_config.utils.@types")
require("wkdoptions.hl_config.path_cache.@types")
require("wkdoptions.hl_config.cword_occurrences.@types")

---@class WKDOptions.HL_CFG.Modules
--- Complete type hierarchy for hl_config subsystem.
--- All visual/UX features: cursorline, mode tinting, flash, breadcrumbs, indent scope, etc.
---
--- Architecture:
---   - core: state management + safe highlight application
---   - features: isolated feature modules (8 total)
---   - breadcrumbs: winbar rendering + context building
---   - utils: shared utilities (winhighlight, large_file, separator, skip)
---   - path_cache: buffer-local repo path caching
---   - cword_occurrences: <cword> highlighting with configurable rendering
---
--- Performance:
---   - Memoization: fs_stat, separator resolution, winhighlight parsing
---   - Lazy loading: breadcrumbs ctx module loaded on demand
---   - Per-window caching: mode cache to avoid redundant updates
---   - Viewport-limited: indent_scope only scans visible lines
---
--- Safety:
---   - Type guards: all API calls validated before use
---   - pcall wrapping: no silent failures in critical paths
---   - Buffer/window checks: consistent validation across all features
---   - Safe winhighlight: prevents E5248 via strict parsing
---
---@field core WKDOptions.HL_CFG.Core # State management + highlight application
---@field features WKDOptions.HL_CFG.Features # All feature modules (cursorline, mode_tint, flash, etc.)
---@field breadcrumbs WKDOptions.HL_CFG.Breadcrumbs # Winbar rendering + context building
---@field utils WKDOptions.HL_CFG.Utils # Shared utilities (winhighlight, large_file, separator, skip)
---@field path_cache WKDOptions.HL_CFG.PathCache # Buffer-local repo path caching
---@field cword_occurrences WKDOptions.HL_CFG.CwordOccurrences # <cword> occurrences highlighting

---@class WKDOptions.HL_CFG
--- Main module entry point (init.lua).
---@field enable fun(): nil # Enable all features, install autocmds, register commands (call once during wkdoptions.setup)

return {}
