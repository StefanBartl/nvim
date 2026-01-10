---@module 'custom.format.filter_lines'
---@brief Filter buffer lines based on patterns
---@description
--- Provides line filtering functionality with AND/OR logic.
--- Supports plain text matching with OR-groups via table syntax.

local M = {}

---Check if line matches a condition
---@param line string Line content
---@param condition string|table Condition (string or OR-group)
---@return boolean matches
local function line_matches(line, condition)
  if type(condition) == "string" then
    return string.find(line, condition, 1, true) ~= nil
  elseif type(condition) == "table" then
    for _, str in ipairs(condition) do
      if type(str) == "string" and string.find(line, str, 1, true) then
        return true
      end
    end
    return false
  end
  return false
end

---Parse filter argument (table syntax or plain string)
---@param arg string Argument string
---@return string|table parsed Parsed condition
local function parse_filter_argument(arg)
  local trimmed = arg:match("^%s*(.-)%s*$") or arg

  if trimmed:match("^%{.*%}$") then
    local list = {}
    for s in trimmed:gmatch([["(.-)"]]) do
      table.insert(list, s)
    end
    for s in trimmed:gmatch([['(.-)']]) do
      table.insert(list, s)
    end
    return list
  end

  return trimmed
end

---Filter buffer lines based on conditions
---@param bufnr integer Buffer number
---@param conditions table[] List of conditions (strings or tables)
---@param remove_flag boolean Whether to remove matching lines (default: keep)
---@return boolean success, string|nil error_message
function M.filter_lines(bufnr, conditions, remove_flag)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  remove_flag = remove_flag or false

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false, "Invalid buffer"
  end

  if #conditions == 0 then
    return false, "No conditions provided"
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local new_lines = {}
  local matched_any = false

  for _, line in ipairs(lines) do
    local matches_all = true
    for _, cond in ipairs(conditions) do
      if not line_matches(line, cond) then
        matches_all = false
        break
      end
    end

    if matches_all then
      matched_any = true
    end

    if remove_flag then
      if not matches_all then
        table.insert(new_lines, line)
      end
    else
      if matches_all then
        table.insert(new_lines, line)
      end
    end
  end

  -- Safety check
  if remove_flag and #new_lines == 0 and matched_any then
    return false, "Operation would remove all lines — aborted"
  end

  if not remove_flag and not matched_any then
    return false, "No lines matched the given conditions"
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
  return true, nil
end

---Parse arguments from command line
---@param args string[] Raw arguments
---@return boolean remove_flag, table[] conditions
function M.parse_filter_args(args)
  local remove_flag = false
  local conditions = {}

  for _, arg in ipairs(args) do
    if arg == "--remove" or arg == "-r" then
      remove_flag = true
    else
      local parsed = parse_filter_argument(arg)
      table.insert(conditions, parsed)
    end
  end

  return remove_flag, conditions
end

return M
