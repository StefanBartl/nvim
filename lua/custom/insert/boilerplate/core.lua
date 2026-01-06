---@module 'custom.insert.boilerplate.core'
---@brief Core implementation for boilerplate/template insertion
---@description
--- Provides functions to insert common code templates.

local M = {}

local api = vim.api

---@alias Custom.Insert.Boilerplate.Template
---| "lua-module"    -- Complete Lua module skeleton
---| "lua-class"     -- Lua class with constructor
---| "lua-function"  -- Annotated function template
---| "nvim-autocmd"  -- Neovim autocommand group
---| "nvim-keymap"   -- Neovim keymap with description
---| "guard-clause"  -- Early return guard pattern

---Insert lines at cursor
---@param lines string[]
local function insert_lines_at_cursor(lines)
  local win = api.nvim_get_current_win()
  local cursor = api.nvim_win_get_cursor(win)
  local row = cursor[1] - 1

  api.nvim_buf_set_lines(0, row, row, false, lines)
  api.nvim_win_set_cursor(win, { row + #lines + 1, 0 })
end

---Get Lua module path for current buffer
---@return string|nil
local function get_module_path()
  local filepath = api.nvim_buf_get_name(0)
  local normalized = filepath:gsub("\\", "/")
  local lua_idx = normalized:find("/lua/")
  if not lua_idx then
    return nil
  end

  local after_lua = normalized:sub(lua_idx + 5)
  local without_ext = after_lua:gsub("%.lua$", "")
  without_ext = without_ext:gsub("/init$", "")
  return without_ext:gsub("/", ".")
end

---Generate template for Lua module
---@param name string|nil Module name (auto-detected if nil)
---@return string[]
local function template_lua_module(name)
  name = name or get_module_path() or "module.name"

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

---Generate template for Lua class
---@param class_name string
---@return string[]
local function template_lua_class(class_name)
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

---Generate template for annotated function
---@return string[]
local function template_lua_function()
  return {
    "---TODO: Add description",
    "---@param arg1 type TODO: Add param description",
    "---@return type TODO: Add return description",
    "local function function_name(arg1)",
    "  -- TODO: Implementation",
    "end",
  }
end

---Generate template for Neovim autocommand group
---@param group_name string
---@return string[]
local function template_nvim_autocmd(group_name)
  return {
    string.format('local augroup = vim.api.nvim_create_augroup("%s", { clear = true })', group_name),
    "",
    "vim.api.nvim_create_autocmd({ TODO: events }, {",
    "  group = augroup,",
    '  pattern = "TODO: pattern",',
    "  callback = function()",
    "    -- TODO: Implementation",
    "  end,",
    '  desc = "TODO: Description",',
    "})",
  }
end

---Generate template for Neovim keymap
---@return string[]
local function template_nvim_keymap()
  return {
    'vim.keymap.set("n", "<leader>TODO", function()',
    "  -- TODO: Implementation",
    'end, { desc = "TODO: Description" })',
  }
end

---Generate template for guard clause
---@return string[]
local function template_guard_clause()
  return {
    "if not condition then",
    '  vim.notify("TODO: Error message", vim.log.levels.ERROR)',
    "  return nil",
    "end",
  }
end

---Insert boilerplate template at cursor
---@param template Custom.Insert.Boilerplate.Template
---@param name string|nil Optional name parameter
---@return boolean success
function M.insert_template(template, name)
  local lines

  if template == "lua-module" then
    lines = template_lua_module(name)
  elseif template == "lua-class" then
    if not name or name == "" then
      name = vim.fn.input("Class name: ")
      if name == "" then
        return false
      end
    end
    lines = template_lua_class(name)
  elseif template == "lua-function" then
    lines = template_lua_function()
  elseif template == "nvim-autocmd" then
    if not name or name == "" then
      name = vim.fn.input("Autocommand group name: ")
      if name == "" then
        return false
      end
    end
    lines = template_nvim_autocmd(name)
  elseif template == "nvim-keymap" then
    lines = template_nvim_keymap()
  elseif template == "guard-clause" then
    lines = template_guard_clause()
  else
    vim.notify(
      "[custom.insert.boilerplate] Unknown template: " .. template,
      vim.log.levels.ERROR
    )
    return false
  end

  insert_lines_at_cursor(lines)
  return true
end

return M
