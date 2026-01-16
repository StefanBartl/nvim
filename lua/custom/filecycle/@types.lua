---@meta
---@module 'custom.filecycle.@types'

---@class FileCycle.Config
---@field open_target? "replace"|"current"|"split"|"vsplit"|"tab"|"background"  -- how to open the target
---  - "replace": replace current buffer content (default for <leader>nf/pf)
---  - "current": open in new buffer, keep old buffer, focus new (stay mode: <leader>nfn/pfn)
---  - "split": open in horizontal split
---  - "vsplit": open in vertical split
---  - "tab": open in new tab
---  - "background": load buffer without focus
---@field keep_focus? boolean         -- when split/vsplit, return focus to original window
---@field include_hidden? boolean
---@field wrap? boolean
---@field follow_symlinks? boolean
---@field root? "buffer_dir"|"cwd"
---@field confirm_on_modified? boolean
---@field case_insensitive? boolean
---@field keymaps? boolean register keymaps or not
---@field usercommands? boolean register usercommands or not

---@class FileCycle.State
---@field opts? FileCycle.Config
---@field setup? fun(user_opts: FileCycle.Config|nil): nil
---@field open? fun(mode: string, opts: FileCycle.Config, count: integer?): boolean
---@field navigate? fun(dir: FilePath, mode: "next"|"prev", opts: FileCycle.Config, count: integer?): boolean
---@field get_root_dir? fun(opts: FileCycle.Config): FilePath|nil, string|nil

---@alias FileCycle.Direction "next"|"prev"

return {}
