---@module 'usrcmds.newfile.types'

---@class NewFileOpts
---@field recursive boolean       -- create parent directories
---@field overwrite boolean       -- force overwrite if file exists
---@field write_now boolean       -- write immediately after opening/renaming

---@class NewFileAPI
---@field ensure_parent fun(path: Path, recursive: boolean): boolean
---@field edit_new fun(path: Path, opts?: NewFileOpts): nil
---@field save_as fun(path: Path, opts?: NewFileOpts): nil
---@field write_to fun(path: Path, opts?: NewFileOpts): nil

