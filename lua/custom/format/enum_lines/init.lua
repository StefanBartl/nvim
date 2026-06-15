---@module 'custom.format.enum_lines'
---@brief Public entry-point for the enum_lines sub-module.
---@description
--- Thin facade over `custom.format.enum_lines.core`.
--- The `:Format enum` subcommand is wired up inside `custom.format.init`
--- via `setup_enum_lines()`.
---
--- Direct programmatic use:
---   local enum = require("custom.format.enum_lines")
---   enum.core.enum_selection({ style = "alpha" })
---   enum.core.enum_range(0, 3, 7, { style = "roman", inline = false })

---@class custom.format.enum_lines
local M = {}

M.core = require("custom.format.enum_lines.core")

return M
