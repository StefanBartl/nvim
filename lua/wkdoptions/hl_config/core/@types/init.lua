---@meta
---@module 'wkdoptions.hl_config.core.@types'
---
--- Type definitions for core modules: state management and highlight application.

---@alias FeatureName
---| '"line"' # CursorLine enabled
---| '"column"' # CursorColumn enabled
---| '"color_persist"' # Re-apply highlights after colorscheme
---| '"yank_flash"' # Flash yanked region
---| '"put_flash"' # Flash pasted region
---| '"signcolumn_tint"' # Tint SignColumn by diagnostic severity
---| '"terminal_palette"' # Apply TermNormal/TermCursorLine
---| '"mode_colors"' # Per-mode CursorLine tinting
---| '"current_word"' # Underline word under cursor
---| '"indent_scope"' # Highlight active indent block
---| '"breadcrumbs"' # Show winbar breadcrumbs
---| '"diff_peek"' # Git hunk preview keymap
---| '"cword_occurrences"' # Highlight all <cword> occurrences

---@class WKDOptions.HL_CFG.Core.State
--- Centralized state management: feature flags, window cache, namespace/augroup registry.
--- Replaces scattered global tables with queryable container.
---@field get_win_mode fun(win: integer): string|nil # Get cached mode for window (nil if not cached)
---@field set_win_mode fun(win: integer, mode: string): nil # Set cached mode for window (used by mode_tint to avoid redundant updates)
---@field clear_win_mode fun(win: integer): nil # Clear cached mode for window (call on WinClosed)
---@field is_enabled fun(name: FeatureName): boolean # Check if feature is enabled (fast lookup from cached flags)
---@field set_enabled fun(name: FeatureName, enabled: boolean): nil # Set feature enabled state (called by after_set on config changes)
---@field get_namespace fun(name: string): integer # Get or create namespace handle (cached, idempotent, prefixed with "myopt_")
---@field get_augroup fun(name: string, clear: boolean|nil): integer # Get or create augroup handle via lib.nvim.bindings.autocmd ("myopt" prefix, clear defaults to true)
---@field init_from_config fun(cfg: WKDOptions.HL_CFG): nil # Initialize feature flags from config (call once during enable())

---@class WKDOptions.HL_CFG.Core.Highlights
--- Safe highlight group application with error guards and validation.
---@field set_hl_safe fun(name: string, spec: table): boolean, string|nil # Apply single highlight group (returns success + error string)
---@field apply_all fun(colors: WKDOptions.HighlightColors): table<string, string> # Apply all highlight groups from colors table (returns map of group_name → error_msg for failures)
---@field exists fun(name: string): boolean # Check if highlight group exists (follows links, validates name)
---@field ensure_hl fun(name: string, fallback: table): nil # Create fallback highlight if group doesn't exist or is empty (idempotent)

---@class WKDOptions.HL_CFG.Core
--- All core modules consolidated.
---@field state WKDOptions.HL_CFG.Core.State
---@field highlights WKDOptions.HL_CFG.Core.Highlights

return {}
