---@module 'custom.function_index.@types.utils'
-- Utility Types

--- Structured error for validation failures.
---@class ValidationError
---@field field string              # Field name that failed validation
---@field message string            # Human-readable error message
---@field value any|nil             # The invalid value (for debugging)

return {}
