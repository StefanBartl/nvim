---@module 'config.neotree.keymaps.filesystem.replace'
--- Replace current buffer with file from node

local node_replace_buf = require("config.neotree.actions.node_replace_buf")

---@type table<string, any>
return {
  ["O"] = {
    function(state)
      node_replace_buf(state, { focus = true, auto_close = true })
    end,
    desc = "Open file and replace current buffer",
  },
}

