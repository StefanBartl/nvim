---@meta
---@module 'config.neotree.@types.state'

local Cfg = {}

---@class Cfg.NeoTree.State
---@field name string                     # Source name (filesystem, buffers, git_status)
---@field path string                     # Current root path
---@field parent Cfg.NeoTree.Node|nil
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
---@field is_expanded boolean|nil       -- optional, whether a directory node is expanded
---@field has_children boolean|nil      -- optional, whether node has children

return Cfg
