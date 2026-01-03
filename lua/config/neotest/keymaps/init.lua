---@module 'config.neotest.keymaps'
--- Neotest keymaps using centralized actions.

local map = require("lib.map")
local actions = require("config.neotest.actions")

local M = {}

---@type table[]
M.keymaps = {
  { "n", "<leader>ntt", actions.run_nearest, "Run nearest test" },
  { "n", "<leader>ntf", actions.run_file, "Run file tests" },
  { "n", "<leader>nta", actions.run_all, "Run all tests" },
  { "n", "<leader>ntd", actions.debug_nearest, "Debug nearest test" },
  { "n", "<leader>nts", actions.toggle_summary, "Toggle summary" },
  { "n", "<leader>nto", actions.open_output, "Show output" },
  { "n", "<leader>ntO", actions.toggle_output_panel, "Toggle output panel" },
  { "n", "<leader>ntS", actions.stop, "Stop test" },
  { "n", "<leader>ntw", actions.toggle_watch, "Toggle watch mode" },
}

function M.setup()
  for i = 1, #M.keymaps do
    local km = M.keymaps[i]
    map(km[1], km[2], km[3], nil, km[4])
  end
end

return M
