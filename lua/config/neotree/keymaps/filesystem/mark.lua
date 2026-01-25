---@module 'config.neotree.keymaps.filesystem.mark'
--- Mark and unmark operations.

local commands = require("config.neotree.commands")

---@type table<string, any>
return {
  ["m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.toggle_mark(state, false)
    end,
    desc = "Mark/Unmark single file",
  },

  ["]m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.mark_all_in_directory(state)
    end,
    desc = "Mark all files in directory",
  },

  ["[m"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.mark.unmark_all_in_directory(state)
    end,
    desc = "Unmark all files in directory",
  },
}
