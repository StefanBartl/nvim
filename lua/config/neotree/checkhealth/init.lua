---@module 'config.neotree.checkhealth'
---@brief Aggregated health checks for Neo-tree configuration

local M = {}

---Run all health checks
function M.check()
  -- Core modules
  require("config.neotree.checkhealth.core").check()

  -- (Action-Modul-Checks entfernt: filetree.nvim besitzt sämtliche Actions;
  -- config.neotree hat keine eigenen Action-Module mehr.)

  -- Optional features
  require("config.neotree.checkhealth.features").check()

  -- Utilities
  require("config.neotree.checkhealth.utils").check()

  -- Watcher Quaeantine & FS Patch
  require("config.neotree.watcher_quarantine.health").check()
end

return M
