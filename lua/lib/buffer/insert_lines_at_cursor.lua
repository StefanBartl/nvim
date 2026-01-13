---@module 'lib.buffer.insert_lines_at_cursor'

local api = vim.api

---Insert lines at current cursor position
---@param lines string[]
return function (lines)
  local win = api.nvim_get_current_win()
  local cursor = api.nvim_win_get_cursor(win)
  local row = cursor[1] - 1

  api.nvim_buf_set_lines(0, row, row, false, lines)
  api.nvim_win_set_cursor(win, { row + #lines + 1, 0 })
end
