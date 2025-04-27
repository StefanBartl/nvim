-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@class ChadrcConfig

local M = {}

require("custom.multigrep").setup()
require("custom.floatterminal")
require("custom.myterm")
require("custom.commands")

return M

