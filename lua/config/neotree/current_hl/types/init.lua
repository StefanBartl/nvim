---@module 'config.neotree.current_hl.types'

---@class NeoTreeCurrentHLColors
---@field file string|table  -- "#rrggbb", "link:Group", "red", or { fg="#rrggbb", bold=true, ... }
---@field parent string|table

---@class NeoTreeCurrentHLConfig
---@field file_hl string
---@field dir_hl string
---@field debounce integer
---@field use_git_status_colors boolean
---@field enable boolean
---@field colors NeoTreeCurrentHLColors|nil

---@class NeoTreeCurrentHLState
---@field current_file string|nil
---@field current_parent string|nil
---@field timer uv.uv_timer_t|nil
