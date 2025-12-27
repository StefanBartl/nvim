---@module 'mappings.dbg_messages.autocmds'
--- Autocommands for tagged log views (messages / noice).
--- Ensures refresh + cursor-at-bottom when a tagged buffer enters a window.

local api = vim.api

---@param win integer
---@return string|nil
local function get_window_tag(win)
  if not api.nvim_win_is_valid(win) then
    return nil
  end
  return vim.w[win] and vim.w[win].custom_tag or nil
end

---@param win integer
---@param attempts integer
---@param retry_delay integer
local function focus_and_bottom(win, attempts, retry_delay)
  api.nvim_set_current_win(win)

  local buf = api.nvim_win_get_buf(win)
  local last = api.nvim_buf_line_count(buf)

  -- Logical cursor move
  pcall(api.nvim_win_set_cursor, win, { last, 0 })

  -- Visual scroll (required for log-style buffers)
  vim.cmd("normal! G")

  require("mappings.dbg_messages.utils")
    .ensure_bottom(win, attempts, retry_delay)
end

---@param win integer
---@param tag string
---@param attempts integer
---@param retry_delay integer
local function refresh_log_view(win, tag, attempts, retry_delay)
  if tag == "messages" then
    vim.cmd("messages")
  elseif tag == "noice_all" then
    vim.cmd("Noice all")
  elseif tag == "noice_errors" then
    vim.cmd("Noice errors")
  else
    return
  end

  focus_and_bottom(win, attempts, retry_delay)
end

---@param augroup integer
---@param timings DbgMsgs.Timings
local function register_bufwinenter(augroup, timings)
  api.nvim_create_autocmd("BufWinEnter", {
    group = augroup,
    desc = "Refresh tagged log views on BufWinEnter",
    callback = function(ev)
      -- Find the concrete window that currently displays this buffer
      local wins = vim.fn.win_findbuf(ev.buf)
      if not wins or #wins == 0 then
        return
      end

      for i = 1, #wins do
        local win = wins[i]
        if api.nvim_win_is_valid(win) then
          local tag = get_window_tag(win)
          if tag then
            refresh_log_view(
              win,
              tag,
              timings.attempts,
              timings.retry_delay_ms
            )
          end
        end
      end
    end,
  })
end

return {
  register_bufwinenter = register_bufwinenter,
}

