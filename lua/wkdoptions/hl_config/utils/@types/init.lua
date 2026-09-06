---@meta
---@module 'wkdoptions.hl_config.utils.@types'
---
--- Type definitions for utility modules shared across features.

---@class WKDOptions.HL_CFG_WinhlPair
--- Parsed winhighlight mapping pair (validated).
---@field from string # Source highlight group (word characters + underscore only)
---@field to string # Target highlight group (word characters + underscore only)

---@class WKDOptions.HL_CFG.Utils.Winhighlight
--- Safe winhighlight parsing and manipulation (prevents E5248).
--- Uses memoization for parse() to avoid repeated string operations.
---@field serialize fun(pairs: WKDOptions.HL_CFG_WinhlPair[]): string # Serialize pairs back to winhighlight CSV (re-validates defensively)
---@field set_pair fun(wh: string|nil, from: string, to: string|nil): string # Set or remove single mapping (to=nil removes mapping)
---@field merge fun(wh: string|nil, new_pairs: table<string, string>): string # Merge new pairs into existing (new pairs win on collision)
---@field apply_to_window fun(win: integer, wh: string): boolean # Safe wrapper to set winhighlight on window (validates win, uses pcall)

---@class WKDOptions.HL_CFG.Utils.LargeFile
--- File size guards with memoization and safe fs_stat calls.
--- Memoizes size per path (weak-keyed cache) to avoid repeated syscalls.
---@field exceeds fun(bufnr: integer|nil, limit_kb: integer): boolean # Check if buffer exceeds size threshold (handles unnamed/invalid buffers)
---@field is_large fun(bufnr: integer|nil, cfg: WKDOptions.HL_CFG): boolean # Check against global large_file_kb threshold
---@field is_large_for_feature fun(bufnr: integer|nil, feature_limit: integer|nil, cfg: WKDOptions.HL_CFG): boolean # Check against feature-specific threshold (nil → use global)

---@class WKDOptions.HL_CFG.Utils.Separator
--- Breadcrumb separator resolution with Nerd Font fallback (memoized).
--- Prefers explicit string, then Nerd Font hex with single-cell validation, then Unicode fallback.
---@field resolve fun(cfg: WKDOptions.HL_CFG): string # Resolve effective separator from config (memoized by hex for Nerd Font path)

---@class WKDOptions.HL_CFG.Utils.Skip
--- Skip rules evaluation for UI-like buffers.
---@field build_matchers fun(cfg: WKDOptions.HL_CFG.Utils.SkipCfg): WKDOptions.HL_CFG.Utils.SkipMatchers # Build O(1) filetype set + name pattern list from config
---@field buffer_is_ui_like fun(matchers: WKDOptions.HL_CFG.Utils.SkipMatchers, bufnr: integer|nil): boolean # Check if buffer matches skip rules (buftype/filetype/name patterns)
---@field std_skip fun(bufnr: integer|nil): boolean # Standard skip check using global config (convenience wrapper)

---@class WKDOptions.HL_CFG.Utils.SkipMatchers
--- Compiled skip matchers for fast buffer evaluation.
---@field ftset table<string, true> # O(1) lookup set for exact filetype matches
---@field npats string[] # Lua patterns for buffer name matching (full path or URI)

---@class WKDOptions.HL_CFG.Utils.SkipCfg
---@field filetypes string[]           -- exact filetype names to skip
---@field name_patterns string[]       -- Lua patterns against buffer name (full path or URI)

---@class WKDOptions.HL_CFG.Utils
--- All utility modules consolidated.
---@field winhighlight WKDOptions.HL_CFG.Utils.Winhighlight
---@field large_file WKDOptions.HL_CFG.Utils.LargeFile
---@field separator WKDOptions.HL_CFG.Utils.Separator
---@field skip WKDOptions.HL_CFG.Utils.Skip

return {}
