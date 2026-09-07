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
---@field reveal_current_file? boolean Documented no-op until window/open/keymaps/reveal_current_file.lua is rebuilt
---@field only_lhs? boolean Attach only the lhs-restricting keymap layer

---@class Cfg.NeoTree.SetupModule
---@field setup fun(opts?: Cfg.NeoTree.InitOpts): nil
---@field options Cfg.NeoTree.InitOpts
---@field get_default_position fun(): Cfg.NeoTree.Position

return {}
