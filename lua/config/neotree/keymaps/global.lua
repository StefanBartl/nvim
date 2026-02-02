---@module 'config.neotree.keymaps.global'
---@brief Global Neo-tree keymaps (outside Neo-tree windows)

local map = require("lib.map")

local M = {}

---Attach global Neo-tree keymaps
---@return nil
function M.attach()
  -- Source switcher
  map("n", "<leader>ns", function()
    require("config.neotree.sources.switcher").show_picker()
  end, { desc = "[Neo-tree] Switch Source" })
end

return M
