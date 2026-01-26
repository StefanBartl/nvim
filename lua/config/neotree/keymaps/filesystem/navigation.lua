---@module 'config.neotree.keymaps.filesystem.navigation'
--- Directory traversal and root navigation.

local traverse = require("config.neotree.actions.traverse")

---@type table<string, any>
return {
  ["+"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      traverse.down(state)
    end,
    desc = "Navigate into directory and set as root",
  },

  ["-"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      traverse.up(state)
    end,
    desc = "Navigate up one level",
  },
}
