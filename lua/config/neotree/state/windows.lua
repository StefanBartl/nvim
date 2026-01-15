---@module 'config.neotree.state.windows'
---@brief Central Neo-tree window state registry with events and snapshots
---@description
--- This module represents the single source of truth for Neo-tree window state.
--- It is UI-agnostic, side-effect free and safe to access from any module.

local M = {}

---@class NeoTreeWindowState
---@field open boolean
---@field position "left"|"right"|"float"|"current"|nil

---@type NeoTreeWindowState
local state = {
  open = false,
  position = nil,
}

---@type fun(from: NeoTreeWindowState, to: NeoTreeWindowState, action: string)[]
local listeners = {}

---@type NeoTreeWindowState[]
local snapshots = {}

---@type boolean
local debug_enabled = false

---@return NeoTreeWindowState
local function clone_state()
  return {
    open = state.open,
    position = state.position,
  }
end

---@param from NeoTreeWindowState
---@param to NeoTreeWindowState
---@param action string
local function emit(from, to, action)
  if debug_enabled then
    snapshots[#snapshots + 1] = {
      open = to.open,
      position = to.position,
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

---@param pos "left"|"right"|"float"|"current"
---@param action? string
function M.set_open(pos, action)
  local from = clone_state()
  state.open = true
  state.position = pos
  emit(from, clone_state(), action or "open")
end

---@param action? string
function M.set_closed(action)
  local from = clone_state()
  state.open = false
  state.position = nil
  emit(from, clone_state(), action or "close")
end

---@param cb fun(from: NeoTreeWindowState, to: NeoTreeWindowState, action: string)
function M.on_transition(cb)
  listeners[#listeners + 1] = cb
end

---@param enable boolean
function M.enable_debug(enable)
  debug_enabled = enable == true
end

---@return NeoTreeWindowState[]
function M.get_snapshots()
  return snapshots
end

function M.reset()
  state.open = false
  state.position = nil
  snapshots = {}
end

return M

