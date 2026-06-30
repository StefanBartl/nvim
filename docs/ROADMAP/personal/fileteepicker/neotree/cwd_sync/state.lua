---@module 'config.neotree.cwd_sync.state'
---@brief Isolated state management for cwd_sync

local M = {}

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
