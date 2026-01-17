---@module 'config.neotree.open.filemanager'
---@brief Cross-platform file manager opener dispatcher

local M = {}

local is_wsl = require("lib.cross.plattform.is_wsl")
local platform = require("config.neotree.utils.platform")
local notify = require("lib.notify").create("[neotree.open.filemanager]")

---Open selected node in file manager
---@param state Cfg.NeoTree.State
---@return boolean success
function M.open_from_neotree(state)
  local mod_name

  if platform.is_windows() then
    mod_name = "config.neotree.open.filemanager.win"
  elseif is_wsl() then
    mod_name = "config.neotree.open.filemanager.wsl"
  else
    mod_name = "config.neotree.open.filemanager.unix_ubuntu"
  end

  local ok, fm = pcall(require, mod_name)
  if not ok then
    notify.error(string.format("File manager module not found: %s", mod_name))
    return false
  end

  -- Call the open function
  local success = fm.open(state)

  -- if success then
    -- notify.info("Opened in file manager")
  -- end

  return success
end

return M
