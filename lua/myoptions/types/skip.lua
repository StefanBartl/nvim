---@module 'myoptions.skip'

---@class SkipCfg
---@field filetypes string[]           -- exact filetype names to skip
---@field name_patterns string[]       -- Lua patterns against buffer name (full path or URI)

---@class SkipMatchers
---@field ftset table<string, true>    -- O(1) lookup set for filetypes
---@field npats string[]               -- raw Lua patterns for buffer name

