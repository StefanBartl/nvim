---@module 'config.neotree.keymaps.filesystem.clipboard'

local clipboard = require("config.neotree.commands.clipboard")

---@type table<string, any>
return {
  ["c"] = {
    function(state)
      clipboard.copy_to_clipboard(state)
    end,
    desc = "Copy marked/current nodes to clipboard",
  },

  ["x"] = {
    function(state)
      clipboard.cut_to_clipboard(state)
    end,
    desc = "Cut marked/current nodes to clipboard",
  },

  ["p"] = {
    function(state)
      clipboard.paste_from_clipboard(state)
    end,
    desc = "Paste from clipboard to current directory",
  },

  ["<C-c>"] = {
    function(state)
      -- Clear clipboard
      state.clipboard = nil
      require("lib.notify").create("[clipboard]").info("Clipboard cleared")
    end,
    desc = "Clear clipboard",
  },
}
