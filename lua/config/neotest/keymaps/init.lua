---@module 'config.neotest.keymaps'
--- Neotest keymaps using centralized actions.

local map = require("lib.nvim.map")
local actions = require("config.neotest.actions")
local notify = require("lib.nvim.notify").create("[plugins.neotest]")

local M = {}

-- FIX: nach actions ausagliedern oder keymaps module
map("n", "<leader>ntr", function()
  local neotest = require("neotest")

  -- Clear all state
  if neotest.state then
    pcall(neotest.state.clear)
  end

  -- Force rediscover
  notify.info("Forcing test discovery...")

  vim.defer_fn(function()
    local tree = neotest.state.positions()
    if tree then
      notify.info("Tests found: " .. vim.tbl_count(tree))
    else
      notify.warn("No tests discovered")
    end
  end, 1000)
end, { desc = "Refresh test discovery" })

-- Debug adapter info
map("n", "<leader>ntD", function()
  local adapters = require("neotest").state.adapter_ids()
  local msg = "Loaded adapters:\n"
  for id, _ in pairs(adapters or {}) do
    msg = msg .. "  - " .. id .. "\n"
  end
  notify.info(msg)
end, { desc = "Show loaded adapters" })

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
