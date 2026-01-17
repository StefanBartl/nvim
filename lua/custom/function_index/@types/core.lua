---@module 'custom.function_index.@types.core'
-- Core Types
require("lua.lib.require").dir("custom.function_index.@types", "")

--- Categorizes the scope and visibility of a function definition.
--- Used for logical grouping and filtering in the UI.
---@alias FunctionType
---| "local"      # Local function (e.g., `local function foo()`)
---| "module"     # Module-level function (e.g., `M.foo = function()`)
---| "exported"   # Explicitly exported function (e.g., `export function`)
---| "method"     # Method within a class/table (e.g., `Class:method()`)
---| "global"     # Global function (e.g., `function foo()`)
---| "anonymous"  # Anonymous function assigned to variable
---| "unknown"    # Could not determine type from pattern

--- Supported programming languages for function indexing.
--- Each language has corresponding regex patterns in core/patterns.lua.
---@alias Language
---| "lua"
---| "python"
---| "javascript"
---| "typescript"
---| "go"
---| "rust"
---| "c"
---| "cpp"
---| "java"
---| "ruby"
---| "php"

--- Represents a single function definition found during indexing.
--- This is the primary data structure passed to UI pickers.
---@class FunctionEntry
---@field filename string          # Absolute or relative path to the file
---@field lnum integer              # Line number (1-indexed)
---@field col integer               # Column number (1-indexed)
---@field text string               # Raw text of the function signature
---@field func_name string          # Extracted function name (for sorting/filtering)
---@field func_type FunctionType    # Categorization of function scope
---@field language Language         # Programming language
---@field signature string          # Cleaned function signature (e.g., "foo(x, y)")

return {}
