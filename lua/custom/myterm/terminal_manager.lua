---@module 'myterm.terminal_manager'
---@brief Terminal creation and visibility control
---@description
--- Responsible for creating terminal instances in various layouts (float, horizontal, vertical).
--- Manages opening logic, buffer association and visibility toggling of active terminals.

---@class UndoEntry
---@field id string
---@field data string[]
local M = {}

-- Internal State and Label Renderer
local state = require("custom.myterm.state")
local label = require("custom.myterm.label")

--- Creates a floating terminal in the center of the screen
---@return integer|nil id Terminal ID or nil on failure
local function open_floating()
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_set_current_buf(buf)

  local ok = pcall(vim.fn.termopen, os.getenv("SHELL") or "bash", {
    on_exit = function(_, _, _) end,
  })
  if not ok then
    vim.notify("[myterm] Failed to start terminal process", vim.log.levels.ERROR)
    return nil
  end

  vim.cmd("startinsert")
  local job_id = vim.bo[buf].channel

  local id = state.add_terminal(buf, win, job_id, "float")
  local term = state.get(id)
  if not term then
    return id
  end
  label.apply(term)

  return id
end

--- Creates a terminal in a horizontal or vertical split
---@param direction "horizontal"|"vertical"
---@return integer|nil id Terminal ID or nil on failure
local function open_split(direction)
  assert(direction == "horizontal" or direction == "vertical", "Invalid split direction")

  local buf = vim.api.nvim_create_buf(false, true)

  if direction == "horizontal" then
    vim.cmd("split")
    vim.api.nvim_win_set_height(0, 10)
  else
    vim.cmd("vsplit")
    vim.api.nvim_win_set_width(0, 80)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  local ok = pcall(vim.fn.termopen, os.getenv("SHELL") or "bash", {
    on_exit = function(_, _, _) end,
  })
  if not ok then
    vim.notify("[myterm] Failed to start terminal process", vim.log.levels.ERROR)
    return nil
  end

  vim.cmd("startinsert")
  local job_id = vim.bo[buf].channel

  local id = state.add_terminal(buf, win, job_id, direction)
  local term = state.get(id)
  if not term then
    return id
  end
  label.apply(term)

  return id
end

--- Opens a new terminal with the specified layout
---@param mode "float"|"horizontal"|"vertical"
---@return integer|nil id Terminal ID or nil on failure
function M.new_terminal(mode)
  assert(mode ~= nil and type(mode) == "string", "mode must be a string")

  if mode == "float" then
    return open_floating()
  elseif mode == "horizontal" or mode == "vertical" then
    ---@cast mode "horizontal"|"vertical"
    return open_split(mode)
  else
    vim.notify("[myterm] Invalid terminal mode: " .. tostring(mode), vim.log.levels.ERROR)
    return nil
  end
end

--- Hides the currently focused terminal (if visible)
---@return boolean success
function M.minimize()
  local term = state.get_last_focused()
  if term and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_hide(term.win)
    print("Terminal " .. term.id .. " minimized")
    return true
  end
  return false
end

return M
