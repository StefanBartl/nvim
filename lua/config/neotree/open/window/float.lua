---@module 'config.neotree.open.window.float'
---@brief Neo-tree float strategy (toggle-based, required)

local buffer_utils = require("config.neotree.utils.buffer")

local M = {}

---@param NeoCmd table
function M.toggle(NeoCmd)
  local ctx = buffer_utils.get_buffer_context()

  NeoCmd.execute({
    source = "filesystem",
    toggle = true,
    position = "float",
    reveal = true,
    reveal_file = ctx and ctx.file or nil,
    dir = ctx and ctx.dir or nil,
  })
end

return M

