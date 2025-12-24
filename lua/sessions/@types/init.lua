---@meta
---@module 'sessions.@types'
---@brief Shared type aliases and class-like docs for sessions.
---@description
--- Centralized type annotations used by the sessions modules to keep source files lean.
--- Follows the project's "types-in-separate-files" guideline to improve readability and tooling.
--- See architecture & coding rules for comments and tag usage discipline.

---@alias SessionsPath string # Absolute filesystem path
---@alias SessionName string  # Logical session identifier (filename without extension)

---@class SessionsBlacklist
---@field buftypes string[]   # Excluded buffer types, e.g. {"quickfix","nofile","prompt"}
---@field filetypes string[]  # Excluded filetypes, e.g. {"gitcommit","gitrebase"}
---@field paths string[]      # Excluded absolute path prefixes, e.g. {"/tmp/","/private/tmp/"}

---@class SessionsCfg
---@field root SessionsPath   # Root directory for session files (within stdpath('config')/sessions)
---@field default_name SessionName
---@field sessionoptions string
---@field blacklist SessionsBlacklist

---@class SessionInfo
---@field name SessionName
---@field path SessionsPath

return {}
