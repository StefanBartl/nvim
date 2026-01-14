---@meta
---@module 'config.neotree.@types.config'

---@class Cfg.NeoTree.InitOpts
---@field trash Cfg.NeoTree.Trash.Config|boolean|nil
---@field window_debug boolean|nil
---@field current_hl Cfg.NeoTree.CurrentHl.Config|boolean|nil
---@field cwd_sync Cfg.NeoTree.CwdSync.Config|boolean|nil
---@field debug boolean|nil

---@class Cfg.NeoTree.CurrentHl.Config
---@field colors table<string, string|table>

---@class Cfg.NeoTree.CwdSync.Config
---@field debounce_ms integer|nil
---@field keep_focus boolean|nil
---@field also_set_nvim_cwd boolean|nil
---@field open_if_closed boolean|nil
---@field use_project_root boolean|nil
---@field project_root_fallback_to_bufdir boolean|nil
---@field force_position_left boolean|nil

return {}
