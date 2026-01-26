---@module 'config.neotree.keymaps.filesystem.trash'
--- Trash and undo-trash mappings.

local trash = require("config.neotree.trash")
local undo = require("config.neotree.undo")

---@type table<string, any>
return {
  ["d"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      trash.neotree_send_node_to_trash(state)
    end,
    desc = "Delete marked files or file under cursor",
  },

  ["U"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      undo.neotree_undo_trash(state)
    end,
    desc = "Undo last trash",
  },

  ["<leader>th"] = {
    function()
      undo.show_history()
    end,
    desc = "Show trash history",
  },
}
