---@meta
---@module 'autocmds.benchmarks.context.@types'

---@class AutoCmds.Context.BufferCtx
---@field bufnr integer Buffer handle
---@field name string Full buffer path (empty if unnamed)
---@field filetype string Buffer filetype
---@field buftype string Buffer type (empty for normal files)
---@field modifiable boolean Whether buffer can be modified
---@field modified boolean Whether buffer has unsaved changes
---@field tick integer Buffer changedtick (for cache validation)
---@field lines string[]|nil Lazy-loaded buffer lines
---@field line_count integer Number of lines in buffer
---@field size_bytes integer Approximate size in bytes
---@field is_valid boolean Whether buffer still exists
---@field is_normal? fun(self: AutoCmds.Context.BufferCtx): boolean
---@field has_filetype? fun(self: AutoCmds.Context.BufferCtx, ft: string|string[]): boolean
---@field is_processable? fun(self: AutoCmds.Context.BufferCtx, ignore_buftypes: table<string, boolean>|nil, ignore_filetypes: table<string, boolean>|nil): boolean

---@class AutoCmds.Context.WindowCtx
---@field winid integer Window handle
---@field bufnr integer Associated buffer
---@field cursor integer[] [row, col] (1-indexed)
---@field topline integer First visible line
---@field botline integer Last visible line
---@field width integer Window width
---@field height integer Window height
---@field is_valid boolean Whether window still exists
---@field get_visible_lines? fun(self: AutoCmds.Context.WindowCtx): integer

-- AUDIT: Wird NICHT verwendet momentan?!?!
---@class AutoCmds.Context.CacheEntry
---@field value any
---@field tick integer Buffer changedtick when cached
---@field timestamp number os.clock() when cached
---@field ttl number? Time-to-live in seconds

return {}
