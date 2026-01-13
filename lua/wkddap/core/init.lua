---@module 'wkddap.core'

local M = {}

function M.setup(opts)
  local ok_setup, setup = pcall(require, "wkddap.core.setup")
  if not ok_setup then
    return false
  end

  return setup.setup(opts)
end

return M

