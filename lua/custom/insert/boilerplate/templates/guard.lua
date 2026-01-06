---@module 'custom.insert.boilerplate.templates.guard'
---@brief Guard clause pattern generators

local utils = require("custom.insert.boilerplate.templates.utils")

local M = {}

---Generate guard clause template
---@param condition string|nil Condition to check
---@param is_negated boolean Whether to use 'not' prefix
---@return string[]|nil lines
function M.guard(condition, is_negated)
  if not condition or condition == "" then
    condition = "condition"
  end

  local check = is_negated and ("not " .. condition) or condition

  return {
    string.format("if %s then", check),
    '  vim.notify("TODO: Error message", vim.log.levels.ERROR)',
    "  return nil",
    "end",
  }
end

---Interactive guard clause generation
---@return string[]|nil lines
function M.guard_interactive()
  local prompts = {
    {
      name = "condition",
      prompt = "Condition to check (empty for 'condition')",
      default = "condition",
      required = false,
    },
    {
      name = "negation",
      prompt = "Use 'not' prefix? (y/n)",
      default = "n",
      required = false,
    },
  }

  local values = utils.process_prompts(prompts)
  if not values then
    return nil
  end

  local is_negated = values.negation:lower() == "y"

  return M.guard(values.condition, is_negated)
end

return M
