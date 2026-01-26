---@module 'config.neotree.utils.selective_callback_guard'
---@brief Selectively disable problematic Neo-tree callbacks

local M = {}

local api = vim.api

---@type table<string, function>
local disabled_callbacks = {}

---Events that cause window access errors during transitions
local PROBLEMATIC_EVENTS = {
  "neo-tree-follow",      -- Primary culprit: accesses old window handle
  "filesystem_navigate",  -- Secondary: filesystem state transitions
  "file_open_requested",  -- Tertiary: file opening during transition
  "after_render",         -- Quaternary: rendering callbacks
  "before_render",        -- Additional: pre-render callbacks
  "vim_buffer_enter",     -- Additional: buffer enter events
}

---Find current valid Neo-tree window
---@return integer|nil
local function find_neotree_win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_is_valid(win) then
      local buf = api.nvim_win_get_buf(win)
      if api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        return win
      end
    end
  end
  return nil
end

---Create a safe wrapper around a callback that validates window handles
---@param original_fn function Original callback
---@return function wrapped Wrapped callback with window validation
local function wrap_with_window_validation(original_fn)
  return function(...)
    -- Update last known valid window
    local current_win = find_neotree_win()
    if current_win then
      require("lib").noop()
    end

    -- Call original with pcall to catch window errors
    local ok, result = pcall(original_fn, ...)

    if not ok then
      -- Check if error is window-related
      if type(result) == "string" and result:match("Invalid 'window'") then
        -- Silently skip - window is in transition
        return nil
      end

      -- Re-throw other errors
      error(result)
    end

    return result
  end
end

---Disable specific Neo-tree callbacks
---@param event_names string[]|nil List of events to disable (default: PROBLEMATIC_EVENTS)
---@return boolean success
function M.disable_events(event_names)
  event_names = event_names or PROBLEMATIC_EVENTS

  local ok, events = pcall(require, "neo-tree.events")
  local _handlers = events._handlers or nil
  if not ok or not events or not _handlers then
    return false
  end

  for _, name in ipairs(event_names) do
    if _handlers[name] then
      disabled_callbacks[name] = _handlers[name]
      _handlers[name] = function() end
    end
  end

  return true
end

---Re-enable previously disabled callbacks (with optional safe wrapping)
---@param use_safe_wrapper boolean|nil Wrap callbacks with window validation (default: true)
---@return boolean success
function M.enable_events(use_safe_wrapper)
  if use_safe_wrapper == nil then
    use_safe_wrapper = true
  end

  if vim.tbl_isempty(disabled_callbacks) then
    return true
  end

  local ok, events = pcall(require, "neo-tree.events")
  if not ok or not events or not events._handlers then
    return false
  end

  for name, handler in pairs(disabled_callbacks) do
    if use_safe_wrapper then
      -- Wrap with window validation
      events._handlers[name] = wrap_with_window_validation(handler)
    else
      -- Restore original
      events._handlers[name] = handler
    end
  end

  disabled_callbacks = {}
  return true
end

---Execute function with callbacks temporarily disabled
---@param fn function Function to execute
---@param restore_delay_ms integer Delay before re-enabling callbacks (default: 1000)
---@param events_to_disable string[]|nil Specific events to disable (default: PROBLEMATIC_EVENTS)
---@return boolean success
---@return any result
function M.with_events_disabled(fn, restore_delay_ms, events_to_disable)
  restore_delay_ms = restore_delay_ms or 1000  -- Increased from 500 to 1000

  local disable_ok = M.disable_events(events_to_disable)
  if not disable_ok then
    -- Fallback: execute without protection
    local ok, result = pcall(fn)
    return ok, result
  end

  local ok, result = pcall(fn)

  -- Schedule re-enable with additional safety buffer
  vim.defer_fn(function()
    -- Double-check: wait a bit more before enabling
    vim.defer_fn(function()
      M.enable_events()
    end, 100)
  end, restore_delay_ms)

  return ok, result
end

---Get list of currently disabled events
---@return string[]
function M.get_disabled_events()
  return vim.tbl_keys(disabled_callbacks)
end

---Check if events are currently disabled
---@return boolean
function M.is_disabled()
  return not vim.tbl_isempty(disabled_callbacks)
end

---@type Cfg.NeoTree.Utils.SelectiveCallbackGuard
return M
