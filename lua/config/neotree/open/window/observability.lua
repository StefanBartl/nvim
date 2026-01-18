---@module 'config.neotree.open.window.observability'
---@brief Structured logging and metrics for Neo-tree operations

local M = {}

---@type table[]
local events = {}
local MAX_EVENTS = 1000

---Log state transition
---@param event_type string
---@param data table
function M.log_event(event_type, data)
  local event = vim.tbl_extend("force", {
    type = event_type,
    timestamp = os.time(),
    time_ns = vim.loop.hrtime(),
  }, data)

  table.insert(events, 1, event)

  -- Limit size
  while #events > MAX_EVENTS do
    table.remove(events)
  end
end

---Get recent events
---@param count? integer
---@return table[]
function M.get_events(count)
  count = count or 50
  local result = {}
  for i = 1, math.min(count, #events) do
    result[i] = events[i]
  end
  return result
end

---Export events to JSON file
---@param path? string
function M.export_events(path)
  path = path or vim.fn.stdpath("state") .. "/neotree_events.json"

  local fd = io.open(path, "w")
  if fd then
    fd:write(vim.json.encode(events))
    fd:close()
    vim.notify(string.format("Exported %d events to %s", #events, path), vim.log.levels.INFO)
  end
end

---Clear events
function M.clear_events()
  events = {}
end

return M
