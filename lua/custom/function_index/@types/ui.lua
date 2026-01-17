---@module 'custom.function_index.@types.ui'
-- UI Types
require("lua.lib.require").dir("custom.function_index.@types", "")

--- Options passed to UI pickers (Telescope/fzf-lua).
---@class PickerOptions
---@field initial_query string|nil  # Pre-fill picker with this search term
---@field cwd string|nil            # Override working directory
---@field additional_args string[]|nil  # Extra arguments to ripgrep

--- Entry format for Telescope picker.
---@class TelescopeEntry
---@field value FunctionEntry       # Original function entry
---@field display string            # Formatted display string
---@field ordinal string            # String used for fuzzy matching
---@field filename string           # For Telescope's preview
---@field lnum integer              # For Telescope's preview

--- Entry format for fzf-lua picker.
--- fzf-lua expects plain strings; we format them with ANSI codes.
---@class FzfEntry
---@field line string               # Formatted string: "file:lnum:signature"
---@field entry FunctionEntry       # Original entry (attached for action handlers)

return {}
