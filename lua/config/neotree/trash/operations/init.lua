---@module 'config.neotree.trash.operations'
---@brief Execute trash operations

local notify = require("lib.notify").create("[trash.operations]")
local safety = require("config.neotree.safety")
local confirmation = require("config.neotree.trash.confirmation")

local M = {}

local str_format = string.format

local config = {}

---Set configuration
---@param cfg table
function M.set_config(cfg)
  config = cfg
end

---Create backups for paths
---@param paths string[]
---@param names string[]
---@return table backups_created
function M.create_backups(paths, names)
  local backups = {}

  for i = 1, #paths do
    local path = paths[i]
    local backup_path, err = safety.backup.create_backup(path, "trash")

    if backup_path then
      backups[path] = backup_path
      if config.debug then
        notify.info(str_format("📦 Backup: %s", backup_path))
      end
    else
      notify.warn(str_format("Backup failed for %s: %s", names[i], err or "unknown"))
    end
  end

  return backups
end

---Execute batch deletion
---@param paths string[]
---@param names string[]
---@param delete_mode Cfg.NeoTree.Trash.Operations.DeleteMode # "all"|"individual"
---@param send_fn function(path, name, ask) -> success, msg, cancelled
---@return table results {success_count, cancelled_count, failed_items}
function M.execute_batch(paths, names, delete_mode, send_fn)
  local success_count = 0
  local cancelled_count = 0
  local failed_items = {}

  for i = 1, #paths do
    local path = paths[i]
    local name = names[i]

    -- Individual confirmation
    if delete_mode == "individual" then
      if not confirmation.confirm_individual(name) then
        cancelled_count = cancelled_count + 1
        if config.debug then
          notify.info(str_format("⏭ Skipped: %s", name))
        end
        goto continue
      end
    end

    if config.debug then
      notify.info(str_format("🗑 Processing: %s", name))
    end

    -- Ask before closing only once (first item)
    local ask_close = delete_mode == "all" and i == 1
    local ok, msg, user_cancelled = send_fn(path, name, ask_close)

    if user_cancelled then
      cancelled_count = cancelled_count + 1
      notify.info(str_format("ℹ️ Skipped: %s", name))
      goto continue
    end

    if ok then
      success_count = success_count + 1

      if config.debug then
        notify.info(str_format("✓ Deleted: %s", name))
      end

      -- Add to undo history
      local undo_ok, undo = pcall(require, "config.neotree.undo")
      if undo_ok and undo.add_to_history then
        undo.add_to_history(path, name)
      end
    else
      table.insert(failed_items, {
        path = path,
        name = name,
        error = msg,
      })

      local clean_msg = msg:match("([^\r\n]+)") or msg
      notify.error(str_format("✗ Failed: %s - %s", name, clean_msg))

      -- Recovery attempt
      if config.use_safety_system then
        local recovered = safety.recovery.attempt_recovery({
          operation = "trash",
          path = path,
          message = msg,
        })
        if recovered then
          notify.info(str_format("🔄 Recovery: %s", name))
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

---Show operation results
---@param results table
---@param backups table
function M.show_results(results, backups)
  local total = results.total
  local success = results.success_count
  local cancelled = results.cancelled_count
  local failed = #results.failed_items

  if success > 0 then
    local msg = str_format("✓ Moved to Trash: %d/%d items", success, total)

    if cancelled > 0 then
      msg = msg .. str_format(" (%d skipped)", cancelled)
    end

    if failed > 0 then
      msg = msg .. str_format(" (%d failed)", failed)
    end

    notify.info(msg)

    if config.create_backups and next(backups) then
      notify.info(str_format("📦 Backups: %d", vim.tbl_count(backups)))
    end
  elseif cancelled > 0 then
    notify.info(str_format("ℹ️ Cancelled (%d skipped)", cancelled))
  else
    notify.error("❌ All operations failed")
  end

  if failed > 0 and config.create_backups then
    notify.info("💡 Tip: Use :NeoTreeBackupList to restore")
  end
end

return M
