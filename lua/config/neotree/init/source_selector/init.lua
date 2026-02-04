---@module 'config.neotree.init.source_selector'

local ICONS = require("config.neotree.sources.icons")

-- Configuration knobs
local icon_family = "nerd" -- common | nerd | codicons
local icon_variant = "v1" -- v1 | v2
local name_length = "long" -- long | short

return {
  {
    source = "filesystem",
    display_name = ICONS.format(icon_family, icon_variant, "filesystem", name_length),
  },
  {
    source = "buffers",
    display_name = ICONS.format(icon_family, icon_variant, "buffers", name_length),
  },
  {
    source = "git_status",
    display_name = ICONS.format(icon_family, icon_variant, "git_status", name_length),
  },
  {
    source = "document_symbols",
    display_name = ICONS.format(icon_family, icon_variant, "document_symbols", name_length),
  },
  {
    source = "diagnostics",
    display_name = ICONS.format(icon_family, icon_variant, "diagnostics", name_length),
  },
  {
    source = "tests",
    display_name = ICONS.format(icon_family, icon_variant, "tests", name_length),
  },
}
