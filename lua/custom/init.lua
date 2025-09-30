---@module 'custom'
-- Initialize modules for 'custom'

require("custom.find_config").enable({ usercmds = true, keymaps = true  })
require("custom.pathprobe").enable_keymaps()
require("custom.usr_pickers").enable({}, { usercmds = true, keymaps = true })
