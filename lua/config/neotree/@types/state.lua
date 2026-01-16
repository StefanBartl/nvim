---@meta
---@module 'config.neotree.@types.state'
---@brief Neo-tree state management types
---@description
--- Core state structure that Neo-tree passes to commands and event handlers.
--- Represents the current view state of a Neo-tree window/source.

---@class Cfg.NeoTree.Window
---@field position? Cfg.NeoTree.Position|nil Window placement
---@field open? boolean If neotree window is open
---@field source? string|nil Active source name

---@class Cfg.NeoTree.Tree
---@field get_node? fun(self: Cfg.NeoTree.Tree, id?: string): Cfg.NeoTree.Node|nil
---@field get_nodes? fun(self: Cfg.NeoTree.Tree, id?: string): Cfg.NeoTree.Node[]|nil
---@field set_selection? fun(self: Cfg.NeoTree.Tree, node_path: string)|nil
---@field root? Cfg.NeoTree.Node|nil Root node of the tree
---@field children? Cfg.NeoTree.Node[]|nil Direct children of root
---@field node_id? string|nil
---@field expanded? table<string, boolean>

---@class Cfg.NeoTree.State
---@field name Cfg.NeoTree.SourceName Source identifier
---@field path string Current root path being displayed
---@field tree Cfg.NeoTree.Tree|nil Tree data structure
---@field clipboard table<string, any>|nil Cut/copy clipboard
---@field explicitly_marked_node_ids table<string, boolean>|nil Nodes marked for batch ops
---@field current_node Cfg.NeoTree.Node|nil Currently focused node
---@field config table Source-specific configuration
---@field commands table<string, function> Available commands for this source
---@field window Cfg.NeoTree.Window|nil Window configuration
---@field ui table|nil UI-specific metadata
---@field source string|nil Alias for name (backward compat)
---@field source_name string|nil Alias for name (backward compat)
---@field parent Cfg.NeoTree.Node|nil Parent context for nested views
---@field is_expanded boolean|nil Current expansion state
---@field has_children boolean|nil Whether current context has children

return {}
