---@meta
---@module 'usrcmds.gather.@types'

---@class UsrCmds.Gather.Config
---@field lua boolean  # Enable Lua gathering commands

-- ==================================================================
-- lua

---@class UsrCmds.Gather.Lua.ScanStats
---@field total_files integer      # Total Lua files found
---@field total_dirs integer        # Total directories containing Lua files
---@field total_lines integer       # Estimated total lines of code
---@field estimated_time_sec number # Estimated scan time in seconds

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

return {}
