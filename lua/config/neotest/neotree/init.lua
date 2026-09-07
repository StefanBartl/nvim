---@module 'config.neotest.neotree'
--- Neo-tree integration for Neotest actions.
--
--[[
 Wiring into Neo-tree:
 local neotest_neotree = require("config.neotest.neotree")

 require("neo-tree").setup({
   filesystem = {
     window = {
       mappings = neotest_neotree.keymaps(),
     },
   },
   commands = neotest_neotree.commands(),
 })

 NOTE: must be merged with Neo-tree's own filesystem mappings/commands,
 not passed as-is (this only returns the tests-source additions).
]]
--

local actions = require("config.neotest.actions")

local M = {}

--- Neo-tree command definitions, registered into opts.commands
---@return table<string, function>
function M.commands()
  return {
    neotest_run_nearest = function(_)
      actions.run_nearest()
    end,
    neotest_run_file = function(_)
      actions.run_file()
    end,
    neotest_run_all = function(_)
      actions.run_all()
    end,
    neotest_debug = function(_)
      actions.debug_nearest()
    end,
    neotest_summary = function(_)
      actions.toggle_summary()
    end,
    neotest_output = function(_)
      actions.open_output()
    end,
    neotest_refresh = function(state)
      require("neo-tree.sources.tests").navigate(state)
    end,
  }
end

--- Neo-tree window mappings, used in source.window.mappings
---@return table<string, string>
function M.keymaps()
  return {
    ["T"] = "neotest_run_nearest",
    ["F"] = "neotest_run_file",
    ["A"] = "neotest_run_all",
    ["D"] = "neotest_debug",
    ["S"] = "neotest_summary",
    ["O"] = "neotest_output",
    ["R"] = "neotest_refresh",
  }
end

return M
