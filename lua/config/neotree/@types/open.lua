---@meta
---@module 'config.neotree.@types.open'
---@brief Window management and opening logic types
---@description
--- Types for window state management, positioning, measurement,
--- and concurrency control during Neo-tree window operations.

---@class Cfg.NeoTree.Open.Win.AliasList
--- List of alternative key strings that should be registered
--- as aliases for a primary lhs mapping.
---@field [integer] string

---@class Cfg.NeoTree.Open.Win.ExtraLhs
---@field extra_lhs? table<string, Cfg.NeoTree.Open.Win.AliasList>
--- Mapping of key combinations (e.g. "<A-c>") to a list of
--- alternative lhs strings for keymap registration.

---@class Cfg.NeoTree.Open.Win.TimingEntry
---@field method string Opening method used ("reveal", "focus", etc.)
---@field position Cfg.NeoTree.Position Window position
---@field duration_ns integer Time taken in nanoseconds
---@field cwd string Working directory during operation
---@field cwd_files? integer Number of files in CWD (if applicable)
---@field first_session boolean First time opening in this session
---@field first_cwd boolean First time in this working directory
---@field action_type Cfg.NeoTree.Position Type of position action

---@class Cfg.NeoTree.Open.Win.BusyGuardState
---@field locked boolean Currently locked flag
---@field lock_time? number Timestamp when locked (vim.loop.now())
---@field retry_count number Consecutive lock collision counter

return {}
