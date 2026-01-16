---@meta
---@module 'config.neotree.@types.config'

---@class Cfg.NeoTree.InitOpts
---@field debug? boolean|nil Global debug flag
---@field default_position? Cfg.NeoTree.Position
---@field restore_last_position? boolean|nil Restore tree state instead of revealing current file
---@field window_debug? boolean|nil
---@field trash? Cfg.NeoTree.Trash.Config|boolean|nil
---@field current_hl? Cfg.NeoTree.CurrentHl.Config|boolean|nil
---@field cwd_sync? Cfg.NeoTree.CwdSync.Config|boolean|nil

---@class Cfg.NeoTree.CurrentHl.Config
---@field colors table<string, string|table> Color configuration for file/parent highlighting

---@class Cfg.NeoTree.CwdSync.Config
---@field debounce_ms integer|nil Debounce time in milliseconds (default: 150)
---@field keep_focus boolean|nil Keep focus in current window after sync (default: true)
---@field also_set_nvim_cwd boolean|nil Also set global :pwd (default: false)
---@field open_if_closed boolean|nil Auto-open neo-tree if closed (default: false)
---@field use_project_root boolean|nil Use project root instead of buffer dir (default: true)
---@field project_root_fallback_to_bufdir boolean|nil Fallback to buffer dir if no root (default: true)
---@field force_position_left boolean|nil Always open at left position (default: true)

---@class Cfg.NeoTree.SetupModule
---@field setup fun(opts: Cfg.NeoTree.InitOpts|nil): nil
---@field options Cfg.NeoTree.InitOpts
---@field get_default_position fun(): Cfg.NeoTree.Position|"right"

return {}
