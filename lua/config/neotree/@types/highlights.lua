---@meta
---@module 'config.neotree.@types.highlights'
---@brief Current file highlighting configuration
---@description
--- Types for highlighting the currently open file and its parent
--- directory in Neo-tree. Supports dynamic colors and git status integration.

---@alias Cfg.NeoTree.HighlightColor string|table
--- Color specification: "#rrggbb", "link:Group", "red", or { fg="#rrggbb", bold=true, ... }

---@class Cfg.NeoTree.CurrentHl.Colors
---@field file Cfg.NeoTree.HighlightColor Current file highlight
---@field parent Cfg.NeoTree.HighlightColor Parent directory highlight

---@class Cfg.NeoTree.CurrentHl.State
---@field current_file? string Currently highlighted file path
---@field current_parent? string Currently highlighted parent path
---@field timer? uv.uv_timer_t Debounce timer handle

return {}
