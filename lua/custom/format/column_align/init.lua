---@module 'custom.format.column_align'
---@brief Align visually selected character to a target column with a fill character

---@class custom.column_align
local M = {}

---Setup function: keymaps only, no user commands
---@return nil
function M.setup()
  local bufnr = require("lib.nvim.buffer.is_markdown_buf")()
  local o = (type(bufnr) == "number") and { buffer = bufnr } or nil

  local ok_col, column_align = pcall(require, "custom.format.column_align.core")
  if ok_col and column_align and type(column_align.align_interactive) == "function" then
    vim.keymap.set("x", "<leader>ac", column_align.align_interactive, {
      noremap = true,
      silent = true,
      desc = "[custom.ColumnAlign] Align character to column",
      buffer = o and o.buffer or nil,
    })
  end
end

return M
