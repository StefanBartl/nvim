---@meta
---@module 'config.neotree.@types.open'

---@class Cfg.NeoTree.Open.Win.BusyGuardState
---@field locked boolean Currently locked
---@field lock_time number|nil Timestamp when locked (vim.loop.now())
---@field retry_count number Number of consecutive lock collisions

return {}
