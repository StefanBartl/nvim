---@meta
---@module 'usrcmds.migrate.opt.@types'

---@class MigrateOpt.Match
---@field bufnr number|nil Buffer number (only for buffer-local matches)
---@field fname string|nil File name (absolute path for file matches)
---@field lnum number Line number (1-indexed)
---@field text string Original line text
---@field migrated string Migrated line text
---@field source "buf"|"file" Source type: buffer or file

return {}
