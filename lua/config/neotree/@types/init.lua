---@meta
---@module 'config.neotree.@types'
---@brief Central type definition index for Neo-tree configuration
---@description
--- This module serves as the entry point for all Neo-tree type definitions.
--- Individual type modules are organized by functional domain:
---
--- Core Structures:
---   - aliases:     Common type aliases and string literal unions
---   - node:        Tree node structure and methods
---   - state:       Neo-tree state passed to commands/handlers
---   - config:      Setup and initialization configuration
---
--- Feature Modules:
---   - actions:     Custom command options (copy, convert, info)
---   - trash:       Deletion and trash system configuration
---   - safety:      Backup, recovery, and operation queue
---   - open:        Window management and positioning
---   - reveal:      File reveal and navigation context
---   - cwd_sync:    CWD synchronization state
---   - highlights:  Current file highlighting
---   - watcher:     File system watcher quarantine
---
--- Integration:
---   - sources:     Icon and source selector display
---   - wsl:         WSL file manager integration
---   - project_root: Project root detection interface
---
--- Usage:
---   All type files use the `Cfg.NeoTree.*` namespace prefix.
---   Import specific type modules as needed via:
---   ```lua
---   ---@type Cfg.NeoTree.State
---   local state = ...
---   ```
---
--- Organization Principles:
---   1. One file per functional domain (not per source file)
---   2. Extract string literal unions as type aliases
---   3. Minimal forward dependencies between type modules
---   4. Structural typing for Neo-tree core objects
---   5. Explicit field documentation with usage notes

require("config.neotree.@types.aliases")
require("config.neotree.@types.node")
require("config.neotree.@types.state")
require("config.neotree.@types.config")
require("config.neotree.@types.actions")
require("config.neotree.@types.trash")
require("config.neotree.@types.safety")
require("config.neotree.@types.open")
require("config.neotree.@types.reveal")
require("config.neotree.@types.cwd_sync")
require("config.neotree.@types.highlights")
require("config.neotree.@types.watcher")
require("config.neotree.@types.sources")
require("config.neotree.@types.wsl")
require("config.neotree.@types.project_root")

return {}
