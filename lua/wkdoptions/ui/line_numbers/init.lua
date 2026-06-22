---@module 'wkdoptions.ui.line_number
---@brief Viewport-aware hybrid line numbers using centralized ignore list.

vim.opt.number = true
vim.opt.relativenumber = false

local ignore_lib = require("lib.nvim.fs.ignore.list")
local ignore_filetypes = ignore_lib.as_set()

-- UI-spezifische Typen ergänzen
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
  -- Sicherheits-Check (falls doch mal ein UI-Buffer durchrutscht)
  local ft = ignore_lib.normalize(vim.bo.filetype)
  if ignore_filetypes[ft] or vim.bo.buftype ~= "" then
    return ""
  end

  if vim.v.virtnum ~= 0 then return "" end

  local cursor_line     = vim.fn.line(".")
  local line_number     = vim.v.lnum
  local last_buffer_line = vim.fn.line("$")
  local first_visible    = vim.fn.line("w0")
  local last_visible     = vim.fn.line("w$")

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

-- Global exportieren
_G.custom_line_numbers = M.render

-- =========================================================================
-- DIE LÖSUNG: Dynamische Zuweisung statt globalem Vorschlaghammer
-- =========================================================================
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "FileType" }, {
  callback = function()
    local ft = ignore_lib.normalize(vim.bo.filetype)

    -- Wenn es ein normaler Datei-Buffer ist (kein Neo-tree, kein Quickfix etc.)
    if not ignore_filetypes[ft] and vim.bo.buftype == "" then
      vim.opt_local.statuscolumn = "%=%{%v:lua.custom_line_numbers()%} "
      vim.opt_local.numberwidth = math.max(4, tostring(vim.fn.line("$")):len() + 1)
    else
      -- Für Neo-tree und Co: Überschreibe es lokal mit "leer" oder dem Standard
      vim.opt_local.statuscolumn = ""
    end
  end,
})
