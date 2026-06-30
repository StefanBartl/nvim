---@module 'config.neotree.safety.dry_run'
---@brief Dry-run mode for testing file operations without executing them

local notify = require("lib.nvim.notify").create("[config.neotree.safety.dry_run]")

local M = {}

---@type boolean
M.enabled = false

---@type table[]
local planned_operations = {}

---Enable dry-run mode
function M.enable()
  M.enabled = true
  planned_operations = {}
  notify.info("Dry-run mode ENABLED")
end

---Disable dry-run mode
function M.disable()
  M.enabled = false
  planned_operations = {}
  notify.info("Dry-run mode DISABLED")
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

  notify.info(string.format("[DRY-RUN] %s: %s", operation, vim.inspect(details)))
end

---Get all planned operations
---@return table[]
function M.get_planned_operations()
  return vim.deepcopy(planned_operations)
end

---Show dry-run report
function M.show_report()
  if #planned_operations == 0 then
    notify.info("No operations planned")
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

  notify.info(table.concat(lines, "\n"))
end

---Clear planned operations
function M.clear()
  planned_operations = {}
end

return M

