---@meta
---@module '@types.types'

---@class EnableConfig
---@field usercmds? TriBool  -- Enable/disable user commands, nil = no change
---@field keymaps?  TriBool  -- Enable/disable keymaps, nil = no change
---@field autocommands? TriBool -- Enable/disable autocommands, nil = no change


--- Minimal TSNode shape for EmmyLua/LuaLS diagnostics.
---@class TSNode
---@field type fun(self: TSNode): string
---@field parent fun(self: TSNode): TSNode|nil

