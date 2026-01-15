---@module 'config.neotree.open.window.controller'
---@brief Centralized Neo-tree window controller with deterministic state machine
---@description
--- Owns the Neo-tree window lifecycle and decides open / close / switch actions.
--- Float windows are handled via toggle=true by design.
--- The controller never reads Neo-tree internal state.

local buffer_utils = require("config.neotree.utils.buffer")
local state = require("config.neotree.state.windows")
local float = require("config.neotree.open.window.float")

local M = {}

---@enum NeoTreePosition
local PositionEnum = {
  left = "left",
  right = "right",
  float = "float",
  current = "current",
}

---@type table<string, true>
local valid_positions = {
  left = true,
  right = true,
  float = true,
  current = true,
}---@type boolean
local busy = false

---@param fn fun()
---@return fun()
local function guarded(fn)
  return function()
    if busy then
      return
    end

    busy = true
    fn()

    vim.defer_fn(function()
      busy = false
    end, 30)
  end
end




---@param pos string
---@return "left"|"right"|"float"|"current"
local function normalize_position(pos)
  if valid_positions[pos] then
    return pos
  end
  return PositionEnum.right
end

---@param target_position string
---@return "open"|"close"|"switch"
local function decide_action(target_position)
  if not state.is_open() then
    return "open"
  end

  if state.get_position() == target_position then
    return "close"
  end

  return "switch"
end

---@param NeoCmd table
---@param target_position "left"|"right"|"float"|"current"
local function open_window(NeoCmd, target_position)
  if target_position == "float" then
    float.toggle(NeoCmd)
    state.set_open("float")
    return
  end

  local ctx = buffer_utils.get_buffer_context()

  NeoCmd.execute({
    source = "filesystem",
    action = "show",
    position = target_position,
    reveal = true,
    reveal_file = ctx and ctx.file or nil,
    reveal_force_cwd = false,
    dir = ctx and ctx.dir or nil,
  })

  state.set_open(target_position)
end

---@param NeoCmd table
local function close_window(NeoCmd)
  if state.get_position() == "float" then
    float.toggle(NeoCmd)
    state.set_closed()
    return
  end

  NeoCmd.execute({
    source = "filesystem",
    action = "close",
  })

  if state.get_position() == "current" then
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.bo[bufnr].filetype == "neo-tree" then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
  end

  state.set_closed()
end

---@param NeoCmd table
---@param target_position "left"|"right"|"float"|"current"
local function switch_window(NeoCmd, target_position)
  close_window(NeoCmd)

  vim.defer_fn(function()
    open_window(NeoCmd, target_position)
  end, 20)
end

---@param target_position string
---@return fun()
function M.make_opener(target_position)
  local ok, NeoCmd = pcall(require, "neo-tree.command")
  if not ok then
    return function() end
  end

  local pos = normalize_position(target_position)

return guarded(function()
  local action = decide_action(pos)

  if action == "open" then
    open_window(NeoCmd, pos)
  elseif action == "close" then
    close_window(NeoCmd)
  else
    switch_window(NeoCmd, pos)
  end
end)
end

function M.get_state()
  return {
    open = state.is_open(),
    position = state.get_position(),
  }
end

return M

