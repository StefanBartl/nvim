---@module 'usrcmds.reload.@types'

---@class UsrCmds.Reload.Opts
---@field deep? boolean Reload all submodules (e.g., testmodul.* when reloading testmodul)
---@field reverse? boolean Reload parent modules (e.g., testmodul when reloading testmodul.keymaps)
---@field pattern? string|nil Reload all modules matching pattern
---@field notify? boolean Show notifications (default: true)
---@field force? boolean Force reload even if module not in package.loaded

---@class UsrCmds.Reload.Result
---@field success boolean
---@field reloaded string[] List of reloaded modules
---@field failed table<string,string> Map of module -> error message
---@field skipped string[] Modules that were skipped

return {}
