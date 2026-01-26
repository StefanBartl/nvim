---@module 'config.neotree.open.window.controller.state_machine'
---@brief Deterministic state machine for Neo-tree window lifecycle

local notify = require("lib.notify").create("[config.neotree.open.window.controller.state_machine]")

local M = {}

local state = require("config.neotree.state.windows")
local executor = require("config.neotree.open.window.controller.executor")
local semaphore = require("config.neotree.open.window.controller.semaphore")
local cfg = require("config.neotree").options

---Decide action based on current state
---@param target_position Cfg.NeoTree.Position
---@param target_source string
---@return "open"|"close"|"switch"
local function decide_action(target_position, target_source)
  local snapshot = state.get_state()

  if not snapshot.open then
    return "open"
  end

  local current_pos = snapshot.position
  local current_src = snapshot.source

  -- Source mismatch → always switch
  if target_source ~= current_src then
    return "switch"
  end

  -- Position match → close
  if current_pos == target_position then
    return "close"
  end

  return "switch"
end

---Execute state machine transition with callbacks
---@param target_position Cfg.NeoTree.Position
---@param source? string
---@return nil
function M.execute_transition(target_position, source)
  local target_source = source or state.get_source() or "filesystem"
  local action = decide_action(target_position, target_source)

  if cfg.debug then
    local snapshot = state.get_state()
    notify.info(string.format( "[neo-tree] Action: %s (pos: %s, source: %s -> %s)", action, target_position, snapshot.source or "nil", target_source ))
  end

  if action == "open" then
    executor.open_window(target_position, target_source, function(success)
      semaphore.release()
      if not success and cfg.debug then
        notify.error("[neo-tree] Open failed")
      end
    end)
  elseif action == "close" then
    executor.close_window(function(success)
      semaphore.release()
      if not success and cfg.debug then
        notify.error("[neo-tree] Close failed")
      end
    end)
  else -- switch
    local current_pos = state.get_position()

    executor.close_window(function(close_ok)
      if not close_ok then
        semaphore.release()
        return
      end

      -- Guard: Verify state is actually closed
      local snapshot = state.get_state()
      if snapshot.open then
        if cfg.debug then
          notify.warn("[neo-tree] State inconsistency after close")
        end
        state.set_closed("switch_recovery")
      end

      -- Calculate delay based on positions
      local delay = (current_pos == "current" or target_position == "current") and 150 or 50

      vim.defer_fn(function()
        executor.open_window(target_position, target_source, function(open_ok)
          semaphore.release()
          if not open_ok and cfg.debug then
            notify.error("[neo-tree] Switch-open failed")
          end
        end)
      end, delay)
    end)
  end
end

return M
