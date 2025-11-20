---@module 'lib.tables'
--- Aggregated export for table helpers.

local M = {}

--- Lazy require to avoid overhead on cold load.
---@generic T
---@return table
local function lr(mod)
  return require("lib.tables." .. mod)
end

M.array = lr("array")
M.core = lr("core")
M.dict = lr("dict")
M.set = lr("set")
M.functional = lr("functional")
M.deep = lr("safe")
M.iterate = lr("set")

return M
