---@module 'custom.insert.lua_module_annotation'
--- UserCommand zum Einfügen von Emmy Lua @module Annotation

local notify = require("lib.nvim.notify").create("[custom.insert.annotation]")

local M = {}

local api = vim.api

--- Converts a file path to a Lua module path
---@param filepath string Absolute path to the file
---@return string|nil `module_path` The module path, or `nil` if no `lua/` folder is found.
local function get_module_path(filepath)
  -- Normalize path
  local normalized = filepath:gsub("\\", "/")

  -- Find lua/ in the path
  local lua_idx = normalized:find("/lua/")
  if not lua_idx then
    return nil
  end

  -- Extract path to lua/
  local after_lua = normalized:sub(lua_idx + 5) -- +5 for "/lua/"

  -- Remove .lua extension
  local without_ext = after_lua:gsub("%.lua$", "")

  -- Remove init at the end (if the file is named init.lua)
  without_ext = without_ext:gsub("/init$", "")

  -- Replace / with .
  local module_path = without_ext:gsub("/", ".")

  return module_path
end

--- Inserts @module annotation at cursor position
local function insert_module_annotation_at_cursor()
  local bufnr = api.nvim_get_current_buf()
  local filepath = api.nvim_buf_get_name(bufnr)

  -- Check if it's a .lua file
  if not filepath:match("%.lua$") then
    notify.warn("Not a Lua file")
    return
  end

  -- Calculate module path
  local module_path = get_module_path(filepath)
  if not module_path then
    notify.warn("File is not in a 'lua/' directory")
    return
  end

  -- Get current cursor position
  local cursor = api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- 0-indexed for nvim_buf_set_lines

  -- Create annotation
  local annotation = string.format("---@module '%s'", module_path)

  -- Insert at cursor position
  api.nvim_buf_set_lines(bufnr, row, row, false, { annotation })

  -- Move cursor down one line
  api.nvim_win_set_cursor(0, { row + 2, 0 })

  notify.info("Inserted: " .. annotation)
end

--- Setup UserCommand
function M.enable()
  api.nvim_create_user_command("LuaModuleAnnotations", function()
    insert_module_annotation_at_cursor()
  end, {
    desc = "[custom.insert.luaModuleAnnotations] Insert @module annotation for current Lua file at cursor position",
  })
end

return M
