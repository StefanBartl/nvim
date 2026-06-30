---@meta
---@module 'config.neotree.@types.project_root'
---@brief Project root detection interface
---@description
--- Minimal interface for project root detection utilities.
--- Used by CWD sync and reveal operations.

---@class ProjectRoot
---@field get fun(bufnr?: integer): Path
--- Compute the project root for a buffer. Returns the root directory
--- path or falls back to buffer directory if no root markers found.

return {}
