# Refactoring & Modularisierung

## Table of content

- [Refactoring & Modularisierung](#refactoring-modularisierung)
  - [Aktuelle Struktur-Probleme](#aktuelle-struktur-probleme)
  - [Vorgeschlagene Modulstruktur](#vorgeschlagene-modulstruktur)
  - [Implementierungsplan](#implementierungsplan)
    - [`cwd_sync/state.lua`](#cwd_syncstatelua)
    - [`cwd_sync/timer.lua`](#cwd_synctimerlua)
    - [`cwd_sync/buffer_resolver.lua`](#cwd_syncbuffer_resolverlua)
    - [`cwd_sync/sync_executor.lua`](#cwd_syncsync_executorlua)
    - [Refactored `cwd_sync/init.lua`](#refactored-cwd_syncinitlua)

---

## Aktuelle Struktur-Probleme

- 249 Zeilen in einer Datei
- Gemischte Verantwortlichkeiten (Timer, State, Buffer-Utils, Neo-tree-Integration)
- Keine klare Separation of Concerns

## Vorgeschlagene Modulstruktur

```
cwd_sync/
├── init.lua              -- Public API (setup, pause_sync)
├── state.lua             -- Sync-State-Management
├── timer.lua             -- Timer-Lifecycle (memoized)
├── sync_executor.lua     -- Core sync logic
├── buffer_resolver.lua   -- Buffer → Dir/Path Resolution
└── @types/init.lua       -- Type Definitions
```

## Implementierungsplan

### `cwd_sync/state.lua`

```lua
---@module 'config.neotree.cwd_sync.state'
---@brief Isolated state management for cwd_sync

local M = {}

---@class Cfg.NeoTree.CwdSync.State
---@field last_dir string|nil
---@field last_file string|nil
---@field user_navigated boolean
---@field last_user_action integer
---@field pause_until integer
---@field sync_scheduled boolean

---@type Cfg.NeoTree.CwdSync.State
local state = {
  last_dir = nil,
  last_file = nil,
  user_navigated = false,
  last_user_action = 0,
  pause_until = 0,
  sync_scheduled = false,
}

---@return Cfg.NeoTree.CwdSync.State
function M.get()
  return state
end

---@param ms integer
function M.pause_until(ms)
  state.pause_until = vim.loop.now() + ms
  state.user_navigated = true
  state.last_user_action = vim.loop.now()
end

---@return boolean
function M.is_paused()
  return vim.loop.now() < state.pause_until
end

---@param dir string
---@param file string
function M.mark_synced(dir, file)
  state.last_dir = dir
  state.last_file = file
end

---@param dir string
---@param file string
---@return boolean
function M.is_already_synced(dir, file)
  return state.last_dir == dir and state.last_file == file
end

---@param scheduled boolean
function M.set_scheduled(scheduled)
  state.sync_scheduled = scheduled
end

---@return boolean
function M.is_scheduled()
  return state.sync_scheduled
end

---Reset user_navigated after cooldown
function M.reset_user_nav_if_cooldown()
  local time_since = vim.loop.now() - state.last_user_action
  if state.user_navigated and time_since > 2000 then
    state.user_navigated = false
  end
end

return M
```

### `cwd_sync/timer.lua`

```lua
---@module 'config.neotree.cwd_sync.timer'
---@brief Memoized timer instance for cwd_sync

local memo = require("lib.memo")

---@return uv.uv_timer_t|nil
local get_timer = memo.fn(function()
  local uv = vim.uv or vim.loop
  return uv.new_timer()
end, { size = 1 })

return get_timer
```

### `cwd_sync/buffer_resolver.lua`

```lua
---@module 'config.neotree.cwd_sync.buffer_resolver'
---@brief Buffer → Dir/Path resolution with project root support

local buffer_utils = require("config.neotree.utils.buffer")

local M = {}

---Derive directory and path with project root support
---@param buf integer
---@param use_project_root boolean
---@param fallback_to_bufdir boolean
---@return string|nil dir
---@return string|nil path
function M.resolve(buf, use_project_root, fallback_to_bufdir)
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
      elseif not fallback_to_bufdir then
        return nil, nil -- No root and no fallback
      end
    end
  end

  return dir, ctx.file
end

return M
```

### `cwd_sync/sync_executor.lua`

```lua
---@module 'config.neotree.cwd_sync.sync_executor'
---@brief Core sync execution with window validation

local state = require("config.neotree.cwd_sync.state")
local buffer_utils = require("config.neotree.utils.buffer")
local resolver = require("config.neotree.cwd_sync.buffer_resolver")

local M = {}

---Find valid Neo-tree window in current tab
---@return integer|nil win
local function find_neotree_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "neo-tree" then
        return win
      end
    end
  end
  return nil
end

---Execute sync with full window validation
---@param cfg Cfg.NeoTree.CwdSync.Config
---@nodiscard
function M.execute(cfg)
  if state.is_paused() then
    return
  end

  -- CRITICAL: Validate Neo-tree window BEFORE executing
  local neo_win = find_neotree_win()

  if not neo_win and not cfg.open_if_closed then
    return -- No window and shouldn't open
  end

  -- Validate window is still valid after debounce
  if neo_win and not vim.api.nvim_win_is_valid(neo_win) then
    neo_win = nil
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  if not buffer_utils.is_valid_file_buffer(cur_buf) then
    return
  end

  local dir, path = resolver.resolve(
    cur_buf,
    cfg.use_project_root,
    cfg.project_root_fallback_to_bufdir
  )

  if not dir or dir == "" or not path or path == "" then
    return
  end

  -- Skip if already synced
  if state.is_already_synced(dir, path) then
    return
  end

  if cfg.also_set_nvim_cwd then
    pcall(vim.api.nvim_set_current_dir, dir)
  end

  local ok_cmd, cmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    return
  end

  ---@type integer|nil
  local prev_win = vim.api.nvim_get_current_win()

  -- Validate previous window
  if prev_win and not vim.api.nvim_win_is_valid(prev_win) then
    prev_win = nil
  end

  -- Execute inside pcall with window validation
  local ok = pcall(function()
    -- Re-validate Neo-tree window inside execution context
    local exec_win = find_neotree_win()

    if not exec_win and cfg.open_if_closed then
      -- Open new Neo-tree window first
      cmd.execute({
        action = "show",
        source = "filesystem",
        position = require("config.neotree").get_default_position(),
      })

      -- Wait for window creation
      vim.wait(100, function()
        return find_neotree_win() ~= nil
      end)

      exec_win = find_neotree_win()
    end

    if not exec_win then
      error("No valid Neo-tree window for sync")
    end

    -- Execute with validated window context
    cmd.execute({
      action = "show",
      source = "filesystem",
      position = require("config.neotree").get_default_position(),
      dir = dir,
      reveal = true,
      reveal_file = path,
    })
  end)

  if ok then
    state.mark_synced(dir, path)
  end

  -- Restore focus with validation
  if cfg.keep_focus and prev_win and vim.api.nvim_win_is_valid(prev_win) then
    pcall(vim.api.nvim_set_current_win, prev_win)
  end
end

return M
```

### Refactored `cwd_sync/init.lua`

```lua
---@module 'config.neotree.cwd_sync'

local state = require("config.neotree.cwd_sync.state")
local executor = require("config.neotree.cwd_sync.sync_executor")
local get_timer = require("config.neotree.cwd_sync.timer")

local M = {}

---Pause sync for specified duration
---@param ms integer
function M.pause_sync(ms)
  state.pause_until(ms)
end

---Schedule sync with race condition prevention
---@param cfg Cfg.NeoTree.CwdSync.Config
local function schedule_sync(cfg)
  if state.is_scheduled() then
    return
  end
  state.set_scheduled(true)

  local timer = get_timer()
  if not timer then
    vim.notify("[cwd_sync] Timer creation failed", vim.log.levels.ERROR)
    state.set_scheduled(false)
    return
  end

  timer:stop()

  -- Check pause before scheduling
  if state.is_paused() then
    state.set_scheduled(false)
    return
  end

  timer:start(cfg.debounce_ms, 0, function()
    vim.schedule(function()
      state.set_scheduled(false)

      -- Double-check pause
      if state.is_paused() then
        return
      end

      -- Reset user_navigated after cooldown
      state.reset_user_nav_if_cooldown()

      executor.execute(cfg)
    end)
  end)
end

---@param user_cfg? Cfg.NeoTree.CwdSync.Config
function M.setup(user_cfg)
  local cfg = vim.tbl_extend("force", {
    debounce_ms = 150,
    keep_focus = true,
    also_set_nvim_cwd = false,
    open_if_closed = false,
    use_project_root = true,
    project_root_fallback_to_bufdir = true,
  }, user_cfg or {})

  local aug = vim.api.nvim_create_augroup("NeoTreeCwdSync", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = aug,
    callback = function()
      schedule_sync(cfg)
    end,
    desc = "Sync Neo-tree with current buffer (reveal)",
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = aug,
    callback = function()
      local timer = get_timer()
      if timer then
        pcall(timer.stop, timer)
        pcall(timer.close, timer)
      end
    end,
    desc = "Cleanup NeoTreeCwdSync timer",
  })
end

return M
```

---


