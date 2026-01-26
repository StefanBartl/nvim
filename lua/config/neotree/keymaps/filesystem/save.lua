---@module 'config.neotree.keymaps.filesystem.save'
--- Save-related mappings for filesystem buffers.

local save_node_buffer = require("config.neotree.actions.save.node_buffer")
local save_adjacent_buffer = require("config.neotree.actions.save.adjacent_buffer")

---@type table<string, any>
return {
  ["<C-s>"] = {
    function()
      save_adjacent_buffer()
    end,
    desc = "Force-save last normal buffer (w!)",
  },

  ["<M-s>"] = {
    function()
      save_node_buffer()
    end,
    desc = "Force-save buffer matching node under cursor (w!)",
  },
}
