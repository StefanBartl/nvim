---@module 'config.neotree.checkhealth.features'
---@brief Optional feature health checks

local M = {}

function M.check()
  vim.health.start("Optional Features")

  -- Trash system
  local ok_trash, trash = pcall(require, "config.neotree.trash")
  if ok_trash then
    vim.health.ok("Trash system loaded")

    if trash.config then
      vim.health.info("Trash configuration:")
      vim.health.info("  use_safety_system: " .. tostring(trash.config.use_safety_system))
      vim.health.info("  create_backups: " .. tostring(trash.config.create_backups))
    end
  else
    vim.health.warn("Trash system not loaded (optional)")
  end

  -- Current highlight
  local ok_hl = pcall(require, "config.neotree.current_hl")
  if ok_hl then
    vim.health.ok("Current highlight loaded")
  else
    vim.health.warn("Current highlight not loaded (optional)")
  end

  -- Watcher quarantine
  local ok_watcher, watcher = pcall(require, "config.neotree.watcher_quarantine")
  if ok_watcher then
    vim.health.ok("Watcher quarantine loaded")

    if watcher.health_check then
      local healthy, reason = watcher.health_check()
      if healthy then
        vim.health.ok("Watcher system healthy")
      else
        vim.health.warn("Watcher system issue: " .. (reason or "unknown"))
      end
    end
  else
    vim.health.warn("Watcher quarantine not loaded (optional)")
  end
end

return M

