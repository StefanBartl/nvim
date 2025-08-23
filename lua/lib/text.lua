---@module 'lib.text'
--- Safe text utilities for Neovim buffers (guarded insert operations)

---@class InsertBlankLineOptions
---@field keep_cursor_on_text boolean?  -- if true, keep cursor on the original text line after insertion (default: true)
---@field notify boolean?               -- if true, show a warning when skipped/failed (default: true)

local M = {}

--- Insert a blank line above the current cursor line, with safety checks.
--- @param opts InsertBlankLineOptions|nil
--- @return boolean inserted   -- true if a line was inserted
--- @return string|nil err     -- "not_modifiable"|"bad_buftype"|"insert_failed"|nil
function M.insert_blank_line_above(opts)
  opts = opts or {}
  local keep_on_text = (opts.keep_cursor_on_text ~= false)
  local do_notify = (opts.notify ~= false)

  local buf = vim.api.nvim_get_current_buf()
  local bo = vim.bo[buf]

  if not bo.modifiable or bo.readonly then
    return false, "not_modifiable"
  end

  local disallowed = { terminal = true, prompt = true, help = true, quickfix = true }
  if disallowed[bo.buftype] then
    return false, "bad_buftype"
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- 1-based row

  local ok, err = pcall(vim.api.nvim_buf_set_lines, buf, row - 1, row - 1, false, { "" })
  if not ok then
    return false, "insert_failed"
  end

  local new_row = keep_on_text and (row + 1) or row
  local line_len = #vim.api.nvim_get_current_line()
  if col > line_len then col = line_len end
  pcall(vim.api.nvim_win_set_cursor, 0, { new_row, col })

  return true
end

return M
