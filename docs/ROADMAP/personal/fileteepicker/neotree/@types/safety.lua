---@meta
---@module 'config.neotree.@types.safety'
---@brief Safety and recovery system structures
---@description
--- Types for backup creation, recovery points, and operation queueing
--- to ensure safe file system operations with rollback capability.

---@class Cfg.NeoTree.Safety.BackupEntry
---@field original_path string Source file/directory path
---@field backup_path string Backup location
---@field timestamp number Unix timestamp of backup creation
---@field operation Cfg.NeoTree.FileOperation Type of operation that triggered backup
---@field metadata table Additional context (size, permissions, etc.)

---@class Cfg.NeoTree.Safety.RecoveryPoint
---@field timestamp number When recovery point was created
---@field operation string Human-readable operation name
---@field state table Serializable state snapshot for rollback
---@field paths string[] Affected file paths

---@class Cfg.NeoTree.Safety.QueuedOperation
---@field fn fun() Operation function to execute
---@field name string Operation identifier for logging
---@field priority integer Execution priority (lower = higher priority)

return {}
