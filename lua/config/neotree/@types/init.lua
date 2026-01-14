---@meta
---@module 'config.neotree.@types'

-- ===========================
-- open.window

---@alias Cfg.NeoTree.Open.Win.AliasList string[]
-- List of alternative key strings that should be registered
-- as aliases for a primary lhs mapping.

---@class Cfg.NeoTree.Open.Win.xlhs
---@field extra_lhs table<string, Cfg.NeoTree.Open.Win.AliasList>|nil
-- Mapping of key combinations (e.g. "<A-c>") to a list of
-- alternative lhs strings. Each list is an array to allow
-- future extension without reallocations.

-- ===========================
-- open.filemanager

---@class Cfg.NeoTree.Wsl.FM
---@field _cfg Cfg.NeoTree.Wsl.OpenConfig
---@field setup any
---@field open any
---@field nodes table<string, Cfg.NeoTree.Node>
---@field get_node fun(self: Cfg.NeoTree.Tree, id: string): Cfg.NeoTree.Node|nil

---@class Cfg.NeoTree.Wsl.OpenConfig
---@field backend "explorer"|"wslview"|"auto" # which launcher to use (default: "explorer")
---@field silent boolean                      # reduce notifications (default: true)

---@alias UnixPath string
---@alias WinPath string

---@class Cfg.NeoTree.Tree
---@field get_node fun(self: Cfg.NeoTree.Tree, id?  : string): Cfg.NeoTree.Node|nil
---@field get_nodes fun(self: Cfg.NeoTree.Tree, id?  : string): Cfg.NeoTree.Node[]|nil
---@field root Cfg.NeoTree.Node|nil
---@field set_selection fun(self: Cfg.NeoTree.Tree, node_path: string) | nil
---@field children Cfg.NeoTree.Node[] | nil

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

-- ===========================
-- safety

---@class Cfg.NeoTree.Safety.RecoveryPoint
---@field timestamp number
---@field operation string
---@field state table Serializable state snapshot
---@field paths string[]

-- ===========================
-- trash

---@class Cfg.NeoTree.Trash.Config
---@field use_safety_system? boolean Enable full safety features (default: true)
---@field create_backups? boolean Create backups before deletion (default: true)
---@field confirm_dangerous?boolean Confirm dangerous operations (default: true)
---@field use_dry_run? boolean Respect dry-run mode (default: true)
---@field auto_close_buffers? boolean Auto-close open buffers without asking (default: false)
---@field debug? boolean

---@alias Cfg.NeoTree.Trash.Operations.DeleteMode "all"|"individual"

-- ===========================
-- actions

---@class Cfg.NeoTree.Copy.ClipboardOpt
---@field relative_to_cwd? boolean Convert paths to relative (default: false)
---@field preview_limit? integer Max entries to show in notification (default: 10)
---@field quote_paths? boolean Wrap paths in quotes (default: false)
---@field format? "list"|"quoted"|"json" Output format (default: "list")

---@class Cfg.NeoTree.Actions.PathToRequireOpts
---@field relative? boolean Use relative paths (default: false)
---@field show_preview? boolean Show preview notification (default: true)

---@class Cfg.NeoTree.Actions.NodeInfoState
---@field active_win integer|nil Current hover window
---@field active_path string|nil Currently displayed path

return {}
