---@module 'custom.mygrep.types.aliases'
---@class ToolState
---@brief Represents the session and persistent state for a grep tool.
---@field history string[] Past search queries (persisted)
---@field favorites string[] Favorited queries (persisted)
---@field undo UndoEntry[] In-memory undo stack (non-persistent)

---@class UndoEntry
---@field action '"delete"'|'"unfavorite"'
---@field value string

-- No runtime content, purely for annotations
local M = {}

return M
