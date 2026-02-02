---@meta
---@module 'config.neotree.@types.config'
---@brief Configuration structures for Neo-tree setup
---@description
--- Types for the main `setup()` function and module-level configuration.
--- Used by `config.neotree.init` to configure all sub-modules.

---@class Cfg.NeoTree.InitOpts
---@field debug? boolean Global debug flag for all modules
---@field default_position? Cfg.NeoTree.Position Default window position
---@field restore_last_position? boolean Restore tree state instead of revealing current file
---@field reveal_current_file? boolean Only has an effect if window_open == false
---@field only_lhs? boolean Only has an effect if window_open == false
---@field trash? Cfg.NeoTree.Trash.Config|boolean Trash system configuration
---@field current_hl? Cfg.NeoTree.CurrentHl.Config|boolean Current file highlighting
---@field cwd_sync? Cfg.NeoTree.CwdSync.Config|boolean CWD synchronization

---@class Cfg.NeoTree.CurrentHl.Config
---@field enable? boolean Enable current file highlighting (default: true)
---@field file_hl? string Highlight group for current file
---@field dir_hl? string Highlight group for parent directory
---@field debounce? integer Debounce time in ms (default: 50)
---@field use_git_status_colors? boolean Use git status colors (default: true)
---@field colors? table<string, string|table> Custom color overrides

---@class Cfg.NeoTree.CwdSync.Config
---@field enabled? boolean Enable CWD synchronization (default: false)
---@field debug? boolean
---@field debounce_ms? integer Debounce time in milliseconds (default: 150)
---@field keep_focus? boolean Keep focus in current window after sync (default: true)
---@field also_set_nvim_cwd? boolean Also set global :pwd (default: false)
---@field open_if_closed? boolean Auto-open neo-tree if closed (default: false)
---@field use_project_root? boolean Use project root instead of buffer dir (default: true)
---@field project_root_fallback_to_bufdir? boolean Fallback to buffer dir if no root (default: true)
---@field force_position_left? boolean Always open at left position (default: true)

---@class Cfg.NeoTree.SetupModule
---@field setup fun(opts?: Cfg.NeoTree.InitOpts): nil
---@field options Cfg.NeoTree.InitOpts
---@field get_default_position fun(): Cfg.NeoTree.Position
---@field busy_guard fun(): boolean

return {}
