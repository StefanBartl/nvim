---@module 'lib.nvim'

local lazy = require("lib.lazy")

local M = {}

M.simple_echo = lazy.require("lib.nvim.simple_echo")

---@type Lib.Nvim
return M
