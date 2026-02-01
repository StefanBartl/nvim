---@module 'config.neotree.checkhealth'
---@brief Aggregated health checks for Neo-tree configuration

local M = {}

---Run all health checks
function M.check()
  -- Core modules
  require("config.neotree.checkhealth.core").check()

  -- State management
  require("config.neotree.checkhealth.state").check()

  -- Window controller
  require("config.neotree.checkhealth.open_window").check()

  -- Actions
  require("config.neotree.checkhealth.actions").check()

  -- Optional features
  require("config.neotree.checkhealth.features").check()

  -- Utilities
  require("config.neotree.checkhealth.utils").check()

  -- Integration tests
  require("config.neotree.checkhealth.integration").check()

  -- Watcher Quaeantine & FS Patch
  require("config.neotree.watcher_quarantine.health").check()
end

return M
