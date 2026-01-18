---@module 'config.neotree.state.windows'
---@brief Central Neo-tree window state registry with snapshot optimization

local M = {}

---@type Cfg.NeoTree.Window
local state = {
  open = false,
  position = nil,
  source = nil,
  id = nil,
}

---@type fun(from: Cfg.NeoTree.Window, to: Cfg.NeoTree.Window, action: string)[]
local listeners = {}

---@type Cfg.NeoTree.Window[]
local snapshots = {}

---@type boolean
local debug_enabled = false

-- PERFORMANCE: Cache for snapshot to avoid repeated cloning
---@type {snapshot: Cfg.NeoTree.Window, timestamp: number}|nil
local snapshot_cache = nil
local SNAPSHOT_CACHE_TTL = 100 -- ms

---Clone state (expensive)
---@return Cfg.NeoTree.Window
local function clone_state()
  return {
    open = state.open,
    position = state.position,
    source = state.source,
  }
end

---Emit state transition event
---@param from Cfg.NeoTree.Window
---@param to Cfg.NeoTree.Window
---@param action string
local function emit(from, to, action)
  -- Invalidate cache
  snapshot_cache = nil

  if debug_enabled then
    snapshots[#snapshots + 1] = clone_state()
  end

  for i = 1, #listeners do
    pcall(listeners[i], from, to, action)
  end
end

---PERFORMANCE: Get cached snapshot
---@return Cfg.NeoTree.Window
function M.get_state()
  local now = vim.loop.now()

  if snapshot_cache and (now - snapshot_cache.timestamp < SNAPSHOT_CACHE_TTL) then
    return snapshot_cache.snapshot
  end

  local snapshot = clone_state()
  snapshot_cache = {
    snapshot = snapshot,
    timestamp = now,
  }

  return snapshot
end

-- Individual getters (fast, no cloning)
function M.is_open()
  return state.open
end

function M.get_position()
  return state.position
end

function M.get_source()
  return state.source
end

---@param pos Cfg.NeoTree.Position
---@param source? string
---@param action? string
function M.set_open(pos, source, action)
  local from = clone_state()
  state.open = true
  state.position = pos
  state.source = source or state.source
  emit(from, clone_state(), action or "open")
end

---@param action? string
function M.set_closed(action)
  local from = clone_state()
  state.open = false
  state.position = nil
  -- Keep source for restore
  emit(from, clone_state(), action or "close")
end

---@param cb fun(from: Cfg.NeoTree.Window, to: Cfg.NeoTree.Window, action: string)
function M.on_transition(cb)
  listeners[#listeners + 1] = cb
end

---@param enable boolean
function M.enable_debug(enable)
  debug_enabled = enable == true
end

---@return Cfg.NeoTree.Window[]
function M.get_snapshots()
  return snapshots
end

function M.reset()
  state.open = false
  state.position = nil
  state.source = nil
  snapshot_cache = nil
  snapshots = {}
end

---@param _id integer|nil
function M.set_id(_id)
  state.id = _id
  if state.id == nil then
    vim.notify("[neo-tree.state.window]: id is set to nil")
  end
end

return M
