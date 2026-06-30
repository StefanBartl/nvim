---@meta
---@module 'config.neotree.@types.watcher'
---@brief File system watcher quarantine and error handling
---@description
--- Types for managing file watcher errors, quarantine states,
--- and EPERM error suppression during intensive operations.

---@class Cfg.NeoTree.WatcherQuarantine.State
---@field in_quarantine boolean Global quarantine active flag
---@field quarantine_until number Timestamp when quarantine ends (vim.loop.now())
---@field suspended_paths table<string, number> Per-path quarantine timestamps
---@field error_suppressed boolean EPERM suppression active
---@field original_notify? function Backup of original vim.notify

return {}
