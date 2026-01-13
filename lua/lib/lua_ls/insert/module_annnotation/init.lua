---@module 'lib.lua_ls.insert.module_annotation'
---Insert a LuaLS @module annotation into a buffer at a configurable position

local api = vim.api

---@class InsertModuleOpts
---@field bufnr? integer Buffer handle; defaults to current buffer
---@field row? integer 0-based row index; defaults to current cursor row
---@field col? integer 0-based column index; defaults to current cursor column

---Insert @module annotation
---
---Semantics:
---- no arguments                  → current buffer, current cursor position
---- opts.bufnr only               → cursor position of current window, target buffer
---- opts.bufnr + opts.row (+col)  → explicit position in given buffer
---
---@param opts? InsertModuleOpts
---@return boolean success
return function(opts)
  opts = opts or {}

  -- Resolve buffer
  local bufnr = opts.bufnr or api.nvim_get_current_buf()

  -- Resolve cursor / position
  local row
  local col

  if opts.row ~= nil then
    row = opts.row
    col = opts.col or 0
  else
    local win = api.nvim_get_current_win()
    local cursor = api.nvim_win_get_cursor(win)
    row = cursor[1] - 1
    col = cursor[2]
  end

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

  -- Insert annotation
  api.nvim_buf_set_lines(bufnr, row, row, false, { annotation })

  -- Move cursor (only if current buffer)
  if bufnr == api.nvim_get_current_buf() then
    api.nvim_win_set_cursor(
      api.nvim_get_current_win(),
      { row + 2, col }
    )
  end

  return true
end

