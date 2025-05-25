---@module 'custom.mygrep.core.undo'
---@class UndoManager
---@brief Handles undo stack operations for tool-specific memory state.
---@description
--- This module provides session-local undo functionality. It allows one to push
--- reversible actions (like deletion or unfavoriting), and re-apply them on demand.
--- The undo stack is part of each tool's ToolState object and is not persisted.

---@field push fun(state: ToolState, action: '"delete"'|'"unfavorite"', value: string): nil Adds an action to the undo stack
---@field apply fun(state: ToolState): boolean Attempts to apply the most recent undo action

local M = {}

--- Pushes an action to the undo stack
---@param state ToolState
---@param action '"delete"'|'"unfavorite"'
---@param value string
---@return nil
function M.push(state, action, value)
  assert(type(state) == "table", "invalid state table")
  assert(action == "delete" or action == "unfavorite", "invalid undo action")
  assert(type(value) == "string" and value ~= "", "invalid undo value")

  state.undo = state.undo or {}

  table.insert(state.undo, {
    action = action,
    value = value,
  })
end

--- Applies the most recent undo action.
--- @param state ToolState
--- @return boolean success Whether an undo action was applied
function M.apply(state)
  assert(type(state) == "table", "invalid state table")

  local entry = table.remove(state.undo)
  if not entry then
    vim.notify("Nothing to undo", vim.log.levels.INFO)
    return false
  end

  if entry.action == "delete" then
    if not vim.tbl_contains(state.history, entry.value) then
      table.insert(state.history, entry.value)
    end
  elseif entry.action == "unfavorite" then
    if not vim.tbl_contains(state.favorites, entry.value) then
      table.insert(state.favorites, entry.value)
    end
  else
    vim.notify("[undo] Unknown action: " .. tostring(entry.action), vim.log.levels.ERROR)
    return false
  end

  return true
end

return M