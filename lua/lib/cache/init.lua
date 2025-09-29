---@module 'lib.cache'
--- Aggregated export for cache helpers.

local M = {}

--- Lazy require to avoid overhead on cold load.
---@generic T
---@return table
local function lr(mod)
  return require("lib.cache." .. mod)
end

M.lru     = lr("lru")
M.memo    = lr("memo")

return M


