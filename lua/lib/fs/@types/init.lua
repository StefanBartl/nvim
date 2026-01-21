---@meta
---@module 'lib.fs.@types'

---@class Lib.Fs
---@field path Lib.Fs.Path
---@field query Lib.Fs.Query
---@field transform Lib.Fs.Transform

---@class Lib.Fs.ALL
---@field joinpath fun(parts: string[]): string
---@field ensure_dir fun(path: string): boolean, string?
---@field is_subpath fun(path: string, base: string): boolean
---@field is_dir fun(p: string): boolean
---@field find_upward_dir fun(names: string[], from: string): string|nil
---@field dedup fun(entries: string[]): string[]
---@field path_shorten fun(path: string, max_len: integer): string
---@field relpath fun(path: string, base: string): string

return {}
