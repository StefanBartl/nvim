---@module 'custom.recommender.rendering'
---Float rendering and state

local notify = require("lib.nvim.notify").create("[custom.recommender.rendering]")

local M = {}

local api = vim.api

M.float_buf = nil
M.float_win = nil
M.cursor_index = 2 -- Start at first selectable line
M.source_win = nil -- Store the window we came from

---@return boolean
function M.is_open()
  return M.float_win ~= nil and api.nvim_win_is_valid(M.float_win)
end

function M.close()
  if M.float_win and api.nvim_win_is_valid(M.float_win) then
    pcall(api.nvim_win_close, M.float_win, true)
  end
  if M.float_buf and api.nvim_buf_is_valid(M.float_buf) then
    pcall(api.nvim_buf_delete, M.float_buf, { force = true })
  end
  M.float_buf, M.float_win, M.source_win = nil, nil, nil
  M.cursor_index = 2
end

---@param suggestions table[]
---@param title string
---@param restore_index integer|nil
function M.open(suggestions, title, restore_index)
  -- Store the current window before opening float
  M.source_win = api.nvim_get_current_win()

  M.close()

  if #suggestions == 0 then
    return
  end

  M.float_buf = api.nvim_create_buf(false, true)
  if not M.float_buf or M.float_buf == 0 then
    notify.error("Failed to create buffer")
    return
  end

  -- Build content lines
  local lines = { "" }
  for _, s in ipairs(suggestions) do
    table.insert(lines, string.format("→ %s (%d hits)", s.chain, s.count))
    table.insert(lines, "  " .. s.alias)
    table.insert(lines, "")
  end

  -- Set buffer options
  pcall(api.nvim_buf_set_option, M.float_buf, "buftype", "nofile")
  pcall(api.nvim_buf_set_option, M.float_buf, "bufhidden", "wipe")
  pcall(api.nvim_buf_set_option, M.float_buf, "swapfile", false)

  -- Set lines
  api.nvim_buf_set_lines(M.float_buf, 0, -1, false, lines)
  pcall(api.nvim_buf_set_option, M.float_buf, "modifiable", false)

  -- Calculate window dimensions
  local width = 50
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 4, vim.o.columns - 10)

  local height = math.min(#lines + 2, vim.o.lines - 10)

  -- Open window
  M.float_win = api.nvim_open_win(M.float_buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  if not M.float_win or M.float_win == 0 then
    notify.error("Failed to create window")
    M.close()
    return
  end

  -- Set window options
  pcall(api.nvim_win_set_option, M.float_win, "cursorline", true)
  pcall(api.nvim_win_set_option, M.float_win, "wrap", false)
  pcall(api.nvim_win_set_option, M.float_win, "number", false)
  pcall(api.nvim_win_set_option, M.float_win, "relativenumber", false)
  pcall(api.nvim_win_set_option, M.float_win, "signcolumn", "no")

  -- Set cursor position
  M.cursor_index = restore_index or 2
  if M.cursor_index > #lines then
    M.cursor_index = 2
  end
  pcall(api.nvim_win_set_cursor, M.float_win, { M.cursor_index, 0 })
end

return M
