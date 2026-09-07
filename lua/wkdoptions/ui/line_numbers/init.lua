---@module 'wkdoptions.ui.line_numbers'
---@brief Viewport-aware hybrid line numbers using centralized ignore list.

vim.opt.number = true
vim.opt.relativenumber = false

local ignore_lib = require("lib.nvim.fs.ignore.list")
local Autocmd = require("lib.nvim.bindings.autocmd")
local ignore_filetypes = ignore_lib.as_set()

-- Add UI-specific filetypes
ignore_filetypes["qf"] = true
ignore_filetypes["help"] = true
ignore_filetypes["alpha"] = true
ignore_filetypes["dashboard"] = true
ignore_filetypes["trouble"] = true
ignore_filetypes["neo-tree"] = true
ignore_filetypes["neo-tree-popup"] = true

---@class CustomLineNumbers
local M = {}

---Render custom statuscolumn numbers.
function M.render()
  -- Safety check, in case a UI buffer slips through anyway
  local ft = ignore_lib.normalize(vim.bo.filetype)
  if ignore_filetypes[ft] or vim.bo.buftype ~= "" then
    return ""
  end

  if vim.v.virtnum ~= 0 then
    return ""
  end

  local cursor_line = vim.fn.line(".")
  local line_number = vim.v.lnum
  local last_buffer_line = vim.fn.line("$")
  local first_visible = vim.fn.line("w0")
  local last_visible = vim.fn.line("w$")

  if line_number == first_visible then
    return "%#DiagnosticWarn#" .. tostring(cursor_line - 1) .. "%*"
  end

  if line_number == last_visible then
    return "%#DiagnosticInfo#" .. tostring(last_buffer_line) .. "%*"
  end

  if line_number == cursor_line then
    return "0"
  end

  return tostring(math.abs(cursor_line - line_number))
end

_G.custom_line_numbers = M.render

-- Assigns `statuscolumn` per buffer instead of setting one global default,
-- since the ignore list only applies to a subset of buffers.
Autocmd.create({ "BufEnter", "BufWinEnter", "FileType" }, function()
  local ft = ignore_lib.normalize(vim.bo.filetype)

  -- Regular file buffer (not neo-tree, quickfix, etc.)
  if not ignore_filetypes[ft] and vim.bo.buftype == "" then
    vim.opt_local.statuscolumn = "%=%{%v:lua.custom_line_numbers()%} "
    vim.opt_local.numberwidth = math.max(4, tostring(vim.fn.line("$")):len() + 1)
  else
    -- neo-tree & co: blank the statuscolumn locally
    vim.opt_local.statuscolumn = ""
  end
end)
