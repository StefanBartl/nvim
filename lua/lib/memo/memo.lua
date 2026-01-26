---@module 'lib.memo.memo'
--- Memoization helpers backed by LRU cache from lib.memo.lru.

local LRU = require("lib.memo.lru")

local M = {}

--- Memoize a pure function by its argument tuple.
--- Note: keys are created from tostring(...) which is fine for primitives/strings.
--- For complex keys, pass a keyer that returns a unique string.
---@param fn fun(...): any # Function to memoize
---@param cap integer|nil # Cache capacity (default: 128)
---@param keyer fun(...): string|nil # Optional custom key generator
---@return fun(...): any # Memoized function
function M.memoize(fn, cap, keyer)
  -- Validate and sanitize capacity
  local capacity = cap
  if capacity == nil then
    capacity = 128
  end
  if type(capacity) ~= "number" then
    error(("memoize: cap must be number or nil, got %s"):format(type(capacity)), 2)
  end
  
  local lru = LRU.new(capacity)
  
  return function(...)
    local key = keyer and keyer(...) or table.concat({ ... }, "\31") -- unit separator
    local hit = lru:get(key)
    if hit ~= nil then
      return hit
    end
    local val = fn(...)
    if val == nil then
      -- Don't cache nil values
      return nil
    end
    lru:put(key, val)
    return val
  end
end

return M
