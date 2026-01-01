---@meta
---@module 'config.neotree.@types'

---@class Cfg.NeoTree.Wsl.FM
---@field _cfg Cfg.NeoTree.Wsl.OpenConfig
---@field setup any
---@field open any

---@class Cfg.NeoTree.Wsl.OpenConfig
---@field backend "explorer"|"wslview"|"auto" # which launcher to use (default: "explorer")
---@field silent boolean                      # reduce notifications (default: true)

---@alias UnixPath string
---@alias WinPath string

-- reveal_manager
---@class Cfg.NeoTree.RevealContext
---@field buf integer
---@field file string
---@field dir string
---@field position NeoTreePosition|nil

return {}
