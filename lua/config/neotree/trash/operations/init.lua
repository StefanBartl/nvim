---@module 'config.neotree.trash.operations'
---@brief Execute trash operations without re-confirmation

local notify = require("lib.nvim.notify").create("[trash.operations]")
local safety = require("config.neotree.safety")

local M = {}

local config = {}

---Set configuration
---@param cfg table
---@return nil
function M.set_config(cfg)
  config = cfg
end

---Create backups
---@param paths string[]
---@param names string[]
---@return table<string, string> backups
---@nodiscard
function M.create_backups(paths, names)
  local backups = {}

  for i = 1, #paths do
    local path = paths[i]
    local backup_path, err = safety.backup.create_backup(path, "trash")

    if backup_path then
      backups[path] = backup_path
      if config.debug then
        notify.info(("📦 Backup: %s"):format(backup_path))
      end
    else
      notify.warn(("Backup failed for %s: %s"):format(names[i], err or "unknown"))
    end
  end

  return backups
end

---Execute batch deletion (respects confirmation mode)
---@param paths string[]
---@param names string[]
---@param delete_mode "all"|"individual"
---@param send_fn fun(path: string, name: string): boolean, string
---@return table results
---@nodiscard
function M.execute_batch(paths, names, delete_mode, send_fn)
  local success_count = 0
  local cancelled_count = 0
  local failed_items = {}

  local confirmation = require("config.neotree.trash.confirmation")

  for i = 1, #paths do
    local path = paths[i]
    local name = names[i]

    -- Individual confirmation ONLY in "individual" mode
    if delete_mode == "individual" then
      if not confirmation.confirm_individual(name) then
        cancelled_count = cancelled_count + 1
        if config.debug then
          notify.info(("⏭ Skipped: %s"):format(name))
        end
        goto continue
      end
    end

    if config.debug then
      notify.info(("🗑 Processing: %s"):format(name))
    end

    -- Execute without asking again (already confirmed globally)
    local ok, msg = send_fn(path, name)

    if ok then
      success_count = success_count + 1

      if config.debug then
        notify.info(("✓ Deleted: %s"):format(name))
      end

      -- Add to undo history
      local undo_ok, undo = pcall(require, "config.neotree.undo")
      if undo_ok and undo.add_to_history then
        undo.add_to_history(path, name)
      end
    else
      failed_items[#failed_items + 1] = {
        path = path,
        name = name,
        error = msg,
      }

      local clean_msg = msg:match("([^\r\n]+)") or msg
      notify.error(("✗ Failed: %s - %s"):format(name, clean_msg))

      -- Recovery attempt
      if config.use_safety_system then
        local recovered = safety.recovery.attempt_recovery({
          operation = "trash",
          path = path,
          message = msg,
        })
        if recovered then
          notify.info(("🔄 Recovery: %s"):format(name))
        end
      end
    end

    ::continue::
  end

  return {
    success_count = success_count,
    cancelled_count = cancelled_count,
    failed_items = failed_items,
    total = #paths,
  }
end

---Show results
---@param results table
---@param backups table
---@return nil
function M.show_results(results, backups)
  local total = results.total
  local success = results.success_count
  local cancelled = results.cancelled_count
  local failed = #results.failed_items

  if success > 0 then
    local parts = { ("✓ Moved to Trash: %d/%d items"):format(success, total) }

    if cancelled > 0 then
      parts[#parts + 1] = ("(%d skipped)"):format(cancelled)
    end

    if failed > 0 then
      parts[#parts + 1] = ("(%d failed)"):format(failed)
    end

    notify.info(table.concat(parts, " "))

    if config.create_backups and next(backups) then
      notify.info(("📦 Backups: %d"):format(vim.tbl_count(backups)))
    end
  elseif cancelled > 0 then
    notify.info(("ℹ️ Cancelled (%d skipped)"):format(cancelled))
  else
    notify.error("❌ All operations failed")
  end

  if failed > 0 and config.create_backups then
    notify.info("💡 Tip: Use :NeoTreeBackupList to restore")
  end
end

return M
