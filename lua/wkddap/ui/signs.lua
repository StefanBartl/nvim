---@module 'wkddap.ui.signs'

local config = require("dap.config")

local M = {}

function M.setup()
  for name, sign in pairs(config.signs) do
    vim.fn.sign_define(name, sign)
  end
end

return M
