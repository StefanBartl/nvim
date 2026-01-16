---@module 'config.neotree.open.window.controller'
---@brief Centralized Neo-tree window controller with deterministic state machine
---@description
--- Owns the Neo-tree window lifecycle and decides open / close / switch actions.
--- Float windows are handled via toggle=true by design.
--- The controller never reads Neo-tree internal state.

local buffer_utils = require("config.neotree.utils.buffer")
local state = require("config.neotree.state.windows")
local float = require("config.neotree.open.window.float")
-- local reveal = require("config.neotree.open.reveal.controller") -- FIX: unused?
local tree_state = require("config.neotree.state.tree")
local cfg = require("config.neotree").options

local M = {}

-- Busy-Guard Configuration
local use_busy_guard = require("config.neotree").busy_guard() or false
local BUSY_GUARD_TIMEOUT_MS = 20 -- Configurable timeout
local BUSY_GUARD_MAX_RETRIES = 3 -- Max retry attempts before force-clear

-- ============================================================================
-- Window Focus Management
-- ============================================================================

---Focus the neo-tree window if it exists and is valid
---@return boolean success
local function focus_neotree_window()
  local attempts = 0
  local max_attempts = 3

  while attempts < max_attempts do
    attempts = attempts + 1

    -- Find neo-tree window
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
          -- Double-check window is still valid before setting current
          if vim.api.nvim_win_is_valid(win) then
            local ok = pcall(vim.api.nvim_set_current_win, win)
            if ok then
              return true
            else
              if cfg.debug then
                vim.notify(
                  string.format("[neo-tree] Failed to focus window %d (attempt %d)", win, attempts),
                  vim.log.levels.WARN
                )
              end
            end
          end
        end
      end
    end

    -- Window not found or invalid, wait and retry
    if attempts < max_attempts then
      vim.wait(50, function()
        return false
      end) -- Wait 50ms before retry
    end
  end

  if cfg.debug then
    vim.notify("[neo-tree] Failed to focus neo-tree window after retries", vim.log.levels.WARN)
  end
  return false
end

-- ============================================================================
-- Constants & Configuration
-- ============================================================================

-- ---@enum NeoTreePosition
-- local PositionEnum = {
-- left = "left",
-- right = "right",
-- float = "float",
-- current = "current",
-- }

---@type table<string, true>
local valid_positions = {
  left = true,
  right = true,
  float = true,
  current = true,
}

-- ============================================================================
-- Busy Guard State
-- ============================================================================

---@type Cfg.NeoTree.Open.Win.BusyGuardState
local busy_state = {
  locked = false,
  lock_time = nil,
  retry_count = 0,
}

---@type boolean
local is_loading = false

---@return boolean unlocked
local function try_acquire_lock()
  -- CRITICAL: Block ALL inputs during loading phase
  if is_loading then
    if cfg.debug then
      vim.notify("[neo-tree] Blocked: Window is loading", vim.log.levels.WARN)
    end
    return false
  end
  local now = vim.loop.now()

  -- Check if lock expired (timeout-based auto-release)
  if busy_state.locked and busy_state.lock_time then
    local elapsed = now - busy_state.lock_time
    if elapsed > BUSY_GUARD_TIMEOUT_MS then
      if cfg.debug then
        vim.notify(
          string.format("[neo-tree] Lock expired after %dms, auto-releasing", elapsed),
          vim.log.levels.WARN
        )
      end
      busy_state.locked = false
      busy_state.lock_time = nil
      busy_state.retry_count = 0
    end
  end

  -- Try to acquire lock
  if busy_state.locked then
    busy_state.retry_count = busy_state.retry_count + 1

    -- Force-clear if too many retries (safety valve)
    if busy_state.retry_count > BUSY_GUARD_MAX_RETRIES then
      if cfg.debug then
        vim.notify("[neo-tree] Max retries exceeded, force-clearing lock", vim.log.levels.ERROR)
      end
      busy_state.locked = false
      busy_state.lock_time = nil
      busy_state.retry_count = 0
      return true
    end

    return false
  end

  -- Lock acquired
  busy_state.locked = true
  busy_state.lock_time = now
  busy_state.retry_count = 0
  return true
end

---@return nil
local function release_lock()
  busy_state.locked = false
  busy_state.lock_time = nil
  busy_state.retry_count = 0
end

---Schedule lock release after delay
---@param delay_ms number
---@return nil
local function schedule_release(delay_ms)
  vim.defer_fn(function()
    release_lock()
  end, delay_ms)
end

-- ============================================================================
-- Position Validation
-- ============================================================================

---@param pos Cfg.NeoTree.Position
---@return Cfg.NeoTree.Position
local function normalize_position(pos)
  if valid_positions[pos] then
    return pos
  end
  if cfg.debug then
    vim.notify(
      string.format("[neo-tree] Invalid position '%s', defaulting to 'right'", pos),
      vim.log.levels.WARN
    )
  end
  return require("config.neotree").get_default_position()
end

---@param target_position Cfg.NeoTree.Position
---@return "open"|"close"|"switch"
local function decide_action(target_position)
  if not state.is_open() then
    return "open"
  end

  local current_pos = state.get_position()

  -- Critical: Exact position match for close
  if current_pos == target_position then
    return "close"
  end

  return "switch"
end

-- ============================================================================
-- Window Operations (Synchronous where possible)
-- ============================================================================

local function open_window(NeoCmd, target_position)
  if cfg.restore_last_position then
    -- Restore Mode
    if target_position == "float" then
      float.toggle(NeoCmd)
      state.set_open("float", "restore")

      -- INCREASED DELAY: Wait for float window to fully initialize
      vim.defer_fn(function()
        local ok, manager = pcall(require, "neo-tree.sources.manager")
        if ok then
          local neo_state = manager.get_state("filesystem")
          if neo_state and neo_state.tree then
            tree_state.restore_state(neo_state.tree)
          end
        end

        -- Try to focus with retries
        focus_neotree_window()
      end, 200) -- CHANGED: 100ms -> 200ms
      return
    end

    -- Non-float positions
    state.set_open(target_position, "restore")

    -- INCREASED DELAY for current position
    local delay = (target_position == "current") and 100 or 50 -- CHANGED: 50->100, 10->50

    vim.defer_fn(function()
      local ok_exec = pcall(NeoCmd.execute, {
        source = "filesystem",
        action = "show",
        position = target_position,
        reveal = false,
      })

      if not ok_exec then
        if cfg.debug then
          vim.notify(
            string.format("[neo-tree] Failed to open %s in restore mode", target_position),
            vim.log.levels.ERROR
          )
        end
        state.set_closed("open_failed")
        return
      end

      -- INCREASED DELAY: Wait for tree to fully render
      vim.defer_fn(function()
        local ok, manager = pcall(require, "neo-tree.sources.manager")
        if ok then
          local neo_state = manager.get_state("filesystem")
          if neo_state and neo_state.tree then
            tree_state.restore_state(neo_state.tree)
          end
        end

        -- Focus with retries
        focus_neotree_window()
      end, 200) -- CHANGED: 100ms -> 200ms
    end, delay)
  else
    -- Reveal Mode (SAME PATTERN)
    if target_position == "float" then
      float.toggle(NeoCmd)
      state.set_open("float", "reveal")

      vim.defer_fn(focus_neotree_window, 200) -- CHANGED: 50ms -> 200ms
      return
    end

    local ctx = buffer_utils.get_buffer_context()
    state.set_open(target_position, "reveal")

    local delay = (target_position == "current") and 100 or 50 -- CHANGED: 50->100, 10->50

    vim.defer_fn(function()
      local ok_exec = pcall(NeoCmd.execute, {
        source = "filesystem",
        action = "show",
        position = target_position,
        reveal = true,
        reveal_file = ctx and ctx.file or nil,
        reveal_force_cwd = false,
        dir = ctx and ctx.dir or nil,
      })

      if not ok_exec then
        if cfg.debug then
          vim.notify(
            string.format("[neo-tree] Failed to open %s in reveal mode", target_position),
            vim.log.levels.ERROR
          )
        end
        state.set_closed("open_failed")
        return
      end

      vim.defer_fn(focus_neotree_window, 200) -- CHANGED: 50ms -> 200ms
    end, delay)
  end
end
---@param NeoCmd table
local function close_window(NeoCmd)
  local current_pos = state.get_position()

  if cfg.debug then
    vim.notify(
      string.format("[neo-tree] Closing position: %s", tostring(current_pos)),
      vim.log.levels.INFO
    )
  end

  -- CRITICAL: Update state to closed IMMEDIATELY to prevent race conditions
  -- This ensures decide_action() sees correct state even if close fails
  state.set_closed("closing_" .. tostring(current_pos))

  -- Capture state BEFORE any close operation (while window is still valid)
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if ok then
    local neo_state = manager.get_state("filesystem")
    if neo_state and neo_state.tree then
      pcall(tree_state.capture_state, neo_state)
    end
  end

  -- Special handling for 'current' position
  if current_pos == "current" then
    -- Find the neo-tree buffer in current window
    local bufnr = vim.api.nvim_get_current_buf()

    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "neo-tree" then
      if cfg.debug then
        vim.notify(
          string.format("[neo-tree] Force-closing current buffer: %d", bufnr),
          vim.log.levels.INFO
        )
      end

      -- Force-delete buffer immediately (no neo-tree close needed)
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
      return
    else
      if cfg.debug then
        vim.notify(
          "[neo-tree] Current position set but no valid neo-tree buffer found",
          vim.log.levels.WARN
        )
      end
      return
    end
  end

  -- Float position uses toggle
  if current_pos == "float" then
    float.toggle(NeoCmd)
    return
  end

  -- Standard positions (left/right)
  local ok_close = pcall(NeoCmd.execute, {
    source = "filesystem",
    action = "close",
  })

  if not ok_close and cfg.debug then
    vim.notify(
      "[neo-tree] Close command failed for position: " .. tostring(current_pos),
      vim.log.levels.WARN
    )
  end
end

---@param NeoCmd table
---@param target_position Cfg.NeoTree.Position
local function switch_window(NeoCmd, target_position)
  local current_pos = state.get_position()

  -- CRITICAL: For 'current' position, we need extra delay
  -- because buffer deletion + new buffer creation need time
  local delay = (current_pos == "current" or target_position == "current") and 150 or 50

  if cfg.debug then
    vim.notify(
      string.format(
        "[neo-tree] Switching from %s to %s (delay: %dms)",
        tostring(current_pos),
        target_position,
        delay
      ),
      vim.log.levels.INFO
    )
  end

  close_window(NeoCmd)

  vim.defer_fn(function()
    -- Verify state is consistent before opening
    if state.is_open() then
      if cfg.debug then
        vim.notify(
          "[neo-tree] State inconsistency detected during switch, forcing closed",
          vim.log.levels.WARN
        )
      end
      state.set_closed("switch_recovery")
    end

    open_window(NeoCmd, target_position)
  end, delay)
end

-- ============================================================================
-- Public API
-- ============================================================================

---Create an opener function for a specific position
---@param target_position Cfg.NeoTree.Position
---@return fun()
function M.make_opener(target_position)
  local ok, NeoCmd = pcall(require, "neo-tree.command")
  if not ok then
    return function()
      vim.notify("[neo-tree] Failed to load neo-tree.command", vim.log.levels.ERROR)
    end
  end

  ---@type Cfg.NeoTree.Position
  local pos = normalize_position(target_position)

  return function()
    -- ========================================================================
    -- Busy Guard: Try to acquire lock
    -- ========================================================================
    if use_busy_guard and not try_acquire_lock() then
      if cfg.debug then
        vim.notify(
          string.format(
            "[neo-tree] Blocked by busy-guard (retry %d/%d)",
            busy_state.retry_count,
            BUSY_GUARD_MAX_RETRIES
          ),
          vim.log.levels.WARN
        )
      end
      return
    end

    is_loading = true

    local action = decide_action(pos)

    if cfg.debug then
      vim.notify(string.format("[neo-tree] Action decided: %s", action), vim.log.levels.INFO)
    end

    local ok_exec, err = pcall(function()
      if action == "open" then
        open_window(NeoCmd, pos)
      elseif action == "close" then
        close_window(NeoCmd)
      else
        switch_window(NeoCmd, pos)
      end
    end)

    if not ok_exec then
      vim.notify(
        string.format("[neo-tree] Execution error: %s", tostring(err)),
        vim.log.levels.ERROR
      )
    end

    if use_busy_guard then
      -- CLEAR LOADING FLAG after delays
      vim.defer_fn(function()
        is_loading = false
      end, 300) -- CRITICAL: Must be longer than all internal delays (200ms max)

      schedule_release(BUSY_GUARD_TIMEOUT_MS)
    end
  end
end

---Get current controller state
---@return table {open: boolean, position: string|nil}
function M.get_state()
  return {
    open = state.is_open(),
    position = state.get_position(),
  }
end

---Force-clear busy guard (for debugging/recovery)
---@return nil
function M.clear_busy_guard()
  release_lock()
  vim.notify("[neo-tree] Busy guard manually cleared", vim.log.levels.INFO)
end

return M
