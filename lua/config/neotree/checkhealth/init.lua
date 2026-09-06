---@module 'config.neotree.checkhealth'
---@brief Aggregated health checks for Neo-tree configuration

local M = {}

---Run all health checks
function M.check()
  -- Core modules
  require("config.neotree.checkhealth.core").check()

  -- (Action module checks removed: filetree.nvim owns all actions now;
  -- config.neotree has no action modules of its own left.)

  -- Optional features
  require("config.neotree.checkhealth.features").check()

  -- Utilities
  require("config.neotree.checkhealth.utils").check()
end

return M
