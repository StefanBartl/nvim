---@module 'custom'
-- Initialize modules for 'custom'

pcall(function()
  require "custom.ctrl_cycle" -- AUDIT:
end)

pcall(function()
  require("pathprobe").setup_keymaps()
end)
