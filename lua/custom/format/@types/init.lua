---@module 'custom.format.@types'
---@brief Central type definitions for the format module
---@description
--- This module provides type definitions used across all format submodules.
--- It defines the command registry structure and common interfaces.

---@alias Custom.Format.SubcommandName
---| "column"      -- Align character to column
---| "table"       -- Format Markdown tables
---| "textwidth"   -- Reflow text to width
---| "filter"      -- Filter lines by pattern
---| "trim"        -- Remove trailing whitespace
---| "sort"        -- Sort lines
---| "unique"      -- Remove duplicate lines
---| "case"        -- Change case
---| "indent"      -- Fix indentation
---| "clear"       -- Clear buffer content

---@class Custom.Format.SubcommandDef
---@field handler fun(args: string[]): nil Function that handles the subcommand
---@field complete fun(arg_lead: string, cmdline: string, cursor_pos: integer): string[]|nil Completion function
---@field nargs string Argument specification ("0", "1", "+", "*", "?")
---@field range boolean|nil Whether command accepts range
---@field desc string Description for command completion

---@class Custom.Format.Registry
---@field subcommands table<Custom.Format.SubcommandName, Custom.Format.SubcommandDef>

---@class Custom.Format.Config
---@field enable_legacy_commands boolean Whether to keep old :ColumnAlignToColumn etc. commands
---@field default_subcommand Custom.Format.SubcommandName|nil Default subcommand if none given

return {}
