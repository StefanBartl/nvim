---@meta
---@module 'wkdoptions.hl_config.features.@types'
---
--- Type definitions for all hl_config feature modules.
--- Each feature follows a consistent interface pattern with enable/refresh/apply methods.

---@class WKDOptions.HL_CFG.Features.CursorLine
--- CursorLine and CursorColumn activation/deactivation with config-aware guards.
---@field activate fun(cfg: WKDOptions.HL_CFG, mode: string|nil): nil # Activate cursorline/column for active window with optional mode tinting
---@field deactivate fun(): nil # Deactivate cursorline/column for inactive windows (map to Normal)
---@field resolve_line_hl fun(mode: string, cfg: WKDOptions.HL_CFG): string # Resolve CursorLine HL group based on mode (returns group name)

---@class WKDOptions.HL_CFG.Features.ModeTint
--- Per-mode CursorLine tinting with window-local mode cache.
--- Prevents redundant winhighlight updates by tracking last-applied mode per window.
---@field update fun(cfg: WKDOptions.HL_CFG, ev: table|nil): nil # Update tint based on ModeChanged event or current mode
---@field clear_cache fun(win: integer): nil # Clear cached mode for closed window (call on WinClosed)
---@field enable fun(cfg: WKDOptions.HL_CFG): nil # Install ModeChanged/BufWinEnter/WinClosed autocmds

---@class WKDOptions.HL_CFG.Features.Flash
--- Yank and Put flash feedback with safe timer cleanup.
---@field flash_changed fun(group: string, ms: integer): nil # Flash region defined by marks '[' and ']' with given HL group for ms duration
---@field enable_yank fun(): nil # Install TextYankPost autocmd for yank flash
---@field enable_put fun(): nil # Install safe p/P mappings with put flash
---@field enable fun(cfg: WKDOptions.HL_CFG): nil # Enable yank/put flash based on config flags

---@class MyOptions.HL_CFG.Features.SigncolTint
--- SignColumn tinting based on worst diagnostic severity in buffer.
--- Maps SignColumn → SignColError/Warn/Info/Hint/Neutral via winhighlight.
---@field apply fun(): nil # Apply tint to current window based on buffer diagnostics
---@field clear fun(): nil # Remove tint (reset to SignColNeutral)
---@field enable fun(cfg: WKDOptions.HL_CFG): nil # Install DiagnosticChanged/BufEnter autocmds

---@class MyOptions.HL_CFG.Features.TermPalette
--- Terminal window harmonization: applies TermNormal/TermCursorLine.
---@field apply fun(): nil # Apply terminal-specific palette to current window (checks buftype = "terminal")
---@field enable fun(cfg: WKDOptions.HL_CFG): nil # Install TermOpen autocmd

---@class MyOptions.HL_CFG.Features.CurrentWord
--- Underline the word under cursor using window-local matchaddpos().
--- Only affects the single occurrence containing the cursor (low visual noise).
---@field update fun(): nil # Update underline for <cword> at cursor position (skips insert mode, UI buffers)
---@field enable fun(cfg: WKDOptions.HL_CFG): nil # Install CursorMoved/InsertEnter/BufLeave/WinLeave autocmds

---@class MyOptions.HL_CFG.Features.IndentScope
--- Viewport-limited indent scope highlighting: tints full lines of active indentation block.
--- Uses viewport bounds (w0..w$) and respects large_file_kb + skip rules.
---@field refresh fun(cfg: WKDOptions.HL_CFG): nil # Update indent scope highlight for current viewport (clears + reapplies)
---@field refresh_current fun(): nil # Refresh using global config (wrapper for after_set integration)
---@field enable fun(cfg: WKDOptions.HL_CFG): nil # Install BufEnter/CursorMoved/WinScrolled autocmds

---@class MyOptions.HL_CFG.Features.DiffPeek
--- Git hunk preview via gitsigns.nvim integration.
--- Maps `gh` to preview_hunk_inline/preview_hunk when gitsigns is available.
---@field enable fun(cfg: WKDOptions.HL_CFG): nil # Install or clear `gh` keymap based on feature state + gitsigns availability

---@class MyOptions.HL_CFG.Features
--- All feature modules consolidated for type checking and IDE support.
---@field cursorline MyOptions.HL_CFG.Features.CursorLine
---@field mode_tint MyOptions.HL_CFG.Features.ModeTint
---@field flash MyOptions.HL_CFG.Features.Flash
---@field signcolumn_tint MyOptions.HL_CFG.Features.SigncolTint
---@field terminal_palette MyOptions.HL_CFG.Features.TermPalette
---@field current_word MyOptions.HL_CFG.Features.CurrentWord
---@field indent_scope MyOptions.HL_CFG.Features.IndentScope
---@field diff_peek MyOptions.HL_CFG.Features.DiffPeek

return {}
