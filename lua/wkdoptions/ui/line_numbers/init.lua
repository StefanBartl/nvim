---@module 'wkdoptions.ui.line_number
---@brief Viewport-aware hybrid line numbers.

vim.opt.number = true
vim.opt.relativenumber = false

---@class CustomLineNumbers
local M = {}

---Render custom statuscolumn numbers.
function M.render()
  -- Ignore wrapped/virtual lines.
  if vim.v.virtnum ~= 0 then
    return ""
  end

  ---@type integer
  local cursor_line = vim.fn.line(".")

  ---@type integer
  local line_number = vim.v.lnum

  ---@type integer
  local last_buffer_line = vim.fn.line("$")

  ---@type integer
  local first_visible = vim.fn.line("w0")

  ---@type integer
  local last_visible = vim.fn.line("w$")

  -- =========================================================================
  -- Erste sichtbare Zeile (Hervorgehoben mit %#DiagnosticWarn#)
  -- =========================================================================
  if line_number == first_visible then
    return "%#DiagnosticWarn#" .. tostring(cursor_line - 1) .. "%*"
  end

  -- =========================================================================
  -- Letzte sichtbare Zeile (Hervorgehoben mit %#DiagnosticInfo#)
  -- =========================================================================
  if line_number == last_visible then
    return "%#DiagnosticInfo#" .. tostring(last_buffer_line) .. "%*"
  end

  -- =========================================================================
  -- Cursor-Zeile
  -- =========================================================================
  if line_number == cursor_line then
    return "0"
  end

  -- =========================================================================
  -- Standard relative Nummern
  -- =========================================================================
  return tostring(math.abs(cursor_line - line_number))
end

-- Export globally for statuscolumn.
_G.custom_line_numbers = M.render

vim.opt.statuscolumn = "%=%{%v:lua.custom_line_numbers()%} "

-- Dynamically resize number column for large files.
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
  callback = function()
    vim.opt_local.numberwidth =
      math.max(4, tostring(vim.fn.line("$")):len() + 1)
  end,
})
