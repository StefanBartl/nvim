---@module 'lib.strings'
--- Aggregated export for strings helpers.

local M = {}

--- Lazy require to avoid overhead on cold load.
---@generic T
---@return table
local function lr(mod)
  return require("lib.strings." .. mod)
end

M.core       = lr("core")
M.patterns   = lr("patterns")

return M

