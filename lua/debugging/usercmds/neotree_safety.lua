---@module 'debugging.usercmds.neotree_safety'

local M = {}

---@return nil
function M.enable()
  vim.api.nvim_create_user_command("NeoTreeQuarantineStatus", function()
    local wq = require("config.neotree.watcher_quarantine")
    local in_q = wq.is_quarantined()
    local healthy, reason = wq.health_check()

    local msg = string.format(
      "Quarantine Status:\n  Active: %s\n  Watchers Healthy: %s%s",
      in_q and "YES" or "NO",
      healthy and "YES" or "NO",
      reason and ("\n  Reason: " .. reason) or ""
    )

    vim.notify(msg, vim.log.levels.INFO)
  end, { desc = "Check Neo-tree watcher quarantine status" })

  vim.api.nvim_create_user_command("NeoTreeQuarantineExit", function()
    local wq = require("config.neotree.watcher_quarantine")
    wq.exit_quarantine()
    vim.notify("Quarantine exited manually", vim.log.levels.INFO)
  end, { desc = "Manually exit Neo-tree watcher quarantine" })

  vim.api.nvim_create_user_command("NeoTreeRestartWatchers", function()
    local wq = require("config.neotree.watcher_quarantine")
    local ok, msg = wq.restart_watchers()
    if ok then
      vim.notify("Watchers restarted", vim.log.levels.INFO)
    else
      vim.notify("Failed to restart watchers: " .. (msg or "unknown"), vim.log.levels.WARN)
    end
  end, { desc = "Restart Neo-tree file watchers" })

  -- Backup commands
  vim.api.nvim_create_user_command("NeoTreeBackupList", function()
    local safety = require("config.neotree.safety")
    safety.backup.show_backup_ui()
  end, { desc = "Show Neo-tree backup UI" })

  vim.api.nvim_create_user_command("NeoTreeBackupClean", function()
    local safety = require("config.neotree.safety")
    local cleaned = safety.backup.clean_old_backups(7)
    vim.notify(string.format("Cleaned %d old backups", cleaned), vim.log.levels.INFO)
  end, { desc = "Clean old Neo-tree backups" })

  -- Dry-run commands
  vim.api.nvim_create_user_command("NeoTreeDryRunToggle", function()
    local safety = require("config.neotree.safety")
    safety.dry_run.toggle()
  end, { desc = "Toggle Neo-tree dry-run mode" })

  vim.api.nvim_create_user_command("NeoTreeDryRunReport", function()
    local safety = require("config.neotree.safety")
    safety.dry_run.show_report()
  end, { desc = "Show Neo-tree dry-run report" })

  -- Queue commands
  vim.api.nvim_create_user_command("NeoTreeQueueStatus", function()
    local safety = require("config.neotree.safety")
    local status = safety.queue.status()
    vim.notify(vim.inspect(status), vim.log.levels.INFO)
  end, { desc = "Show Neo-tree operation queue status" })

  vim.api.nvim_create_user_command("NeoTreeQueueClear", function()
    local safety = require("config.neotree.safety")
    safety.queue.clear()
    vim.notify("Queue cleared", vim.log.levels.INFO)
  end, { desc = "Clear Neo-tree operation queue" })
end

return M
