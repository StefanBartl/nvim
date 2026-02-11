---@meta
---@module 'config.snacks.@types'

---@class Cfg.Snacks
---@field usrcmds config.snacks.usrcmds.Module

---@class Cfg.Snacks.Mappings.Module
---@field keys fun(): (string|function|table)[] # Return keymap table for lazy spec.

---@class Cfg.Snacks
---@field usercommads config.snacks.usrcmds.Module
---@field mappings Cfg.Snacks.Mappings.Module

return {}
