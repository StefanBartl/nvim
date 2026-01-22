---@module 'lib.memo'
--- Aggregated export for cache helpers.

local M = {}

--- Lazy require to avoid overhead on cold load.
---@generic T
---@return table
local function lr(mod)
  return require("lib.memo." .. mod)
end

M.lru = lr("lru")
M.memo = lr("memo")

---@type Lib.Memo
return M
