---@meta
---@module 'custom.filecycle.@types'

---@class FileCycle.Config
---@field open_target? "current"|"split"|"vsplit"|"tab"|"background"  -- how to open the target
---@field keep_focus? boolean         -- when split/vsplit, return focus to original window
---@field include_hidden? boolean
---@field wrap? boolean
---@field follow_symlinks? boolean
---@field root? "buffer_dir"|"cwd"
---@field confirm_on_modified? boolean
---@field case_insensitive? boolean

---@class FileCycle.State
---@field opts FileCycle.Config

return {}
