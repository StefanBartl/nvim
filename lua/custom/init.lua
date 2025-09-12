---@module 'custom'
---@brief Registry for 'custom' module

require "custom.last_file.init"
require "custom.ctrl_cycle"
require("custom.smart_edit").setup({ set_cr = true })
