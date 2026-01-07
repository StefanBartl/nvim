---@module '@types.neotree.custom'
---@brief Structural type definitions for Neo-tree integration
---@description
--- Provides local EmmyLua type definitions for Neo-tree state objects.
--- These types are intentionally structural to remain robust against
--- Neo-tree internal refactors.

---@class Cfg.NeoTree.Window
---@field position '"left"|"right"|"float"|"current"'

---@class Cfg.NeoTree.Node
---@field id string
---@field name string
---@field path string
---@field type '"file"'|'"directory"'
---@field parent Cfg.NeoTree.Node|nil
---@field children Cfg.NeoTree.Node[]|nil
---@field extra table|nil
---@field is_expanded boolean|nil       -- optional, whether a directory node is expanded
---@field has_children boolean|nil      -- optional, whether node has children

---@class Cfg.NeoTree.Tree
---@field get_node fun(self: Cfg.NeoTree.Tree, id?  : string): Cfg.NeoTree.Node|nil
---@field root Cfg.NeoTree.Node|nil
---@field set_selection fun(self: Cfg.NeoTree.Tree, node_path: string) | nil
---@field children Cfg.NeoTree.Node[] | nil

---@class Cfg.NeoTree.State
---@field name string                     # Source name (filesystem, buffers, git_status)
---@field path string                     # Current root path
---@field tree Cfg.NeoTree.Tree|nil       # Tree abstraction
---@field clipboard table<string, any>|nil    -- optional clipboard field
---@field explicitly_marked_node_ids table<string, boolean>|nil  -- optional marked nodes
---@field current_node Cfg.NeoTree.Node|nil    # Currently focused node
---@field config table                    # Source configuration
---@field commands table<string, function>
---@field ui table|nil
---@field source string|nil            # Optional alias for name
---@field source_name string|nil       # Optional alias for name
---@field window Cfg.NeoTree.Window|nil

return {}
