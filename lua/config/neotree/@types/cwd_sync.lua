---@meta
---@module 'config.neotree.@types.cwd_sync'
---@brief CWD synchronization state management
---@description
--- Tracks state for automatic CWD synchronization with Neo-tree root.
--- Handles debouncing, user navigation detection, and pause logic.

---@class Cfg.NeoTree.CwdSyncState
---@field timer uv.uv_timer_t|nil Debounce timer handle
---@field pending boolean Sync operation pending
---@field last_dir? string Last synchronized directory
---@field last_file? string Last processed file path
---@field user_navigated boolean User explicitly navigated (pause sync)
---@field last_user_action integer Timestamp of last user action
---@field pause_until integer Timestamp until sync is paused
---@field sync_scheduled boolean Sync already scheduled flag

return {}
