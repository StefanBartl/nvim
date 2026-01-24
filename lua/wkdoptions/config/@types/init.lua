---@meta
---@module 'wkdoptions.config.@types'

---@class WKDOptions.Config.Observer
---@field callbacks fun(key:string)[]

---@class WKDOptions.Config.Observers
---@field highlight WKDOptions.Config.Observer
---@field options WKDOptions.Config.Observer

---@class WKDOptions.Config.Parser
---@field parse fun(s: string|nil): boolean|number|string

---@class WKDOptions.Config.Setter
---@field set_by_path fun(t: table, path: string, val: any, toggle_if_bool: boolean): boolean, string|nil

---@class WKDOptions.Config.Getter
---@field get_by_path fun(t: table, path: string): any|nil
---@field collect_keys fun(root: table, prefix: string|nil, out: string[]): nil

---@class WKDOptions.Config.Core
---@field parser WKDOptions.Config.Parser
---@field setter WKDOptions.Config.Setter
---@field getter WKDOptions.Config.Getter
---@field observer table

---@class WKDOptions.Config.Data
---@field highlight WKDOptions.HL_CFG
---@field options OptionsCfg
---@field skip WKDOptions.HL_CFG.Utils.SkipCfg

---@class WKDOptions.Config.Module
---@field cfg WKDOptions.Config.Data
---@field parse fun(s: string|nil): boolean|number|string
---@field set fun(ns: '"highlight"'|'"options"', key: string, value: any, toggle_if_bool: boolean): boolean, string|nil
---@field keys fun(ns: '"highlight"'|'"options"'): string[]
---@field on_after_set fun(ns: '"highlight"'|'"options"', fn: fun(key:string):nil): nil

return {}
