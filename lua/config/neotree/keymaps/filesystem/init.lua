---@module 'config.neotree.keymaps.filesystem'
--- Entry point that merges all filesystem keymap modules into a single mapping table.

local modules = {
  require("config.neotree.keymaps.filesystem.filter"),
  require("config.neotree.keymaps.filesystem.commands"),
  require("config.neotree.keymaps.filesystem.files"),
  require("config.neotree.keymaps.filesystem.save"),
  require("config.neotree.keymaps.filesystem.preview"),
  require("config.neotree.keymaps.filesystem.replace"),
  require("config.neotree.keymaps.filesystem.clipboard"),
  require("config.neotree.keymaps.filesystem.create"),
  require("config.neotree.keymaps.filesystem.trash"),
  require("config.neotree.keymaps.filesystem.mark"),
  require("config.neotree.keymaps.filesystem.navigation"),
  require("config.neotree.keymaps.filesystem.path"),
  require("config.neotree.keymaps.filesystem.info"),
  require("config.neotree.keymaps.filesystem.search"),
}

---@type table<string, any>
local mappings = {}

-- Merge all sub-modules into a single mapping table.
for _, mod in ipairs(modules) do
  for key, value in pairs(mod) do
    mappings[key] = value
  end
end

return mappings
