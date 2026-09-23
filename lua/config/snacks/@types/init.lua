---@meta
---@module 'config.snacks.@types'

---@class Cfg.Snacks.Mappings.Module
---@field keys fun(): (string|function|table)[]  Return keymap table for lazy spec.

---@class Cfg.Snacks
---@field mappings Cfg.Snacks.Mappings.Module

---@class snacks.Picker
---@field close fun(self: snacks.Picker): nil

--- Only the keys this config reads off a picker item and snacks does NOT
--- name itself. `file` and `text` used to be listed here too and were both
--- `duplicate-doc-field`: snacks declares them in
--- `snacks/picker/config/defaults.lua`, and re-opening a class to repeat a
--- field it already has is a duplicate, not an override.
---@class snacks.picker.Item
---@field path? string
---@field filename? string
---@field item? table<string, any>

-- A `snacks.picker.todo_comments` field used to be declared here: the
-- picker source todo-comments.nvim registered at runtime, which snacks'
-- generated types did not know. The plugin is gone (insights.nvim's
-- `:Insights todos` replaced it, 2026-09-19), and with it the source.

return {}
