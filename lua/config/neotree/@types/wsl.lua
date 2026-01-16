---@meta
---@module 'config.neotree.@types.wsl'
---@brief WSL file manager integration types
---@description
--- Types for opening files/directories in Windows Explorer from WSL.
--- Handles path conversion and backend selection.

---@alias UnixPath string
--- Unix-style path (forward slashes)

---@alias WinPath string
--- Windows-style path (backslashes, drive letters)

---@class Cfg.NeoTree.Wsl.OpenConfig
---@field backend Cfg.NeoTree.Backend Which launcher to use (default: "explorer")
---@field silent boolean Reduce notifications (default: true)

---@class Cfg.NeoTree.Wsl.FileManager
---@field _cfg Cfg.NeoTree.Wsl.OpenConfig Internal configuration
---@field setup fun(opts?: Cfg.NeoTree.Wsl.OpenConfig): nil
---@field open fun(path: string): boolean, string|nil
---@field nodes table<string, Cfg.NeoTree.Node> Node cache
---@field get_node fun(self: Cfg.NeoTree.Wsl.FileManager, id: string): Cfg.NeoTree.Node|nil

return {}
