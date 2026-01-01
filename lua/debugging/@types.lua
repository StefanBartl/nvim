---@meta
---@module 'debugging.types'
require("debugging.views.@types")

---@class autocmds_modules
---@field list_autocmds boolean

---@class markdown_modules
---@field inline_debug_fixed boolean

---@class terminals_modules
---@field keylogger boolean

---@class debugging_setup
---@field all? boolean
---@field autocmds? autocmds_modules|nil
---@field markdown? markdown_modules|nil
---@field terminals? terminals_modules|nil
---@field views? DebugViews.Setup|nil
---@field usercmds? boolean|nil

return {}
