---@module 'config.neotree.checkhealth.open_window'
---@brief Health checks for neo-tree window controller

local M = {}

function M.check()
  vim.health.start("Neo-tree window controller")

  local ok = pcall(require, "config.neotree.open.window.controller")
  if ok then
    vim.health.ok("window controller loaded")
  else
    vim.health.error("window controller not loadable")
  end
end

return M

