---@module 'lib.lua_ls.insert.module_w_path'
---@brief Core implementation for Lua annotation insertion
---@description
--- Provides functions to insert EmmyLua annotations at the cursor position.
---
--- dependcies:
--- lib/lua_ls/get_module_path
--- lib/buffer/insert_lines_at_cursor.lua

local api = vim.api

---Insert @module annotation
---@return boolean success
return function ()
  local bufnr = api.nvim_get_current_buf()
  local filepath = api.nvim_buf_get_name(bufnr)

  if not filepath:match("%.lua$") then
    vim.notify(
      "[lib.lua_ls.insert.module_annotation] Not a Lua file",
      vim.log.levels.WARN
    )
    return false
  end

  local module_path = require("lib.lua_ls.get_module_path")(filepath)
  if not module_path then
    vim.notify(
      "[lib.lua_ls.insert.module_annotation] File not in lua/ directory",
      vim.log.levels.WARN
    )
    return false
  end

  local annotation = string.format("---@module '%s'", module_path)
  require("lib.buffer.insert_lines_at_cursor")({ annotation })

  return true
end
