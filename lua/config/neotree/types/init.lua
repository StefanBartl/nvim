---@meta
---@module 'config.neotree.types'

---@class NeoTreeCwdSyncConfig
---@field debounce_ms integer                -- Debounce window for bursts of BufEnter/WinEnter/TabEnter
---@field keep_focus boolean                 -- After syncing, restore focus to the previously active window
---@field also_set_nvim_cwd boolean          -- Optionally keep :pwd in lockstep with Neo-tree's root
---@field open_if_closed boolean             -- If no Neo-tree window exists in the current tab, open one
---@field use_project_root boolean           -- Prefer project root (e.g., via repo root) over buffer directory
---@field project_root_fallback_to_bufdir boolean -- Fallback to buffer directory if no project root found
---@field force_position_left boolean        -- If a filesystem view exists in this tab but isn't "left", normalize it to "left"

---@class NeoTreeCwdSyncState
---@field timer uv.uv_timer_t|nil
---@field pending boolean
---@field last_dir string|nil

---@class NeoTreeTrash
---@field send_to_trash fun(path:string): (boolean, string) send path to system trash, returns ok,message
---@field neotree_send_node_to_trash fun(state:table): nil neo-tree mapping callback to trash node and refresh view

