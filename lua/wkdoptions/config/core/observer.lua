---@module 'wkdoptions.config.core.observer'
--- Observer pattern for configuration changes.

local M = {}

--- Observer lists for re-apply hooks
---@type { highlight: fun(key:string)[], options: fun(key:string)[] }
local observers = {
  highlight = {},
  options = {},
}

--- Register after-set callback for a namespace ('highlight' | 'options').
---@param ns '"highlight"'|'"options"'
---@param fn fun(key:string):nil
---@return nil
function M.on_after_set(ns, fn)
  if type(fn) ~= "function" then
    return
  end

  if not observers[ns] then
    observers[ns] = {}
  end

  table.insert(observers[ns], fn)
end

--- Trigger all callbacks for a namespace and key.
---@param ns '"highlight"'|'"options"'
---@param key string
---@return nil
function M.trigger(ns, key)
  local cbs = observers[ns]
  if not cbs then
    return
  end

  for i = 1, #cbs do
    pcall(cbs[i], key)
  end
end

--- Clear all observers for a namespace.
---@param ns '"highlight"'|'"options"'
---@return nil
function M.clear(ns)
  observers[ns] = {}
end

--- Get observer count for testing/debugging.
---@nodiscard
---@param ns '"highlight"'|'"options"'
---@return integer
function M.count(ns)
  return #(observers[ns] or {})
end

return M
