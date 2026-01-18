---@module 'config.neotree.open.window.controller'
---@brief Refactored Neo-tree window controller with deterministic state machine

local M = {}

-- Sub-modules (lazy loaded)
local state_machine
local semaphore
---@diagnostic disable-next-line: unused-local
local executor
local position_utils

---Create an opener function for a specific position
---@param target_position Cfg.NeoTree.Position
---@param source? string
---@return fun()
function M.make_opener(target_position, source)
  -- Lazy load sub-modules
  if not state_machine then
    state_machine = require("config.neotree.open.window.controller.state_machine")
    semaphore = require("config.neotree.open.window.controller.semaphore")
---@diagnostic disable-next-line: unused-local
    executor = require("config.neotree.open.window.controller.executor")
    position_utils = require("config.neotree.open.window.controller.position")
  end

  local pos = position_utils.normalize(target_position)

  return function()
    -- Acquire semaphore (blocks concurrent operations)
    if not semaphore.acquire() then
      if require("config.neotree").options.debug then
        vim.notify("[neo-tree] Blocked by semaphore", vim.log.levels.WARN)
      end
      return
    end

    -- Execute state machine transition
    local ok, err = pcall(function()
      state_machine.execute_transition(pos, source)
    end)

    if not ok then
      vim.notify(
        string.format("[neo-tree] Controller error: %s", tostring(err)),
        vim.log.levels.ERROR
      )
      semaphore.force_release()
    end
  end
end

---Get current state snapshot
---@return table {open: boolean, position: string|nil, source: string|nil}
function M.get_state()
  return require("config.neotree.state.windows").get_state()
end

---Force-clear semaphore (recovery)
---@return nil
function M.clear_semaphore()
  if semaphore then
    semaphore.force_release()
  end
  vim.notify("[neo-tree] Semaphore manually cleared", vim.log.levels.INFO)
end

return M
