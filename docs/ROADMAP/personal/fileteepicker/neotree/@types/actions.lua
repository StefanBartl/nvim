---@meta
---@module 'config.neotree.@types.actions'
---@brief Type definitions for Neo-tree custom actions
---@description
--- Configuration options for custom command implementations like
--- clipboard operations, path conversions, and node info display.

---@class Cfg.NeoTree.Actions.CopyClipboardOpts
---@field relative_to_cwd? boolean Convert paths to relative (default: false)
---@field preview_limit? integer Max entries to show in notification (default: 10)
---@field quote_paths? boolean Wrap paths in quotes (default: false)
---@field format? Cfg.NeoTree.OutputFormat Output format (default: "list")

---@class Cfg.NeoTree.Actions.PathToRequireOpts
---@field relative? boolean Use relative paths (default: false)
---@field show_preview? boolean Show preview notification (default: true)

---@class Cfg.NeoTree.Actions.NodeInfoState
---@field active_win integer|nil Current hover window handle
---@field active_path string|nil Currently displayed path

---@class Cfg.NeoTree.Actions.AddOptions
---@field insert_clipb? boolean Automatically insert clipboard content (default: false)
---@field ask_insert_clipb? boolean Ask before inserting clipboard content (default: false)

return {}
