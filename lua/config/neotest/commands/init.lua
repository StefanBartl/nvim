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
local notify = require("lib.notify").create("[plugins.neotest]")

local M = {}

local create = vim.api.nvim_create_user_command

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

  -- FIX: entweder nach actions oder command modules
  local ok, neotest = pcall(require, "neotest")
  if not ok then
    vim.notify("Neotest not loaded", vim.log.levels.ERROR)
    return
  end

    vim.api.nvim_create_user_command("NeotestDebugAdapters", function()
    local config = neotest.config
    if not config or not config.adapters then
      notify.warn("No adapters configured")
      return
    end

    local lines = { "=== Neotest Adapters ===" }
    for i, adapter in ipairs(config.adapters) do
      local name = type(adapter) == "table" and adapter.name or tostring(adapter)
      table.insert(lines, string.format("[%d] %s", i, name))
    end

    notify.info(table.concat(lines, "\n"))
  end, {})

  vim.api.nvim_create_user_command("NeotestDebugTree", function()
    local tree = neotest.state.positions()
    if not tree then
      notify.warn("No test tree available")
      return
    end

    -- Dump tree structure
    local lines = { "=== Test Tree ===" }
    local function dump(node, indent)
      indent = indent or 0
      local prefix = string.rep("  ", indent)
      table.insert(lines, prefix .. "- " .. (node.name or "?"))
      if node.children then
        for _, child in ipairs(node.children) do
          dump(child, indent + 1)
        end
      end
    end
    dump(tree)

    notify.info(table.concat(lines, "\n"))
  end, {})
end

return M
