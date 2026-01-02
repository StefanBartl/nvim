---@module 'config.neotree.safety.dry_run'
---@brief Dry-run mode for testing file operations without executing them

local M = {}

---@type boolean
M.enabled = false

---@type table[]
local planned_operations = {}

---Enable dry-run mode
function M.enable()
  M.enabled = true
  planned_operations = {}
  vim.notify("Dry-run mode ENABLED", vim.log.levels.INFO)
end

---Disable dry-run mode
function M.disable()
  M.enabled = false
  planned_operations = {}
  vim.notify("Dry-run mode DISABLED", vim.log.levels.INFO)
end

---Toggle dry-run mode
function M.toggle()
  if M.enabled then
    M.disable()
  else
    M.enable()
  end
end

---Log operation (instead of executing)
---@param operation string Operation type
---@param details table Operation details
function M.log_operation(operation, details)
  if not M.enabled then
    return
  end

  table.insert(planned_operations, {
    operation = operation,
    details = details,
    timestamp = os.time(),
  })

  vim.notify(
    string.format("[DRY-RUN] %s: %s", operation, vim.inspect(details)),
    vim.log.levels.INFO
  )
end

---Get all planned operations
---@return table[]
function M.get_planned_operations()
  return vim.deepcopy(planned_operations)
end

---Show dry-run report
function M.show_report()
  if #planned_operations == 0 then
    vim.notify("No operations planned", vim.log.levels.INFO)
    return
  end

  local lines = { "=== Dry-Run Report ===" }

  for i, op in ipairs(planned_operations) do
    local time_str = os.date("%H:%M:%S", op.timestamp)
    table.insert(lines, string.format("[%d] %s | %s", i, time_str, op.operation))

    for k, v in pairs(op.details) do
      table.insert(lines, string.format("    %s: %s", k, tostring(v)))
    end
  end

  table.insert(lines, "")
  table.insert(lines, string.format("Total operations: %d", #planned_operations))

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

---Clear planned operations
function M.clear()
  planned_operations = {}
end

return M

