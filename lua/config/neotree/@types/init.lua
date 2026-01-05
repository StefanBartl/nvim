---@meta
---@module 'config.neotree.@types'

-- ===========================
-- open_fm

---@class Cfg.NeoTree.Wsl.FM
---@field _cfg Cfg.NeoTree.Wsl.OpenConfig
---@field setup any
---@field open any

---@class Cfg.NeoTree.Wsl.OpenConfig
---@field backend "explorer"|"wslview"|"auto" # which launcher to use (default: "explorer")
---@field silent boolean                      # reduce notifications (default: true)

---@alias UnixPath string
---@alias WinPath string

-- ===========================
-- reveal_manager

---@class Cfg.NeoTree.RevealContext
---@field buf integer
---@field file string
---@field dir string
---@field position Cfg.NeoTree.Position|nil

-- ===========================
-- sources

---@class Cfg.NeoTree.Sources.Icon
---@field icon string        -- Icon glyph (can be empty for common/text mode)
---@field long string        -- Long display name
---@field short string       -- Short display name

---@class Cfg.NeoTree.Sources.IconVariant
---@field filesystem Cfg.NeoTree.Sources.Icon
---@field buffers Cfg.NeoTree.Sources.Icon
---@field git_status Cfg.NeoTree.Sources.Icon
---@field document_symbols Cfg.NeoTree.Sources.Icon
---@field netman Cfg.NeoTree.Sources.Icon
---@field tests Cfg.NeoTree.Sources.Icon

---@class Cfg.NeoTree.Sources.IconSet
---@field v1 Cfg.NeoTree.Sources.IconVariant
---@field v2 Cfg.NeoTree.Sources.IconVariant

---@class Cfg.NeoTree.Sources.DynamicConfig
---@field icon_family '"common"'|'"nerd"'|'"codicons"'
---@field icon_variant '"v1"'|'"v2"'
---@field width_threshold integer
---@field has_netman boolean
---@field has_tests boolean

-- ===========================
-- watcher_quarantine

---@class Cfg.NeoTree.WatcherQuarantine.State
---@field in_quarantine boolean Global quarantine active
---@field quarantine_until number Timestamp when quarantine ends (vim.loop.now())
---@field suspended_paths table<string, number> Per-path quarantine timestamps
---@field error_suppressed boolean EPERM suppression active
---@field original_notify function|nil Backup of original vim.notify

return {}
