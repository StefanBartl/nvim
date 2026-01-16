---@meta
---@module 'config.neotree.@types.safety'

---@class Cfg.Neotree.Safety.BackupEntry
---@field original_path string
---@field backup_path string
---@field timestamp number
---@field operation string "delete"|"move"|"overwrite"
---@field metadata table

---@class Cfg.NeoTree.Safety.QueuedOperation
---@field fn fun() Operation function
---@field name string Operation name for logging
---@field priority integer Priority (lower = higher priority)


return {}
