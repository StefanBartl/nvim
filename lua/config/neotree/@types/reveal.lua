---@meta
---@module 'config.neotree.@types.reveal'
---@brief File reveal and navigation context types
---@description
--- Context information used when revealing files in Neo-tree.
--- Tracks buffer, file path, directory, and target position.

---@class Cfg.NeoTree.RevealContext
---@field buf integer Buffer number being revealed
---@field file string Full file path
---@field dir string Parent directory path
---@field position? Cfg.NeoTree.Position Target window position

return {}
