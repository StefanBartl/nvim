---@meta
---@module 'config.snacks.@types'

---@class Cfg.Snacks.Mappings.Module
---@field keys fun(): (string|function|table)[] # Return keymap table for lazy spec.

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

--- `todo-comments.nvim` registers this picker source into
--- `Snacks.picker.sources` from its own `setup()` (todo-comments/config.lua),
--- so it exists at runtime -- but snacks' generated `picker/types.lua` lists
--- only snacks' own sources, so nothing declares it.
---@class snacks.picker
---@field todo_comments fun(opts?: snacks.picker.todo.Config|{}): snacks.Picker

return {}
