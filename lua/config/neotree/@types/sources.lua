---@meta
---@module 'config.neotree.@types.sources'
---@brief Icon and source selector display configuration
---@description
--- Types for dynamic icon selection and source tab display.
--- Supports multiple icon families and responsive name formatting.

---@class Cfg.NeoTree.Sources.Icon
---@field icon string           -- Icon glyph used for display (may be empty in text/common mode)
---@field long string           -- Long, descriptive display name (used in wide layouts)
---@field short string          -- Short display name (used in narrow layouts)

---@class Cfg.NeoTree.Sources.IconVariant
---@field filesystem Cfg.NeoTree.Sources.Icon        -- Icon definition for filesystem source
---@field buffers Cfg.NeoTree.Sources.Icon           -- Icon definition for buffers source
---@field git_status Cfg.NeoTree.Sources.Icon        -- Icon definition for git status source
---@field document_symbols Cfg.NeoTree.Sources.Icon  -- Icon definition for document symbols source
---@field netman Cfg.NeoTree.Sources.Icon             -- Icon definition for netman (remote) source
---@field tests Cfg.NeoTree.Sources.Icon              -- Icon definition for test-related source
---@field diagnostics Cfg.NeoTree.Sources.Icon        -- Icon definition for diagnostics source

---@class Cfg.NeoTree.Sources.IconSet
---@field v1 Cfg.NeoTree.Sources.IconVariant          -- First icon variant set (legacy / compact)
---@field v2 Cfg.NeoTree.Sources.IconVariant          -- Second icon variant set (extended / modern)

---@class Cfg.NeoTree.Sources.DynamicConfig
---@field icon_family Cfg.NeoTree.IconFamily          -- Selected icon family (e.g. nerd, ascii, text)
---@field icon_variant Cfg.NeoTree.IconVariant        -- Active icon variant version (v1 or v2)
---@field width_threshold integer                     -- Minimum window width required to use long names
---@field has_netman boolean                          -- Whether the netman source is available/registered
---@field has_tests boolean                           -- Whether the tests source is available/registered
---@field has_diagnostics boolean                     -- Whether the diagnostics source is available/registered

---@class Cfg.NeoTree.Sources.SourceDef
---@field name string                                 -- Canonical source name (e.g. "filesystem", "buffers")
---@field loader fun(): table                         -- Lazy loader function returning the source module
---@field loaded boolean                              -- Indicates whether the source has already been loaded
---@field config table|nil                            -- Optional per-source configuration table
---@field source table|nil                            -- Loaded source module (set after successful loader execution)

return {}
