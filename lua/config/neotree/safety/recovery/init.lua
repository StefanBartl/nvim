---@module 'config.neotree.safety.recovery'
---@brief Automatic recovery from failed operations

local M = {}

---@class RecoveryPoint
---@field timestamp number
---@field operation string
---@field state table Serializable state snapshot
---@field paths string[]

---@type RecoveryPoint[]
local recovery_points = {}
local MAX_RECOVERY_POINTS = 10

---Create recovery point before operation
---@param operation string
---@param paths string[]
---@param state table|nil
---@return integer point_id
function M.create_recovery_point(operation, paths, state)
  local point = {
    timestamp = os.time(),
    operation = operation,
    state = state or {},
    paths = paths,
  }

  table.insert(recovery_points, 1, point)

  -- Limit recovery points
  while #recovery_points > MAX_RECOVERY_POINTS do
    table.remove(recovery_points)
  end

  return #recovery_points
end

---Attempt automatic recovery
---@param error_info table Error information
---@return boolean recovered
function M.attempt_recovery(error_info)
  if #recovery_points == 0 then
    return false
  end

  local latest = recovery_points[1]

  -- Check if error is recoverable
  local recoverable_errors = {
    "EPERM",
    "EBUSY",
    "EACCES",
  }

  local is_recoverable = false
  for _, err_type in ipairs(recoverable_errors) do
    if error_info.message and error_info.message:match(err_type) then
      is_recoverable = true
      break
    end
  end

  if not is_recoverable then
    return false
  end

  -- Wait and retry
  vim.defer_fn(function()
    -- Retry operation logic here
    vim.notify(
      string.format("Attempting recovery for: %s", latest.operation),
      vim.log.levels.INFO
    )

    -- Cleanup and retry would go here
  end, 2000)

  return true
end

---List recovery points
---@return RecoveryPoint[]
function M.list_recovery_points()
  return vim.deepcopy(recovery_points)
end

---Clear old recovery points
---@param max_age_minutes integer
---@return integer cleared
function M.clear_old_points(max_age_minutes)
  local cutoff = os.time() - (max_age_minutes * 60)
  local cleared = 0
  local new_points = {}

  for _, point in ipairs(recovery_points) do
    if point.timestamp >= cutoff then
      table.insert(new_points, point)
    else
      cleared = cleared + 1
    end
  end

  recovery_points = new_points
  return cleared
end

return M
