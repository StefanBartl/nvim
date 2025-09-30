---@meta
---@module 'usrcmds.usr_pickers.types'

---@class UsrPickersKeymaps
---@field tel_files string
---@field tel_grep  string
---@field fzf_files string
---@field fzf_grep  string

---@class UsrPickersCommands
---@field find_files_telescope string
---@field grep_telescope       string
---@field find_files_fzf       string
---@field grep_fzf             string

---@class UsrPickersConfig
---@field keys? UsrPickersKeymaps
---@field commands? UsrPickersCommands
---@field notify_level? integer
