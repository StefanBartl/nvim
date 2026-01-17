---@module 'custom.function_index.@types.cache'
-- Cache Types
require("lua.lib.require").dir("custom.function_index.@types", "")

--- Metadata stored alongside cached index entries.
--- Used to determine cache validity.
---@class CacheMetadata
---@field version string            # Cache format version (for migration)
---@field indexed_at number         # Timestamp of last full index
---@field cwd string                # Working directory when index was created
---@field file_count integer        # Number of files indexed
---@field entry_count integer       # Number of function entries

--- Internal representation of an indexed function with metadata.
--- Used for caching and incremental updates.
---@class IndexEntry
---@field entry FunctionEntry       # The function entry itself
---@field file_mtime number         # File modification time (os.time() or uv.fs_stat)
---@field indexed_at number         # Timestamp when this entry was indexed

--- Structure of the serialized cache file.
---@class CachedIndex
---@field metadata CacheMetadata
---@field entries IndexEntry[]

return {}
