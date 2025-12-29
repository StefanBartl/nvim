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
---@field keymaps? boolean register keymaps or not
---@field usercommands? boolean register usercommands or nt

---@class FileCycle.State
---@field opts? FileCycle.Config
---@field setup? fun(user_opts: FileCycle.Config|nil)): nil
---@field open? fun(mode: string, opts: FileCycle.Config): boolean
---@field navigate? fun(dir: FilePath, mode: "next"|"prev", opts: FileCycle.Config): boolean
---@field get_root_dir? fun(opts: FileCycle.Config): FilePath|nil, string|nil

return {}
