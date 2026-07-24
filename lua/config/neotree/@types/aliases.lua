---@meta
---@module 'config.neotree.@types.aliases'
---@brief Central type aliases used across Neo-tree configuration
---@description
--- Defines common type aliases to avoid repetition and ensure consistency.
--- String literal unions are extracted here for reusability.

-- ===========================
-- Actions
-- ===========================

---@alias Cfg.NeoTree.Actions.PickerType "telescope"|"fzf"|"auto"

-- ===========================
-- Position & Window
-- ===========================

---@alias Cfg.NeoTree.Position "top"|"bottom"|"left"|"right"|"current"|"float"
--- Window position for Neo-tree panels

---@alias Cfg.NeoTree.Backend "explorer"|"wslview"|"auto"
--- File manager backend selection for WSL integration

-- ===========================
-- Node Types
-- ===========================

---@alias Cfg.NeoTree.NodeType "file"|"directory"|"virtual"
--- Type classification for tree nodes

-- ===========================
-- Operations
-- ===========================

---@alias Cfg.NeoTree.FileOperation "delete"|"move"|"overwrite"
--- File system operation types tracked by safety system

---@alias Cfg.NeoTree.DeleteMode "all"|"individual"
--- Batch deletion mode: all at once or one-by-one confirmation

-- ===========================
-- Icon & Display
-- ===========================

---@alias Cfg.NeoTree.IconFamily "common"|"nerd"|"codicons"
--- Icon set variant for source selector display

---@alias Cfg.NeoTree.IconVariant "v1"|"v2"
--- Icon version variant

---@alias Cfg.NeoTree.NameLength "long"|"short"
--- Display name length preference

---@alias Cfg.NeoTree.OutputFormat "list"|"quoted"|"json"
--- Path copy output formatting

-- ===========================
-- Sources
-- ===========================

---@alias Cfg.NeoTree.SourceName "filesystem"|"buffers"|"git_status"|"document_symbols"|"diagnostics"|"tests"|"netman.ui.neo-tree"
--- Valid Neo-tree source identifiers

---@alias Cfg.NeoTree.Sources.IconFamily
---| '"common"'
---| '"nerd"'
---| '"codicons"'

---@alias Cfg.NeoTree.Sources.IconVariantKey
---| '"v1"'
---| '"v2"'

---@alias Cfg.NeoTree.Sources.IconLength
---| '"long"'
---| '"short"'

return {}
