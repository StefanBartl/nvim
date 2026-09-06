---@meta
---@module 'config.neotree.@types.config'
---@brief Configuration structures for Neo-tree setup
---@description
--- Types for the main `setup()` function and module-level configuration.
--- Used by `config.neotree.init` to configure all sub-modules.

---@class Cfg.NeoTree.InitOpts
---@field debug? boolean Global debug flag for all modules
---@field default_position? Cfg.NeoTree.Position Default window position
---@field restore_last_position? boolean Restore tree state instead of revealing current file
---@field reveal_current_file? boolean Only has an effect if window_open == false
---@field only_lhs? boolean Only has an effect if window_open == false
---@field window_debug? boolean Accepted by M.setup(), see --- CDX: at its default in init.lua
---@field window_open? boolean Accepted by M.setup(), see --- CDX: at its default in init.lua

---@class Cfg.NeoTree.SetupModule
---@field setup fun(opts?: Cfg.NeoTree.InitOpts): nil
---@field options Cfg.NeoTree.InitOpts
---@field get_default_position fun(): Cfg.NeoTree.Position
--- CDX: declared but M never implements this method; plugins/neotree.lua
--- instead passes `busy_guard = false` as a plain InitOpts value (merged into
--- M.options, name-colliding with this method decl). Clarify intent: method
--- or option?
---@field busy_guard fun(): boolean

return {}
