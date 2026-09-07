---@module 'config.neotree.@types.utils'

---@class Cfg.NeoTree.Utils
---@field init Cfg.NeoTree.Utils.Module
---@field node Cfg.NeoTree.Utils.Node

--- Unified utilities for Neo-tree configuration.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Module
---@field safe_hide_preview fun(): boolean

--- Utility functions for working with Neo-tree nodes.
--- This class is used purely for type annotations and does not represent an instantiable object.
---@class Cfg.NeoTree.Utils.Node
---@field get_current fun(state: Cfg.NeoTree.State): Cfg.NeoTree.Node|nil
---@field get_path fun(node: Cfg.NeoTree.Node|nil): (string, boolean)
---@field collect_nodes fun(state: Cfg.NeoTree.State): Cfg.NeoTree.Node[]
---@field extract_paths fun(nodes: table[]): (string[], string[])
---@field get_line_number fun(bufnr: integer, node_id: integer|string): integer|nil

return {}
