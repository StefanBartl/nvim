---@meta
---@module 'config.neotree.@types.trash'
---@brief Trash/deletion system type definitions
---@description
--- Types for safe file deletion with backup, recovery, and batch operations.

---@class Cfg.NeoTree.Trash.Config
---@field use_safety_system? boolean # Enable full safety features (default: true)
---@field create_backups? boolean # Create backups before deletion (default: true)
---@field confirm_dangerous? boolean # Confirm dangerous operations (default: true)
---@field use_dry_run? boolean # Respect dry-run mode (default: true)
---@field auto_close_buffers? boolean # Auto-close open buffers without asking (default: false)
---@field debug? boolean # Enable debug logging
---@field quarantine_duration? integer # Increased from 2000
---@field pre_delete_wait? integer # Wait before deletion
---@field post_delete_wait? integer # Wait after deletion

return {}
