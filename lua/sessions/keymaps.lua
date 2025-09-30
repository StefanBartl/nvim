---@module 'sessions/keympas'
---@brief Keymaps for portable sessions

local M = {}
local map = require("lib.map")

---@return nil
function M.enable()
	map("n", "<leader>ssa", function() vim.cmd("SessionSave") end, { desc = "Session Save" })
  map("n", "<leader>slo", function() vim.cmd("SessionLoad") end, { desc = "Session Load" })
  map("n", "<leader>sst", function()
    local stamp = os.date("sess-%Y%m%d-%H%M%S")
    vim.cmd("SessionSave " .. stamp)
  end, { desc = "Session Save (timestamp)" })
  map("n", "<leader>sli", function() vim.cmd("SessionList") end, { desc = "Session List" }	)
end

return M

