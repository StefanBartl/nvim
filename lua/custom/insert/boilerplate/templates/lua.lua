---@module 'custom.insert.boilerplate.templates.lua'
---@brief Lua code template generators

local utils = require("custom.insert.boilerplate.templates.utils")

local M = {}

---Generate Lua module template
---@param name string|nil Module name
---@return string[]
function M.module(name)
  name = name or utils.get_module_path() or "module.name"

  return {
    string.format("---@module '%s'", name),
    "---@brief TODO: Add brief description",
    "---@description",
    "--- TODO: Add detailed description",
    "",
    "local M = {}",
    "",
    "---TODO: Add function description",
    "---@return nil",
    "function M.setup()",
    "  -- TODO: Implementation",
    "end",
    "",
    "return M",
  }
end

---Generate Lua class template
---@param class_name string
---@return string[]
function M.class(class_name)
  return {
    string.format("---@class %s", class_name),
    "---@field private _data table Internal state",
    string.format("local %s = {}", class_name),
    string.format("%s.__index = %s", class_name, class_name),
    "",
    "---Constructor",
    "---@param opts table|nil Options",
    string.format("---@return %s", class_name),
    string.format("function %s.new(opts)", class_name),
    "  opts = opts or {}",
    string.format("  local self = setmetatable({}, %s)", class_name),
    "  self._data = opts",
    "  return self",
    "end",
    "",
    string.format("return %s", class_name),
  }
end

---Generate Lua function template
---@return string[]
function M.func()
  return {
    "---TODO: Add description",
    "---@param arg1 type TODO: Add param description",
    "---@return type TODO: Add return description",
    "local function function_name(arg1)",
    "  -- TODO: Implementation",
    "end",
  }
end

return M
