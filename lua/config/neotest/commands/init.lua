---@module 'config.neotest.commands'
--- User commands for Neotest based on shared actions.
--
--[[
-- Usercommands:
--  :NeotestActions
--  :NeotestRunNearest
--  :NeotestRunFile
--  :NeotestRunAll
--  :NeotestDebugNearest
--  :NeotestSummaryToggle
--  :NeotestOutput
--  :NeotestOutputPanelToggle
--  :NeotestStop
--  :NeotestWatchToggle
]]
--

local actions = require("config.neotest.actions")

local M = {}

local create = require("lib.nvim.bindings.usercmd").create

function M.setup()
  create("NeotestActions", function()
    require("config.neotest.telescope").open()
  end, { desc = "Open Neotest actions picker" })

  create("NeotestRunNearest", actions.run_nearest, {
    desc = "Run nearest test",
  })

  create("NeotestRunFile", actions.run_file, {
    desc = "Run all tests in current file",
  })

  create("NeotestRunAll", actions.run_all, {
    desc = "Run all tests in project",
  })

  create("NeotestDebugNearest", actions.debug_nearest, {
    desc = "Debug nearest test using DAP",
  })

  create("NeotestSummaryToggle", actions.toggle_summary, {
    desc = "Toggle Neotest summary",
  })

  create("NeotestOutput", actions.open_output, {
    desc = "Open Neotest output",
  })

  create("NeotestOutputPanelToggle", actions.toggle_output_panel, {
    desc = "Toggle Neotest output panel",
  })

  create("NeotestStop", actions.stop, {
    desc = "Stop running tests",
  })

  create("NeotestWatchToggle", actions.toggle_watch, {
    desc = "Toggle Neotest watch mode",
  })

  create("NeotestClearAll", function()
    local neotest = require("neotest")
    neotest.run.stop()
    neotest.output.close()
    neotest.summary.close()
end, { desc = "Stop tests and close all windows" })
end

return M
