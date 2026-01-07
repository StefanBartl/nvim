---@module 'config.neotest.neotree'
--- Neo-tree integration for Neotest actions.

--[[ FIX: Einbinden in neotree (merge mit filesystem mappings)
 Einbindung in Neo-tree
 local neotest_neotree = require("config.neotest.neotree")

 require("neo-tree").setup({
   filesystem = {
     window = {
       mappings = neotest_neotree.mappings(),
     },
   },
   commands = neotest_neotree.commands(),
 })
]]--

local actions = require("config.neotest.actions")

local M = {}

--- Neo-tree command definitions
---@return table<string, table>
function M.commands()
  return {
    neotest_run_nearest = {
      text = "Run nearest test",
      callback = actions.run_nearest,
    },
    neotest_run_file = {
      text = "Run file tests",
      callback = actions.run_file,
    },
    neotest_run_all = {
      text = "Run all tests",
      callback = actions.run_all,
    },
    neotest_debug = {
      text = "Debug nearest test",
      callback = actions.debug_nearest,
    },
    neotest_summary = {
      text = "Toggle summary",
      callback = actions.toggle_summary,
    },
    neotest_output = {
      text = "Show output",
      callback = actions.open_output,
    },
  }
end

--- Neo-tree menu mapping
---@return table[]
function M.mappings()
  return {
    {
      key = "T",
      command = "neotest_run_nearest",
    },
    {
      key = "F",
      command = "neotest_run_file",
    },
    {
      key = "A",
      command = "neotest_run_all",
    },
    {
      key = "D",
      command = "neotest_debug",
    },
  }
end

return M

