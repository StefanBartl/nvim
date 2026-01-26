---@module 'config.neotree.keymaps.filesystem.search'
--- Grep and search integrations.

local grep_picker = require("config.neotree.actions.grep_picker")

---@type table<string, any>
return {
  ["gr"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      grep_picker.live_grep(state)
    end,
    desc = "Live grep in node directory (auto)",
  },

  ["<leader>gt"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      grep_picker.live_grep(state, "telescope")
    end,
    desc = "Live grep (telescope)",
  },

  ["<leader>gf"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      grep_picker.live_grep(state, "fzf")
    end,
    desc = "Live grep (fzf-lua)",
  },
}
