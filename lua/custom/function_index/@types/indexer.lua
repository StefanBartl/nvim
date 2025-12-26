---@module 'custom.function_index.@types.indexer'
-- Indexer Types
require("lua.lib.require_dir")("custom.function_index.@types", "")

--- Internal state of the indexer during index building.
--- Not exposed to users, used for async operations.
---@class IndexerState
---@field entries IndexEntry[]      # Accumulated function entries
---@field total_files integer       # Total files scanned
---@field total_functions integer   # Total functions found
---@field errors string[]           # Errors encountered during indexing
---@field started_at number         # Timestamp when indexing started
---@field finished_at number|nil    # Timestamp when indexing finished (nil if in progress)

--- Defines a regex pattern and metadata for detecting functions in a language.
--- Stored in core/patterns.lua.
---@class LanguagePattern
---@field language string
---@field pattern string            # PCRE2-compatible regex pattern
---@field func_type function|string    # Default type for matches (can be overridden by capture groups)
---@field name_capture integer      # Capture group index for function name (1-indexed)
---@field signature_capture integer|nil  # Optional capture group for full signature

return {}
