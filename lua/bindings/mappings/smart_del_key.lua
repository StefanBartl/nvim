---@module 'bindings.mappings.smart_del_key'
--- Normal-mode <Del>: on a blank line delete the whole line, otherwise delete
--- the character under the cursor -- both via the black-hole register / buffer
--- API so registers and cursor position are untouched.

---@class SmartEdit
local M = {}

--- Return true if the current line is empty or whitespace-only.
--- @return boolean
local function is_blank_line()
  ---@type string
  local line = vim.api.nvim_get_current_line()
  return line:match("^%s*$") ~= nil
end

--- Delete exactly the current line without touching registers.
--- Uses the buffer API for precision (no ambiguity with :normal parsing).
local function delete_current_line_api()
  local bufnr = 0
  local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
  -- Delete [row-1, row) (0-based, end-exclusive)
  vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, {})
  -- Keep cursor on the same visual line index if possible
  -- After deletion, the next line has now this index; column resets to 0
  local max_row = vim.api.nvim_buf_line_count(bufnr)
  if row > max_row then
    row = max_row
  end
  vim.api.nvim_win_set_cursor(0, { row, 0 })
end

--- Smart delete for <Del> in Normal mode.
--- If blank line: delete it precisely; otherwise: delete one char via "_x.
function M.smart_del()
  if is_blank_line() then
    delete_current_line_api()
    return
  end
  -- IMPORTANT: no leading/trailing spaces; use :normal! to bypass mappings
  vim.cmd.normal({ args = { [["_x]] }, bang = true })
end

--- Bind the global normal-mode <Del> mapping.
function M.setup()
  local map = require("lib.nvim.bindings.keymap")
  map("n", "<Del>", M.smart_del, { desc = "Smart delete (<Del>)" })
end

return M
