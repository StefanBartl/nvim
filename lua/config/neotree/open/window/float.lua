---@module 'config.neotree.open.window.float'
---@brief Neo-tree float strategy with state tracking

local buffer_utils = require("config.neotree.utils.buffer")

local M = {}

---@type {open: boolean, last_toggle: number}
local float_state = {
  open = false,
  last_toggle = 0,
}

---Toggle float with anti-bounce protection
---@param NeoCmd table
function M.toggle(NeoCmd)
  local now = vim.loop.now()

  -- Anti-bounce: Min 100ms between toggles
  if now - float_state.last_toggle < 100 then
    return
  end

  float_state.last_toggle = now
  float_state.open = not float_state.open

  local ctx = buffer_utils.get_buffer_context()

  -- Use explicit show/close instead of toggle
  if float_state.open then
    NeoCmd.execute({
      source = "filesystem",
      action = "show",
      position = "float",
      toggle = false,
      reveal = true,
      reveal_file = ctx and ctx.file or nil,
      dir = ctx and ctx.dir or nil,
    })
  else
    NeoCmd.execute({
      source = "filesystem",
      action = "close",
    })
  end
end

---Get float state
---@return {open: boolean, last_toggle: number}
function M.get_state()
  return vim.deepcopy(float_state)
end

---Reset float state
function M.reset()
  float_state.open = false
  float_state.last_toggle = 0
end

return M
