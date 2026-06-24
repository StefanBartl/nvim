---@module 'custom'
-- Initialize modules for 'custom'

require("custom.open").setup()
require("custom.format").setup({
  enable_legacy_commands = true,
})
require("custom.mynotes")
local line_marker = require("wkdoptions.ui.line_marker")
line_marker.enable_commands()
line_marker.enable_mappings()
