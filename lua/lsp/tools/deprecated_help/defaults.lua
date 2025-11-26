---@module 'lsp.tools.deprecated_help.defaults'

local M = {}

-- Default mapping (can be overridden via setup opts)
---@type string
M.keymap = "<leader>oh" -- open help for last detected symbol in the current buffer

return M
