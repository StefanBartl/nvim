---@module 'custom.insert.@types'
---@brief Central type definitions for the insert module
---@description
--- This module provides type definitions used across all insert submodules.
--- It defines the command registry structure and common interfaces.

---@alias Custom.Insert.SubcommandName
---| "filepath"     -- Insert file paths in various formats
---| "module"       -- Insert Lua module annotations
---| "timestamp"    -- Insert timestamps/dates
---| "uuid"         -- Insert UUIDs/GUIDs
---| "boilerplate"  -- Insert code templates
---| "function"
---| "class"

---@class Custom.Insert.SubcommandDef
---@field handler fun(args: string[]): nil Function that handles the subcommand
---@field complete fun(arg_lead: string, cmdline: string, cursor_pos: integer): string[]|nil Completion function
---@field nargs string Argument specification ("0", "1", "+", "*", "?")
---@field range boolean|nil Whether command accepts range
---@field desc string Description for command completion

---@class Custom.Insert.Registry
---@field subcommands table<Custom.Insert.SubcommandName, Custom.Insert.SubcommandDef>

---@class Custom.Insert.Config
---@field enable_legacy_commands boolean Whether to keep old commands
---@field default_subcommand Custom.Insert.SubcommandName|nil Default subcommand if none given

return {}
