---@meta
---@module 'config.snacks.@types'

---@class Cfg.Snacks
---@field usrcmds config.snacks.usrcmds.Module

---@class Cfg.Snacks.Mappings.Module
---@field keys fun(): (string|function|table)[] # Return keymap table for lazy spec.

---@class Cfg.Snacks
---@field usercommads config.snacks.usrcmds.Module
---@field mappings Cfg.Snacks.Mappings.Module


---@class snacks.Picker
---@field close fun(self: snacks.Picker): nil

---@class snacks.picker.Item
---@field file? string
---@field path? string
---@field filename? string
---@field item? table<string, any>
---@field text? string

return {}
