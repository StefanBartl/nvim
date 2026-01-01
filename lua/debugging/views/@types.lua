---@meta
---@module 'debugging.views.@types'

---@class DebugViews.CaptureOpts
---@field debug boolean|nil
---@field clipboard boolean|nil
---@field save_file boolean|nil
---@field output_dir string|nil

---@class DebugViews.DisplayOpts
---@field tag string
---@field cmd string
---@field attempts integer|nil
---@field retry_delay_ms integer|nil
---@field auto_bottom boolean|nil

---@class DebugViews.WindowRegistry
---@field messages integer|nil
---@field noice_all integer|nil
---@field noice_errors integer|nil

---@class DebugViews.Keymaps
---@field enable boolean
---@field map fun(mode:string,lhs:string,rhs:fun(),opts:table)
---@field prefix string  # z.B. "<leader>d"

---@class DebugViews.Autocmds
---@field enable boolean
---@field group_name string
---@field auto_refresh boolean

---@class DebugViews.Timings
---@field delay_messages_ms integer
---@field delay_noice_ms integer
---@field retry_delay_ms integer
---@field attempts integer

---@class DebugViews.Setup
---@field keymaps DebugViews.Keymaps|nil
---@field autocmds DebugViews.Autocmds|nil
---@field timings DebugViews.Timings|nil
---@field capture DebugViews.CaptureOpts|nil

return {}

