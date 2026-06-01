---@module 'custom.open.registry'
---@brief Central registry for :Open handlers.
---@description
--- Handlers are registered once during M.setup() and looked up by key at
--- command invocation time.  Duplicate keys produce a warning, not an error,
--- to allow user overrides.

local notify = require("lib.notify").create("[custom.open.registry]")

local M = {}

---@type table<string, Custom.Open.Handler>
local _handlers = {}

-- ---------------------------------------------------------------------------
-- Write API
-- ---------------------------------------------------------------------------

---Register a handler.  Overwrites an existing registration with a warning.
---@param handler Custom.Open.Handler
---@return boolean success
function M.register(handler)
  if type(handler) ~= "table" then
    notify.error("[custom.open.registry] handler must be a table")
    return false
  end

  if type(handler.key) ~= "string" or handler.key == "" then
    notify.error("[custom.open.registry] handler.key must be a non-empty string")
    return false
  end

  if type(handler.run) ~= "function" then
    notify.error(string.format("[custom.open.registry] handler '%s': run must be a function", handler.key))
    return false
  end

  if type(handler.desc) ~= "string" then
    handler.desc = "(no description)"
  end

  if _handlers[handler.key] then
    notify.warn(string.format("[custom.open.registry] '%s' already registered — overwriting", handler.key))
  end

  _handlers[handler.key] = handler
  return true
end

-- ---------------------------------------------------------------------------
-- Read API
-- ---------------------------------------------------------------------------

---Look up a handler by key.
---@param key string
---@return Custom.Open.Handler|nil
function M.get(key)
  if type(key) ~= "string" then
    return nil
  end
  return _handlers[key]
end

---Return a sorted list of all registered handler keys.
---@return string[]
function M.list_keys()
  local keys = {}
  for k in pairs(_handlers) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

---Return all registered handlers sorted by key.
---@return Custom.Open.Handler[]
function M.list()
  local result = {}
  for _, h in pairs(_handlers) do
    result[#result + 1] = h
  end
  table.sort(result, function(a, b)
    return a.key < b.key
  end)
  return result
end

return M
