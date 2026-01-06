---@module 'custom.insert.annotation.core'
---@brief Core implementation for Lua annotation insertion
---@description
--- Provides functions to insert EmmyLua annotations at the cursor position.

local M = {}

local api = vim.api

---Convert file path to Lua module path
---@param filepath string Absolute path to file
---@return string|nil module_path
local function get_module_path(filepath)
  local normalized = filepath:gsub("\\", "/")
  local lua_idx = normalized:find("/lua/")
  if not lua_idx then
    return nil
  end

  local after_lua = normalized:sub(lua_idx + 5)
  local without_ext = after_lua:gsub("%.lua$", "")
  without_ext = without_ext:gsub("/init$", "")
  local module_path = without_ext:gsub("/", ".")

  return module_path
end

---Insert lines at current cursor position
---@param lines string[]
local function insert_lines_at_cursor(lines)
  local win = api.nvim_get_current_win()
  local cursor = api.nvim_win_get_cursor(win)
  local row = cursor[1] - 1

  api.nvim_buf_set_lines(0, row, row, false, lines)
  api.nvim_win_set_cursor(win, { row + #lines + 1, 0 })
end

---Insert @module annotation
---@return boolean success
function M.insert_module_annotation()
  local bufnr = api.nvim_get_current_buf()
  local filepath = api.nvim_buf_get_name(bufnr)

  if not filepath:match("%.lua$") then
    vim.notify(
      "[custom.insert.annotation] Not a Lua file",
      vim.log.levels.WARN
    )
    return false
  end

  local module_path = get_module_path(filepath)
  if not module_path then
    vim.notify(
      "[custom.insert.annotation] File not in lua/ directory",
      vim.log.levels.WARN
    )
    return false
  end

  local annotation = string.format("---@module '%s'", module_path)
  insert_lines_at_cursor({ annotation })

  return true
end

---Insert @class annotation
---@param name string|nil Class name (prompts if nil)
---@return boolean success
function M.insert_class_annotation(name)
  if not name or name == "" then
    name = vim.fn.input("Class name: ")
    if name == "" then
      return false
    end
  end

  local lines = {
    string.format("---@class %s", name),
  }

  insert_lines_at_cursor(lines)
  return true
end

---Insert complete function annotation block
---@return boolean success
function M.insert_function_annotation()
  -- Prompt for function description
  local desc = vim.fn.input("Function description: ")
  if desc == "" then
    desc = "TODO: Add description"
  end

  -- Prompt for parameters
  local params = {}
  while true do
    local param_name = vim.fn.input("Parameter name (empty to finish): ")
    if param_name == "" then
      break
    end

    local param_type = vim.fn.input(string.format("Type for '%s': ", param_name))
    if param_type == "" then
      param_type = "any"
    end

    local param_desc = vim.fn.input(string.format("Description for '%s': ", param_name))
    if param_desc == "" then
      param_desc = "TODO: Add description"
    end

    table.insert(params, {
      name = param_name,
      type = param_type,
      desc = param_desc,
    })
  end

  -- Prompt for return value
  local return_type = vim.fn.input("Return type (empty for nil): ")
  if return_type == "" then
    return_type = "nil"
  end

  local return_desc = vim.fn.input("Return description: ")
  if return_desc == "" then
    return_desc = "TODO: Add description"
  end

  -- Build annotation lines
  local lines = { "---" .. desc }

  for _, param in ipairs(params) do
    table.insert(
      lines,
      string.format("---@param %s %s %s", param.name, param.type, param.desc)
    )
  end

  table.insert(
    lines,
    string.format("---@return %s %s", return_type, return_desc)
  )

  insert_lines_at_cursor(lines)
  return true
end

---@type Custom.Insert.Annotation.API
return M
