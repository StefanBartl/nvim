---@meta
---@module 'config.neotree.@types.cwd_sync'
---@brief CWD synchronization state management
---@description
--- Tracks state for automatic CWD synchronization with Neo-tree root.
--- Handles debouncing, user navigation detection, and pause logic.

---@class Cfg.NeoTree.CwdSync.State.Timer
---@field close? any # hier fun() FIX:
---@field stop? any # hier fun() FIX:

---@class Cfg.NeoTree.CwdSync.State
---@field timer? Cfg.NeoTree.CwdSync.State.Timer
---@field pending? boolean
---@field last_dir string|nil
---@field last_file string|nil
---@field user_navigated boolean
---@field last_user_action integer
---@field pause_until integer
---@field sync_scheduled boolean

return {}
