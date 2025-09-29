---@meta
---@module 'config.neotree.types'

---@class NeoTreeCwdSyncConfig
---@field debounce_ms integer        # Debounce for event storms (milliseconds)
---@field keep_focus boolean         # Restore previous window after syncing
---@field also_set_nvim_cwd boolean  # Also run :cd to the derived directory
---@field open_if_closed boolean     # Open Neo-tree if no window is open
---@field use_project_root boolean   # Try utils.lv_project_root first
---@field project_root_fallback_to_bufdir boolean # Fallback to buffer dir if project root is nil

---@class NeoTreeCwdSyncState
---@field timer uv.uv_timer_t|nil    # libuv timer handle or nil
---@field pending boolean|nil
---@field last_dir string|nil

