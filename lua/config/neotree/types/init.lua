---@meta
---@module 'config.neotree.types'

-- === open ===

---@class Cfg.NeoTree.Cfg
---@field extra_lhs table<string,string[]>|nil  -- zusätzliche LHS je Hauptbinding, z. B. { ["<A-c>"] = {"¢"} }

-- == cwd_sync ==

---@class Cfg.NeoTree.CwdSyncState
---@field timer uv.uv_timer_t|nil
---@field pending boolean
---@field last_dir string|nil

-- == trash ==

---@class Cfg.NeoTree.Trash
---@field send_to_trash fun(path:string): (boolean, string) send path to system trash, returns ok,message
---@field neotree_send_node_to_trash fun(state:table): nil neo-tree mapping callback to trash node and refresh view

return {}
