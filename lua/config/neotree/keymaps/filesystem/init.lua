---@module 'config.neotree.keymaps.filesystem'
--- Entry point that merges all filesystem keymap modules into a single mapping table.
---
--- Merge priority for <Tab> and <CR> (later entry wins):
---   preview -> images -> pdfport
---   plain toggle_preview < system app for images < pdfport for PDFs

-- Modules handled by filetree.nvim (removed):
--   filter, save, replace, mark, navigation, path, info, search,
--   preview, images, pdfport, trash
-- trash: d/U/<leader>th are now owned by filetree.nvim's trash feature
--   (batch chooser + reliable buffer-close). Keeping the old
--   config.neotree.keymaps.filesystem.trash in this merge bound `d` a second
--   time and raced filetree's own `d`, which is why buffer-close was
--   intermittent. See also `trash = false` passed to config.neotree.setup().
-- Remaining: neotree-native operations only.
local modules = {
  require("config.neotree.keymaps.filesystem.commands"),
  require("config.neotree.keymaps.filesystem.files"),
  require("config.neotree.keymaps.filesystem.clipboard"),
  require("config.neotree.keymaps.filesystem.create"),
}

---@type table<string, any>
local mappings = {}

for _, mod in ipairs(modules) do
  for key, value in pairs(mod) do
    mappings[key] = value
  end
end

return mappings
