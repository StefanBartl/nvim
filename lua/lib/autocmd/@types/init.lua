---@meta
---@module 'lib.autocmd.@types'

---@class Lib.Autocmd.Args
---@field id integer Autocommand ID
---@field event string Event name
---@field group integer|nil Augroup ID
---@field match string Matched pattern
---@field buf integer Buffer number
---@field file string Filename
---@field data any Event-specific data

---@class LibAutocmdOpts
---@field group? string|integer
---@field pattern? string|string[]
---@field desc? string
---@field once? boolean
---@field nested? boolean

---@class Lib.AutoCmd
---@field group fun(name: string, clear: boolean|nil): integer # Create autocommand group
---@field create fun(event: string|string[], callback: fun(args:Lib.Autocmd.Args), opts: LibAutocmdOpts|nil): nil # Create autocommand
---@field get_augroup fun(name: string, opts: { clear?: boolean, prefix?: string }|nil): integer # Augroup registry: Centralized augroup creation with optional prefixing and deduplication.

return {}
