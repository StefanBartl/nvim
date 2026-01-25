---@module 'config.neotree.open.window.controller.semaphore'
---@brief Synchronous semaphore for concurrency control

local notify = require("lib.notify").create("[config.neotree.open.window.controller.semaphore]")

local M = {}

---@type {count: integer, waiting: function[], max_wait: integer}
local sem = {
  count = 1, -- Max 1 concurrent operation
  waiting = {},
  max_wait = 5, -- Max queued operations
}

local cfg = require("config.neotree").options

---Try to acquire semaphore
---@return boolean acquired
function M.acquire()
  if sem.count > 0 then
    sem.count = sem.count - 1
    return true
  end

  -- Queue is full
  if #sem.waiting >= sem.max_wait then
    if cfg.debug then
      notify.warn("[semaphore] Queue full, dropping request")
    end
    return false
  end

  -- Add to wait queue
  local co = coroutine.running()
  if co then
    table.insert(sem.waiting, co)
    coroutine.yield() -- Wait for release
    return true
  end

  return false
end

---Release semaphore
---@return nil
function M.release()
  sem.count = math.min(1, sem.count + 1)

  -- Wake up next waiter
  if #sem.waiting > 0 then
    local waiter = table.remove(sem.waiting, 1)
    if waiter then
      vim.schedule(function()
        coroutine.resume(waiter)
      end)
    end
  end
end

---Force release (recovery)
---@return nil
function M.force_release()
  sem.count = 1
  sem.waiting = {}
end

---Get semaphore status
---@return {available: boolean, waiting: integer}
function M.status()
  return {
    available = sem.count > 0,
    waiting = #sem.waiting,
  }
end

return M
