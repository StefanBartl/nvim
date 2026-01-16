---@meta
---@module 'config.neotree.@types.sources'
---@brief Icon and source selector display configuration
---@description
--- Types for dynamic icon selection and source tab display.
--- Supports multiple icon families and responsive name formatting.

---@class Cfg.NeoTree.Sources.Icon
---@field icon string Icon glyph (can be empty for common/text mode)
---@field long string Long display name
---@field short string Short display name

---@class Cfg.NeoTree.Sources.IconVariant
---@field filesystem Cfg.NeoTree.Sources.Icon
---@field buffers Cfg.NeoTree.Sources.Icon
---@field git_status Cfg.NeoTree.Sources.Icon
---@field document_symbols Cfg.NeoTree.Sources.Icon
---@field netman Cfg.NeoTree.Sources.Icon
---@field tests Cfg.NeoTree.Sources.Icon
---@field diagnostics Cfg.NeoTree.Sources.Icon

---@class Cfg.NeoTree.Sources.IconSet
---@field v1 Cfg.NeoTree.Sources.IconVariant
---@field v2 Cfg.NeoTree.Sources.IconVariant

---@class Cfg.NeoTree.Sources.DynamicConfig
---@field icon_family Cfg.NeoTree.IconFamily Icon set selection
---@field icon_variant Cfg.NeoTree.IconVariant Icon version
---@field width_threshold integer Minimum width for long names
---@field has_netman boolean Netman source available
---@field has_tests boolean Test source available
---@field has_diagnostics boolean Diagnostics source available

return {}
