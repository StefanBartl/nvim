---@meta
---@module 'config.@tyes.telescope.types'

---@alias HistoryBackend
--- Identifies the active history storage backend.
---| "sqlite" # SQLite database via telescope-smart-history (preferred)
---| "file"   # Plain text file fallback (stdpath("data")/picker-history/)
---| "none"   # No history backend available (functionality disabled)

---@class HistoryConfig
--- Configuration structure returned by history.setup() for telescope defaults.
---@field path string Absolute path to history storage (sqlite3 file or text file)
---@field limit integer Maximum number of history entries to retain

---@class HistoryExtensionConfig
--- Extension-specific configuration for telescope extensions table.
--- Only populated when sqlite backend is active.
---@field smart_history? {limit: integer} Config for smart_history extension
