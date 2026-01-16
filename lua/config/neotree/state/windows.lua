---@module 'config.neotree.state.windows'
---@brief Central Neo-tree window state registry with events and snapshots
---@description
--- This module represents the single source of truth for Neo-tree window state.
--- It is UI-agnostic, side-effect free and safe to access from any module.

local M = {}

---@type Cfg.NeoTree.Window
local state = {
  open = false,
  position = nil,
  source = nil,  -- ADDED: Track active source
}

---@type fun(from: Cfg.NeoTree.Window, to: Cfg.NeoTree.Window, action: string)[]
local listeners = {}

---@type Cfg.NeoTree.Window[]
local snapshots = {}

---@type boolean
local debug_enabled = false

---@return Cfg.NeoTree.Window
local function clone_state()
  return {
    open = state.open,
    position = state.position,
    source = state.source,
  }
end

---@param from Cfg.NeoTree.Window
---@param to Cfg.NeoTree.Window
---@param action string
local function emit(from, to, action)
  if debug_enabled then
    snapshots[#snapshots + 1] = {
      open = to.open,
      position = to.position,
      source = to.source,
    }
  end

  for i = 1, #listeners do
    pcall(listeners[i], from, to, action)
  end
end

function M.is_open()
  return state.open
end

function M.get_position()
  return state.position
end

function M.get_source()
  return state.source
end

---Get complete state (for debugging)
---@return Cfg.NeoTree.Window
function M.get_state()
  return clone_state()
end

---@param pos Cfg.NeoTree.Position
---@param source? string
---@param action? string
function M.set_open(pos, source, action)
  local from = clone_state()
  state.open = true
  state.position = pos
  state.source = source or state.source  -- Keep existing source if not provided
  emit(from, clone_state(), action or "open")
end

---@param action? string
function M.set_closed(action)
  local from = clone_state()
  state.open = false
  state.position = nil
  -- IMPORTANT: Keep source even when closed (for restore)
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
  snapshots = {}
end

return M
