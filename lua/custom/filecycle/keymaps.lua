---@module 'custom.filecycle.keymaps'
require("lua.custom.filecycle.@types")

local map = require("lib.map")

local M = {}

function M.attach()
  map({ "n", "i" }, "<leader>nf", function()
    require("usrcmds.filecycle").open("next")
  end, { desc = "[filecycle] Next file" })
  map({ "n", "i" }, "<leader>pf", function()
    require("usrcmds.filecycle").open("prev")
  end, { desc = "[filecycle] Previous file" })
end

return M
