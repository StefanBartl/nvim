---@meta
---@module 'wkdoptions.hl_config.cword_occurrences.@types'
---
--- Type definitions for <cword> occurrences highlighting module.
--- Already extensively documented in wkdoptions/@types/cword_occurences.lua,
--- here we add the public API surface.

---@class WKDOptions.HL_CFG.CwordOccurrences
--- Highlight all occurrences of <cword> except the one under cursor.
--- Supports "highlight" and underline-family rendering modes with configurable slicing.
---@field refresh fun(): nil # Rebuild decorations immediately for active window/buffer (forced update, no debounce)
---@field enable fun(): nil # Install autocmds/timers and perform initial paint (CursorMoved/CursorMovedI/BufEnter/TextChanged/etc.)

--- Note: Detailed config types (CwordOccurrencesCfg, CwordRender, CwordMarking, etc.)
--- are already defined in wkdoptions/@types/cword_occurences.lua (typo preserved for compat).
--- This file only adds the module API surface to the type hierarchy.

return {}
