---@module 'config.neotree.open.keymaps.reveal_current_file'

local map = require("lib.map")

local M = {}

---@return nil
function M.attach()
  map("n", "C", function()
    local ok, NeoCmd = pcall(require, "neo-tree.command")
    if ok then
      require("config.neotree.open.reveal.controller").reveal_current(NeoCmd)
    end
  end, { desc = "[Neo-tree] Reveal current file" })
end

return M

