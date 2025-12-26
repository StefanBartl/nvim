---@module 'custom.function_index.@types.cache'
-- Cache Types

--- Metadata stored alongside cached index entries.
--- Used to determine cache validity.
---@class CacheMetadata
---@field version string            # Cache format version (for migration)
---@field indexed_at number         # Timestamp of last full index
---@field cwd string                # Working directory when index was created
---@field file_count integer        # Number of files indexed
---@field entry_count integer       # Number of function entries

--- Structure of the serialized cache file.
---@class CachedIndex
---@field metadata CacheMetadata
---@field entries IndexEntry[]

return {}
