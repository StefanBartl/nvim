---@module 'custom'
-- Initialize modules for 'custom'

---AUDIT:
require("custom.diff").enable({
  diff_exit = true,
  diff_origin = true,
  diff = true,
})
require("custom.open").setup()
require("custom.format").setup({
  enable_legacy_commands = true,
})
require("custom.mynotes")
-- AUDIT:
local line_marker = require("custom.line_marker")
line_marker.enable_commands()
line_marker.enable_mappings()
