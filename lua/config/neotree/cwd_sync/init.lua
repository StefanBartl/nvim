---@module 'config.neotree.cwd_sync'

local lazy = require("lib.lazy")
local buffer_utils = lazy.require('config.neotree.utils.buffer')
local callback_guard = lazy.require('config.neotree.utils.selective_callback_guard')
local memo = lazy.require("lib.memo")
local notify = lazy.require("lib.notify").create("[config.neotree.cwd_sync]")
local debug = notify.debug
local warn = notify.warn

local M = {}

local api, uv = vim.api, vim.uv
local now = uv.now
local nvim_win_is_valid = api.nvim_win_is_valid

---@type Cfg.NeoTree.CwdSync.State
local S = {
  timer = nil,
  pending = false,
  last_dir = nil,
  last_file = nil,
  user_navigated = false,
  last_user_action = 0,
  pause_until = 0,
  sync_scheduled = false,
}

---Pause sync for specified duration
---@param ms integer
function M.pause_sync(ms)
  S.pause_until = now() + ms
  S.user_navigated = true
  S.last_user_action = now()
end

---Get timer with memoization
---@return userdata|uv.uv_timer_t|nil
local get_timer = memo.fn(function()
  return uv.new_timer()
end, { size = 1 })

---Find valid Neo-tree window in current tab
---@return integer|nil win
local function find_neotree_win()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if nvim_win_is_valid(win) then
      local buf = api.nvim_win_get_buf(win)
      if api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        return win
      end
    end
  end
  return nil
end

--- Wait for window to stabilize after creation
---@param max_attempts integer
---@param interval_ms integer
---@return integer|nil stable_win
local function wait_for_stable_window(max_attempts, interval_ms)
  max_attempts = max_attempts or 10
  interval_ms = interval_ms or 50

  for i = 1, max_attempts do
    local win = find_neotree_win()

    if win and nvim_win_is_valid(win) then
      -- Double-check stability: wait a bit and verify again
      vim.wait(interval_ms)

      if nvim_win_is_valid(win) then
        return win
      end
    end

    if i < max_attempts then
      vim.wait(interval_ms)
    end
  end

  return nil
end

---Derive directory and path with validation
---@param buf integer
---@param use_project_root boolean
---@return string|nil dir
---@return string|nil path
local function derive_dir_and_path(buf, use_project_root)
  local ctx = buffer_utils.get_buffer_context(buf)
  if not ctx then
    return nil, nil
  end

  local dir = ctx.dir

  if use_project_root then
    local ok, Root = pcall(require, "config.neotree.actions.project_root")
    if ok and type(Root.get) == "function" then
      local root = Root.get(buf)
      if root and root ~= "" then
        dir = root
      end
    end
  end

  return dir, ctx.file
end

--- Execute sync with comprehensive window validation
---@param cfg table
local function sync_now(cfg)
  if now() < S.pause_until then
    if cfg.debug then
      debug("[cwd_sync] Sync paused")
    end
    return
  end

  -- STEP 1: Pre-check Neo-tree window state
  local neo_win = find_neotree_win()

  if not neo_win and not cfg.open_if_closed then
    if cfg.debug then
      debug("[cwd_sync] No Neo-tree window and open_if_closed=false")
    end
    return
  end

  -- Validate window before proceeding
  if neo_win and not nvim_win_is_valid(neo_win) then
    if cfg.debug then
      warn("[cwd_sync] Invalid Neo-tree window detected")
    end
    neo_win = nil
  end

  local cur_buf = api.nvim_get_current_buf()
  if not buffer_utils.is_valid_file_buffer(cur_buf) then
    if cfg.debug then
      debug("[cwd_sync] Current buffer is not a valid file buffer")
    end
    return
  end

  local dir, path = derive_dir_and_path(cur_buf, cfg.use_project_root)
  if not dir or dir == "" or not path or path == "" then
    if cfg.debug then
      debug("[cwd_sync] Could not derive dir/path")
    end
    return
  end

  -- Skip if already synced
  if S.last_dir == dir and S.last_file == path then
    if cfg.debug then
      debug("[cwd_sync] Already synced to current location")
    end
    return
  end

  if cfg.also_set_nvim_cwd then
    pcall(api.nvim_set_current_dir, dir)
  end

  local ok_cmd, cmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    if cfg.debug then
      notify.error("[cwd_sync] Could not load neo-tree.command")
    end
    return
  end

  -- STEP 2: Save previous window BEFORE execute
  local prev_win = api.nvim_get_current_win()

  if prev_win and not nvim_win_is_valid(prev_win) then
    prev_win = nil
  end

  if cfg.debug then
    debug("[cwd_sync] Pre-execute")
    vim.print({
      neo_win = neo_win,
      prev_win = prev_win,
      dir = dir,
      path = path,
      callbacks_disabled = callback_guard.is_disabled(),
    })
  end

  -- STEP 3: Execute with callbacks disabled (longer delay for CWD changes)
  local exec_ok, exec_result = callback_guard.with_events_disabled(function()
    cmd.execute({
      action = "show",
      source = "filesystem",
      position = require("config.neotree").get_default_position(),
      dir = dir,
      reveal = true,
      reveal_file = path,
    })
  end, 1000)  -- Increased from 500 to 1000ms

  if not exec_ok then
    --  Clear any stale state on error
    S.last_dir = nil
    S.last_file = nil
    warn(string.format("[cwd_sync] Execute failed: %s", tostring(exec_result)))
    return
  end

  -- STEP 4: Wait for window to stabilize
  vim.defer_fn(function()
    local stable_win = wait_for_stable_window(10, 50)

    if cfg.debug then
      debug("[cwd_sync] Post-execute")
      vim.print({
        exec_ok = exec_ok,
        stable_win = stable_win,
        callbacks_disabled = callback_guard.is_disabled(),
      })
    end

    if stable_win then
      S.last_dir = dir
      S.last_file = path

      -- Validate prev_win again before focus restore
      if cfg.keep_focus and prev_win and nvim_win_is_valid(prev_win) then
        -- Additional check: Ensure prev_win is not Neo-tree itself
        local prev_buf = api.nvim_win_get_buf(prev_win)
        if vim.bo[prev_buf].filetype ~= "neo-tree" then
          pcall(api.nvim_set_current_win, prev_win)
        end
      end
    else
      -- Window never stabilized - clear state
      if cfg.debug then
        warn("[cwd_sync] Window never stabilized")
      end
      S.last_dir = nil
      S.last_file = nil
    end
  end, 200)
end

---Schedule sync with race condition prevention
---@param cfg table
local function schedule_sync(cfg)
  if S.sync_scheduled then
    return
  end
  S.sync_scheduled = true

  local timer = get_timer()
  if not timer then
    notify.error("[cwd_sync] Timer creation failed")
    S.sync_scheduled = false
    return
  end

  timer:stop()

  if now() < S.pause_until then
    S.sync_scheduled = false
    return
  end

  timer:start(cfg.debounce_ms, 0, function()
    vim.schedule(function()
      S.sync_scheduled = false

      if now() < S.pause_until then
        return
      end

      local time_since_action = now() - S.last_user_action
      if S.user_navigated and time_since_action > 2000 then
        S.user_navigated = false
      end

      sync_now(cfg)
    end)
  end)
end

function M.setup(cfg)

  local aug = api.nvim_create_augroup("NeoTreeCwdSync", { clear = true })

  api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = aug,
    callback = function()
      schedule_sync(cfg)
    end,
    desc = "Sync Neo-tree with current buffer (reveal)",
  })

  api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      if S.timer then
        pcall(S.timer.stop, S.timer)
        pcall(S.timer.close, S.timer)
        S.timer = nil
      end
    end,
    desc = "Cleanup NeoTreeCwdSync timer",
  })

  require("config.neotree.cwd_sync.disable_follow").setup()
end

return M
