---@module 'custom.utils.toggle_transparency'

local M = {}

function M.toggle()
  local ok, base46 = pcall(require, "base46")
  if ok and base46 and base46.toggle_transparency then
    base46.toggle_transparency()
  end
end

return M

