---@meta
---@module 'mappings.dbg_messages.@types'

---@alias DbgMsgs.Win integer
---@alias DbgMsgs.Buf integer

---@class DbgMsgs.WindowRegistry
---@field messages integer|nil
---@field noice_all integer|nil
---@field noice_errors integer|nil

---@class DbgMsgs.Keymaps
---@field enable boolean
---@field map fun(mode:string,lhs:string,rhs:fun(),opts:table)

---@class DbgMsgs.Autocmds
---@field enable boolean
---@field group_name string

---@class DbgMsgs.Timings
---@field delay_messages_ms integer
---@field delay_noice_ms integer
---@field retry_delay_ms integer
---@field attempts integer

---@class DbgMsgs.Setup
---@field keymaps DbgMsgs.Keymaps|nil
---@field autocmds DbgMsgs.Autocmds|nil
---@field timings DbgMsgs.Timings|nil

return {}
