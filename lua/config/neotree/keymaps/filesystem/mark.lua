---@module 'config.neotree.keymaps.filesystem.mark'
--- Mark and unmark operations.

---@type table<string, any>
return {
  ["m"] = {
    function(state)
      require("config.neotree.commands").mark.toggle_mark(state, false)
    end,
    desc = "Mark/Unmark single file",
  },

  ["]m"] = {
    function(state)
      require("config.neotree.commands").mark.mark_all_in_directory(state)
    end,
    desc = "Mark all files in directory",
  },

  ["[m"] = {
    function(state)
      require("config.neotree.commands").mark.unmark_all_in_directory(state)
    end,
    desc = "Unmark all files in directory",
  },

  ["<C-m>"] = {
    function(state)
      require("config.neotree.commands").mark.clear_all_marks(state)
    end,
    desc = "Clear all marks",
  },

  ["<leader>ms"] = {
    function(state)
      require("config.neotree.commands").mark.show_marked_nodes(state)
    end,
    desc = "Show marked nodes",
  },
}
