---@meta
---@module 'wkdoptions.hl_config.cword_occurrences.@types'
---
--- Type definitions for the <cword> occurrences highlighting module:
--- the public API surface plus the feature config shape (CwordOccurrencesCfg,
--- referenced from wkdoptions/@types/highlight.lua).

---@class WKDOptions.HL_CFG.CwordOccurrences
--- Highlight all occurrences of <cword> except the one under cursor.
--- Supports "highlight" and underline-family rendering modes with configurable slicing.
---@field refresh fun(): nil # Rebuild decorations immediately for active window/buffer (forced update, no debounce)
---@field enable fun(): nil # Install autocmds/timers and perform initial paint (CursorMoved/CursorMovedI/BufEnter/TextChanged/etc.)

---@alias CwordRender
---| '"highlight"'
---| '"underline"'
---| '"undercurl"'
---| '"underdouble"'
---| '"underdotted"'
---| '"underdashed"'

---@alias CwordMarking
---| '"leadingchar"'
---| '"word"'
---| '"tailchar"'
---| '"firstN"'

---@alias CwordCaseMode "smart"|"sensitive"|"insensitive"
---@alias CwordMatchKind "exact"|"substring"

---@class CwordHlAttr
---@field fg string|nil
---@field bg string|nil
---@field sp string|nil
---@field bold boolean|nil
---@field italic boolean|nil
---@field underline boolean|nil
---@field undercurl boolean|nil
---@field underdouble boolean|nil
---@field underdotted boolean|nil
---@field underdashed boolean|nil
---@field strikethrough boolean|nil
---@field reverse boolean|nil
---@field standout boolean|nil
---@field nocombine boolean|nil
---@field link string|nil

---@class CwordOccurrencesCfg
---@field enabled boolean # Master switch
---@field render CwordRender # Rendering mode
---@field underline_color string|nil # Special color for underline modes
---@field force_plain_underline boolean|nil # Always include plain underline
---@field marking CwordMarking # Slice to render
---@field firstN integer # Leading bytes when marking == "firstN"
---@field viewport_only boolean # Restrict to visible lines
---@field min_len integer # Minimum <cword> length
---@field smart_case boolean # Legacy smart case flag
---@field case_mode CwordCaseMode|nil # Case handling strategy
---@field match_kind CwordMatchKind|nil # Match strategy
---@field in_insert boolean # Keep decorations in Insert mode
---@field hl string # HL group for full-word slices
---@field hl_lead string|nil # HL group for partial slices
---@field hl_attr CwordHlAttr|nil # Fallback attrs for hl
---@field hl_lead_attr CwordHlAttr|nil # Fallback attrs for hl_lead
---@field priority integer # Extmark priority
---@field debounce_ms integer # Debounce interval
---@field large_file_kb integer|nil # Per-feature large file guard

return {}
