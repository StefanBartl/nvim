---@meta
---@module 'config.neotree.@types.node'
---@brief Neo-tree node structure definition
---@description
--- Represents a single entry (file, directory, virtual) within a Neo-tree source.
--- This is the core data structure for tree navigation and manipulation.

---@class Cfg.NeoTree.Node
---@field id string Unique node identifier (usually absolute path)
---@field path string|nil Filesystem path if applicable
---@field name string Display name of the node
---@field type Cfg.NeoTree.NodeType Node classification
---@field parent_id string|nil ID of the parent node (nil for root)
---@field level integer Tree depth (root = 0)
---@field loaded boolean Whether children have been loaded
---@field is_expanded boolean|nil Directory expansion state
---@field has_children boolean|nil Whether node has child entries
---@field children Cfg.NeoTree.Node[]|nil Child nodes if loaded
---@field extra table|nil Source-specific metadata
---@field tree Cfg.NeoTree.Tree Reference to containing tree
---@field explicitly_marked_node_ids table<string, boolean>|nil Marked nodes for batch operations
---@field is_directory boolean
---@field get_parent_id boolean

-- ---Return the parent node ID for upward navigation
-- ---@param self Cfg.NeoTree.Node
-- ---@return string|nil parent_id
-- local function get_parent_id(self) end

-- ---Check if node represents a directory
-- ---@param self Cfg.NeoTree.Node
-- ---@return boolean
-- local function is_directory(self) end

-- ---Check if node represents a file
-- ---@param self Cfg.NeoTree.Node
-- ---@return boolean
-- local function is_file(self) end

-- ---Return filesystem-safe absolute path if available
-- ---@param self Cfg.NeoTree.Node
-- ---@return string|nil path
-- local function get_path(self) end

-- ---Return display label used by UI
-- ---@param self Cfg.NeoTree.Node
-- ---@return string name
-- local function get_name(self) end

return {}
