---@module 'config.menu.types'

---@class menu_neotree_module
---@field DEFAULT_ICON string
---@field build fun(): table
---@field load fun(): table

---@class custom_neotree_entry
---@field key string
---@field enabled boolean
---@field label string|nil
---@field icon string|nil
---@field rtxt string|nil
---@field hl string|nil
---@field note string|nil
