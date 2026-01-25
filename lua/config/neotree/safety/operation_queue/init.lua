---@module 'config.neotree.safety.operation_queue'
---@brief Sequential operation queue for file operations

local notify = require("lib.notify").create("[config.neotree.safety.operation_queue]")

local M = {}

---@type Cfg.NeoTree.Safety.QueuedOperation[]
local queue = {}
local processing = false
local paused = false

---Add operation to queue
---@param operation fun() Operation function
---@param name string|nil Operation name
---@param priority integer|nil Priority (default: 10)
function M.enqueue(operation, name, priority)
  name = name or "unnamed_operation"
  priority = priority or 10

  table.insert(queue, {
    fn = operation,
    name = name,
    priority = priority,
  })

  -- Sort by priority
  table.sort(queue, function(a, b)
    return a.priority < b.priority
  end)

  M.process_queue()
end

---Process queue sequentially
function M.process_queue()
  if processing or paused or #queue == 0 then
    return
  end

  processing = true
  local operation = table.remove(queue, 1)

  vim.schedule(function()
    -- Execute operation with error handling
    local ok, err = pcall(operation.fn)

    if not ok then
      notify.error(string.format("Operation '%s' failed: %s", operation.name, tostring(err)))
    end

    -- Delay before next operation (gives filesystem time to settle)
    vim.defer_fn(function()
      processing = false
      M.process_queue()
    end, 500)
  end)
end

---Pause queue processing
function M.pause()
  paused = true
end

---Resume queue processing
function M.resume()
  paused = false
  M.process_queue()
end

---Clear all pending operations
function M.clear()
  queue = {}
  processing = false
end

---Get queue status
---@return {processing:boolean, paused:boolean, pending:integer}
function M.status()
  return {
    processing = processing,
    paused = paused,
    pending = #queue,
  }
end

return M
