---@module 'custom.dir_picker.types'
---@brief Type definitions for the dir_picker module.

---@alias DirPickerEngine
---| '"telescope"'  # Use Telescope find_files
---| '"fzf"'        # Use fzf-lua files

---@alias DirPickerDepthArg
--- Accepted values for the depth/location argument.
---| integer         # Directory levels above CWD (0 = CWD itself)
---| '"cwd"'         # Alias: current working directory
---| '"root"'        # Alias: filesystem root (upward walk)
---| '"home"'        # Alias: user home directory ($HOME)
---| '"git"'         # Alias: nearest ancestor containing .git
---| '"path=<dir>"'  # Explicit path; expanded, normalized, ~ and $VAR supported

---@alias DirPickerPathArg
--- A raw string of the form `path=<value>` where <value> is any absolute or
--- relative path. Tilde (~) and environment variables ($VAR, %VAR%) are expanded.
--- Examples:
---   path=/srv/www
---   path=~/projects
---   path=c:\tools
---   path=%USERPROFILE%\dev

---@class DirPickerConfig
---@field default_engine  DirPickerEngine                       Default picker engine
---@field fallback_engine DirPickerEngine                       Fallback if default unavailable
---@field depth_aliases?   table<string, fun(): string>          Named depth resolvers

return {}
