---@module 'config.neotree.checkhealth.features'
---@brief Optional feature health checks

local M = {}

function M.check()
  vim.health.start("Optional Features")

  -- Trash/undo and current_hl were removed: filetree.nvim's `trash` and
  -- `current_hl` features own both now (see keymaps/filesystem/init.lua's
  -- header comment and plugins/personal/init.lua's filetree.nvim setup).

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

