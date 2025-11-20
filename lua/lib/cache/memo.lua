---@module 'lib.cache.memo'
--- Memoization helpers backed by LRU cache from lib.cache.lru.

local LRU = require("lib.cache.lru")

---@class Memo
local M = {}

--- Memoize a pure function by its argument tuple.
--- Note: keys are created from tostring(...) which is fine for primitives/strings.
--- For complex keys, pass a keyer that returns a unique string.
---@param fn fun(...): any
---@param cap integer|nil
---@param keyer fun(...): string|nil
---@return fun(...): any
function M.memoize(fn, cap, keyer)
  local lru = LRU.new(cap or 128)
  return function(...)
    local key = keyer and keyer(...) or table.concat({ ... }, "\31") -- unit separator
    local hit = lru:get(key)
    if hit ~= nil then
      return hit
    end
    local val = fn(...)
    lru:put(key, val)
    return val
  end
end

return M
