---@meta
---@module 'config.neotree.actions.open_system_app.types'
---@brief Type definitions for the system-default opener action.

---@alias OpenSysApp.OpenCmd
---| '"xdg-open"'  # Linux (freedesktop)
---| '"open"'      # macOS
---| '"cmd.exe"'   # Windows

---@class OpenSysApp.Config
---@field filetypes table<string, true>  Set of lowercase extensions (no dot) that trigger the system opener.
---@field notify_on_open boolean         Show a notification when a file is handed off to the system.
---@field notify_on_error boolean        Show a notification when the OS opener fails.

---@class OpenSysApp.Opts
---@field filetypes? string[]            Extension list to replace the defaults (e.g. {"pdf","png"}).
---@field extra_filetypes? string[]      Extensions to add on top of the defaults.
---@field notify_on_open? boolean
---@field notify_on_error? boolean

---@class OpenSysApp.Module
---@field DEFAULT_FILETYPES string[]
---@field setup fun(opts?: OpenSysApp.Opts): nil
---@field attach fun(opts: table): nil
---@field open fun(path: string): nil
---@field is_handled fun(path: string): boolean
---@field get_config fun(): OpenSysApp.Config

return {}
