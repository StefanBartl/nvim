---@module 'custom.function_index.@types.config'
-- Configuration Types
require("lua.lib.require_dir")("custom.function_index.@types", "")

--- Configuration for persistent cache behavior.
---@class CacheConfig
---@field enabled boolean           # Whether to use persistent caching
---@field dir string                # Directory to store cache files (default: stdpath("cache")/function_index)
---@field ttl_seconds integer       # Time-to-live for cache entries (default: 3600)

--- Configuration for indexing behavior and filtering.
---@class IndexingConfig
---@field auto_rebuild_on_save boolean  # Automatically rebuild index when files are saved
---@field exclude_patterns string[]     # Patterns to exclude from indexing (e.g., "node_modules/")
---@field max_file_size_kb integer      # Skip files larger than this size (default: 1024)
---@field follow_symlinks boolean       # Whether to follow symbolic links (default: false)

--- Per-language enable/disable flags.
--- Set to false to exclude a language from indexing.
---@class LanguageConfig
---@field lua boolean
---@field python boolean
---@field javascript boolean
---@field typescript boolean
---@field go boolean
---@field rust boolean
---@field c boolean
---@field cpp boolean
---@field java boolean
---@field ruby boolean
---@field php boolean

--- UI and picker customization options.
---@class UIConfig
---@field show_language_icons boolean  # Display language icons in picker (requires nerd fonts)
---@field show_function_types boolean  # Display function type (local, method, etc.) in picker
---@field group_by_file boolean        # Group entries by filename in picker
---@field default_picker string        # Default picker to use: "telescope" or "fzf"

--- Root configuration object for the function_index module.
--- Passed to setup() and merged with defaults.
---@class FunctionIndexConfig
---@field enable_user_commands boolean Enable :FunctionIndex* commands
---@field enable_keymaps boolean Enable default keymaps
---@field keymaps table<string, string> Keymap definitions
---@field default_scope "cwd"|"buffer" Default search scope

return {}
