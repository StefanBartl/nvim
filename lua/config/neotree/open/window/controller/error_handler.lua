---@module 'config.neotree.open.window.controller.error_handler'
---@brief Centralized error handling for Neo-tree operations

local M = {}

local cfg = require("config.neotree").options

---@type table<string, integer>
local error_counts = {}

---Log error with context
---@param context string Error context (e.g., "open_window", "close_window")
---@param err string Error message
---@param level? integer Log level (default: ERROR)
function M.log(context, err, level)
  level = level or vim.log.levels.ERROR

  error_counts[context] = (error_counts[context] or 0) + 1

  if cfg.debug or level == vim.log.levels.ERROR then
    vim.notify(
      string.format("[neo-tree.%s] %s", context, tostring(err)),
      level
    )
  end
end

---Safe call with error logging
---@param fn function
---@param context string
---@return boolean success, any result_or_error
function M.safe_call(fn, context)
  local ok, result = pcall(fn)
  if not ok then
    M.log(context, result)
    return false, result
  end
  return true, result
end

---Get error statistics
---@return table<string, integer>
function M.get_stats()
  return vim.deepcopy(error_counts)
end

---Clear error statistics
function M.clear_stats()
  error_counts = {}
end

return M
