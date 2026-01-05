---@meta
---@module 'debugging.types'
require("debugging.views.@types")

---@class Dbg.Autocmds.Modules
---@field all? boolean
---@field list_autocmds? boolean

---@class Dbg.Markdown.Modules
---@field all? boolean
---@field inline_debug_fixed? boolean

---@class Dbg.NvimOpts.Modules
---@field all? boolean
---@field indent_helpers boolean

---@class Dbg.Terminals.Modules
---@field all? boolean
---@field keylogger? boolean

---@class Dbg.Tools.Modules
---@field all? boolean
---@field buffer_inspector? boolean
---@field cursor_state? boolean
---@field vardump? boolean

---@class Dbg.Usercmds.Modules
---@field all? boolean
---@field neotree? boolean
---@field reports? boolean

---@class Dbg.Views.Modules
---@field keymaps boolean
---@field autocmds boolean
---@field timings boolean
---@field capture boolean

---@class Dbg.Setup
---@field all? boolean
---@field autocmds? Dbg.Autocmds.Modules|nil
---@field markdown? Dbg.Markdown.Modules|nil
---@field terminals? Dbg.Terminals.Modules|nil
---@field views? Dbg.Views.Modules|nil
---@field usercmds? boolean|nil
---@field tools? Dbg.Tools.Modules|nil
---@field nvim_options? Dbg.NvimOpts.Modules|nil

return {}
