---@module 'custom.function_index.@types.config'
-- Configuration Types

---@class CacheConfig
--- Configuration for persistent cache behavior.
---@field enabled boolean           # Whether to use persistent caching
---@field dir string                # Directory to store cache files (default: stdpath("cache")/function_index)
---@field ttl_seconds integer       # Time-to-live for cache entries (default: 3600)

---@class IndexingConfig
--- Configuration for indexing behavior and filtering.
---@field auto_rebuild_on_save boolean  # Automatically rebuild index when files are saved
---@field exclude_patterns string[]     # Patterns to exclude from indexing (e.g., "node_modules/")
---@field max_file_size_kb integer      # Skip files larger than this size (default: 1024)
---@field follow_symlinks boolean       # Whether to follow symbolic links (default: false)

---@class LanguageConfig
--- Per-language enable/disable flags.
--- Set to false to exclude a language from indexing.
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

---@class UIConfig
--- UI and picker customization options.
---@field show_language_icons boolean  # Display language icons in picker (requires nerd fonts)
---@field show_function_types boolean  # Display function type (local, method, etc.) in picker
---@field group_by_file boolean        # Group entries by filename in picker
---@field default_picker string        # Default picker to use: "telescope" or "fzf"

---@class FunctionIndexConfig
--- Root configuration object for the function_index module.
--- Passed to setup() and merged with defaults.
---@field cache CacheConfig
---@field indexing IndexingConfig
---@field languages LanguageConfig
---@field ui UIConfig

return {}
