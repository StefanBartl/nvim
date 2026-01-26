---@module 'config.neotree.keymaps.filesystem.create'

local commands = require("config.neotree.commands")

---@type table<string, any>
return {
  -- ["a"] = { "add", nowait = true, config = { show_path = "relative" } },
  ["a"] = { "custom_add", nowait = true, config = { insert_clipb = true } }, -- { insert_clipb = true } möglich (ohne confirmation)
  ["D"] = {
    ---@param state Cfg.NeoTree.State
    function(state)
      commands.diff_files(state)
    end,
    desc = "Diff files (mark two files, then trigger)",
  },
  ["r"] = "rename",
}
