---@module 'config.neotree.reveal.controller'
---@brief Explicit reveal logic independent from window lifecycle

local M = {}

---@param NeoCmd table
function M.reveal_current(NeoCmd)
  NeoCmd.execute({
    source = "filesystem",
    action = "focus",
    reveal = true,
  })
end

return M

