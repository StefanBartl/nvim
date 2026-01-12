---@meta
---@module 'config.neotree.@types.node'

-- =========================================================
-- Neo-tree Node
--
-- Repräsentiert einen Eintrag (Datei, Verzeichnis, virtuell)
-- innerhalb eines Neo-tree-Sources. Auf dieser Struktur
-- werden Methoden wie get_parent_id() aufgerufen.
-- =========================================================

local Cfg = {}

---@class Cfg.NeoTree.Window
---@field position '"left"|"right"|"float"|"current"'

---@class Cfg.NeoTree.Node
---@field id string                         -- Unique node identifier (usually absolute path)
---@field get_id string                     -- get unique node identifier (usually absolute path)
---@field path string|nil                   -- Filesystem path if applicable
---@field name string                       -- Display name of the node
---@field type '"file"'|'"directory"'|'"virtual"' -- Node kind
---@field parent_id string|nil              -- ID of the parent node (nil for root)
---@field level integer                     -- Tree depth (root = 0)
---@field loaded boolean                    -- Children loaded flag
---@field is_expanded boolean                  -- Directory expanded flag
---@field children Cfg.NeoTree.Node[]|nil             -- Child node ids (if loaded)
---@field has_children boolean
---@field extra table|nil                   -- Source-specific metadata
---@field tree Cfg.NeoTree.Tree
---@field explicitly_marked_node_ids table<string, boolean>|nil
---@field is_directory boolean
---@field get_parent_id boolean

---Return the parent node id.
---This is commonly used to navigate upwards in the tree.
---@return string|nil
function Cfg.NeoTree.Node:get_parent_id() end

---Return whether the node represents a directory.
---@return boolean
function Cfg.NeoTree.Node:is_directory() end

---Return whether the node represents a file.
---@return boolean
function Cfg.NeoTree.Node:is_file() end

---Return a filesystem-safe absolute path, if available.
---@return string|nil
function Cfg.NeoTree.Node:get_path() end

---Return the display label used by the UI.
---@return string
function Cfg.NeoTree.Node:get_name() end

return Cfg
