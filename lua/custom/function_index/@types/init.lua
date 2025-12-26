---@module 'custom.function_index.@types'
---@brief Type definitions for the function_index module
---@description

--- Represents an async operation (used with vim.loop).
---@class AsyncJob
---@field handle userdata|nil      # libuv handle (process, timer, etc.)
---@field callback function         # Callback to invoke on completion
---@field on_error function         # Error handler
---@field is_running boolean        # Whether the job is currently active

--- State for throttled/debounced function calls.
---@class ThrottleState
---@field timer userdata|nil       # libuv timer handle
---@field last_called number       # Timestamp of last invocation
---@field pending_args any[]       # Arguments from most recent call

--- parser.lua

--- Parsed result from a single line of ripgrep output.
--- Used internally by core/parser.lua.
---@class RipgrepResult
---@field filename string
---@field lnum integer
---@field col integer
---@field text string

return {}
