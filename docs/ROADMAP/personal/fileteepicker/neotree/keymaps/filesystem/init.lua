---@module 'config.neotree.keymaps.filesystem'
--- Entry point that merges all filesystem keymap modules into a single mapping table.
---
--- Merge priority for <Tab> and <CR> (later entry wins):
---   preview -> images -> pdfport
---   plain toggle_preview < system app for images < pdfport for PDFs

local modules = {
  require("config.neotree.keymaps.filesystem.filter"),
  require("config.neotree.keymaps.filesystem.commands"),
  require("config.neotree.keymaps.filesystem.files"),
  require("config.neotree.keymaps.filesystem.save"),
  require("config.neotree.keymaps.filesystem.replace"),
  require("config.neotree.keymaps.filesystem.clipboard"),
  require("config.neotree.keymaps.filesystem.create"),
  require("config.neotree.keymaps.filesystem.trash"),
  require("config.neotree.keymaps.filesystem.mark"),
  require("config.neotree.keymaps.filesystem.navigation"),
  require("config.neotree.keymaps.filesystem.path"),
  require("config.neotree.keymaps.filesystem.info"),
  require("config.neotree.keymaps.filesystem.search"),
  -- TODO: Vereinen von preview;images;pdfprot
  require("config.neotree.keymaps.filesystem.preview"), -- <Tab> scroll + toggle fallback
  require("config.neotree.keymaps.filesystem.images"),  -- <Tab>/<CR> image -> system app  (must come AFTER preview)
  require("config.neotree.keymaps.filesystem.pdfport"), -- <Tab>/<CR> PDF  -> pdfport       (must come AFTER images)
}

---@type table<string, any>
local mappings = {}

for _, mod in ipairs(modules) do
  for key, value in pairs(mod) do
    mappings[key] = value
  end
end

return mappings
