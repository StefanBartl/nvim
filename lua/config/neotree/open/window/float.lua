---@module 'config.neotree.open.window.float'
---@brief Neo-tree float strategy with external state synchronization

local M = {}

---@type {open: boolean, last_action: number}
local float_state = {
  open = false,
  last_action = 0,
}

---Set open state (called by executor)
---@param is_open boolean
function M.set_open_state(is_open)
  float_state.open = is_open
  float_state.last_action = vim.loop.now()
end

---Get float state
---@return {open: boolean, last_action: number}
function M.get_state()
  return vim.deepcopy(float_state)
end

---Reset float state
function M.reset()
  float_state.open = false
  float_state.last_action = 0
end

---Check if float is open (for debugging)
---@return boolean
function M.is_open()
  return float_state.open
end

return M
