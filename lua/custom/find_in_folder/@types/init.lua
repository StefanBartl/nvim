---@meta
---@module 'custom.find_in_folder.types'

---@alias FindInFolder.Picker
---| "telescope"
---| "fzf"

---@class FindInFolder.Opts
---@field folder? string
---@field picker? FindInFolder.Picker
---@field keymaps? boolean
---@field usercmds? boolean

---@class FindInFolder.State
---@field last_folder string|nil
---@field last_picker FindInFolder.Picker|nil

return {}