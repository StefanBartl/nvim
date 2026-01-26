---@module 'config.neotree.safety'
---@brief Aggregated safety features for file operations

local notify = require("lib.notify").create("[config.neotree.safety]")

local M = {}

M.backup = require("config.neotree.safety.backup")
M.queue = require("config.neotree.safety.operation_queue")
M.dry_run = require("config.neotree.safety.dry_run")
M.validation = require("config.neotree.safety.validation")
M.recovery = require("config.neotree.safety.recovery")

---Setup safety features with config
---@param config table|nil
function M.setup(config)
  config = config or {}

  -- Auto-cleanup old backups on startup
  if config.auto_cleanup_backups ~= false then
    local cleaned = M.backup.clean_old_backups(config.backup_max_age_days or 7)
    if cleaned > 0 then
      notify.info(string.format("Cleaned %d old backups", cleaned))
    end
  end

  -- Auto-cleanup old recovery points
  if config.auto_cleanup_recovery ~= false then
    M.recovery.clear_old_points(config.recovery_max_age_minutes or 60)
  end
end

---Wrap operation with full safety (backup + queue + validation)
---@param operation_fn fun(): boolean?, string|nil? Operation to execute Operation to execute
---@param operation_name string
---@param paths string[]
---@return boolean success, string|nil error
function M.safe_operation(operation_fn, operation_name, paths)
  -- Dry-run check
  if M.dry_run.enabled then
    M.dry_run.log_operation(operation_name, { paths = paths })
    return true, "dry-run"
  end

  -- Validate
  local valid, reason = M.validation.validate_operation(operation_name, paths)
  if not valid then
    return false, reason
  end

  -- Confirm if dangerous
  if not M.validation.confirm_operation(operation_name, paths) then
    return false, "user cancelled"
  end

  -- Create backup
  local backups = {}
  if operation_name == "delete" or operation_name == "move" then
    for _, path in ipairs(paths) do
      local backup_path, _ = M.backup.create_backup(path, operation_name)
      if backup_path then
        table.insert(backups, backup_path)
      end
    end
  end

  -- Create recovery point
  M.recovery.create_recovery_point(operation_name, paths, {
    backups = backups,
  })

  -- Execute via queue
  local success = false
  local error_msg = nil

  M.queue.enqueue(function()
    local ok, err = pcall(operation_fn)
    success = ok
    error_msg = err

    if not ok then
      -- Attempt recovery
      M.recovery.attempt_recovery({
        operation = operation_name,
        message = tostring(err),
      })
    end
  end, operation_name, 10)

  -- Wait for operation to complete
  vim.wait(5000, function()
    return not M.queue.status().processing
  end)

  return success, error_msg
end

return M

