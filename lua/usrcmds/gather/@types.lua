---@meta
---@module 'usrcmds.gather.@types'

---@alias UsrCmds.Gather.Lua.ScanMode "buffer"|"cwd"  # Scan current buffer only or scan all Lua files in current working directory

---@class UsrCmds.Gather.Lua.Match
---@field name string         # Symbol name (function/table/string)
---@field line integer        # Line number (1-based)
---@field col integer         # Column number (0-based)
---@field file string|nil     # File path (only in cwd mode)
---@field context string|nil  # Additional context (e.g., parent table path)

---@class UsrCmds.Gather.Lua.FileMatches
---@field path string              # Absolute file path
---@field matches UsrCmds.Gather.Lua.Match[]

---@class UsrCmds.Gather.Lua.ScanResult
---@field matches UsrCmds.Gather.Lua.Match[]
---@field errors string[]

---@alias UsrCmds.Gather.Lua.GatherType "functions"|"tables"|"strings"

---@class UsrCmds.Gather.Config
---@field lua boolean  # Enable Lua gathering commands

return {}
