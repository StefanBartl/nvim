---@module 'config.neotest.neotree'
--- Neo-tree integration for Neotest actions.

--[[
 Einbindung in Neo-tree
 local neotest_neotree = require("config.neotest.neotree")

 require("neo-tree").setup({
   filesystem = {
     window = {
       mappings = neotest_neotree.keymaps(),
     },
   },
   commands = neotest_neotree.commands(),
 })

ACHTUNG: Merge mit Neotree filesysten mappings und commands notwendig!
]]
--
---@module 'config.neotest.neotree'
--- Neo-tree integration for Neotest actions.

local actions = require("config.neotest.actions")

local M = {}

--- Neo-tree command definitions
--- Diese werden in opts.commands registriert
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

--- Neo-tree window mappings
--- Diese werden in source.window.mappings verwendet
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
