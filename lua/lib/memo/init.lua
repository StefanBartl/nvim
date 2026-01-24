---@module 'lib.memo'
--- Aggregated export for cache helpers with enhanced API.

local M = {}

--- Lazy require to avoid overhead on cold load.
---@generic T
---@param mod string
---@return T
local function lr(mod)
  return require("lib.memo." .. mod)
end

-- Bestehende Submodule
M.lru = lr("lru")
M.memo = lr("memo")

--- Convenience function: memoize with default settings.
--- Delegates to memo.memoize but provides shorter syntax.
---@param func fun(...): any # Function to memoize
---@param opts table<string, any>|nil # Optional config: { size = 128, weak = "kv", keyer = nil }
---@return fun(...): any # Memoized function
function M.fn(func, opts)
  opts = opts or {}
  local size = opts.size or 128
  local keyer = opts.keyer
  
  return M.memo.memoize(func, size, keyer)
end

---@type Lib.Memo
return M
