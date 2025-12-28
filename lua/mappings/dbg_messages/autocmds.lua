---@module 'mappings.dbg_messages.autocmds'
--- Autocommands for tagged log views (messages / noice).
--- Ensures refresh + cursor-at-bottom when a tagged buffer enters a window.

local api = vim.api

-- ---@param win integer
-- ---@return string|nil
-- local function get_window_tag(win)
  -- if not api.nvim_win_is_valid(win) then
    -- return nil
  -- end
  -- return vim.w[win] and vim.w[win].custom_tag or nil
-- end

---@param win integer
---@param attempts integer
---@param retry_delay integer
local function focus_and_bottom(win, attempts, retry_delay)
  -- Validate window exists and is valid
  if not (win and api.nvim_win_is_valid(win)) then
    return
  end

  -- Verify window is still a content window (not border/title)
  local ok_config, config = pcall(api.nvim_win_get_config, win)
  if not ok_config then
    return
  end

  -- Skip if this is a border/title window
  if config.relative == "win" or config.width <= 1 or config.height <= 1 then
    return
  end

  local utils = require("mappings.dbg_messages.utils")

  -- Make focusable before setting focus
  utils.make_focusable(win)

  -- Ensure deterministic focus and cursor visibility
  utils.force_focus(win)

  -- Re-validate after focus change
  if not api.nvim_win_is_valid(win) then
    return
  end

  local ok_buf, buf = pcall(api.nvim_win_get_buf, win)
  if not ok_buf or not api.nvim_buf_is_valid(buf) then
    return
  end

  local last = api.nvim_buf_line_count(buf)

  -- Logical cursor move
  pcall(api.nvim_win_set_cursor, win, { last, 0 })

  -- Visual scroll (required for log-style buffers)
  vim.cmd("normal! G")

  utils.ensure_bottom(win, attempts, retry_delay)
end

---@param win integer
---@param tag string
---@param attempts integer
---@param retry_delay integer
local function refresh_log_view(win, tag, attempts, retry_delay)
  -- Validate window
  if not (win and api.nvim_win_is_valid(win)) then
    return
  end

  -- Verify it's a content window
  local ok_config, config = pcall(api.nvim_win_get_config, win)
  if not ok_config or config.relative == "win" or config.width <= 1 or config.height <= 1 then
    return
  end

  -- Re-emit content (messages are snapshots, not live views)
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
          local tag = vim.w[win] and vim.w[win].custom_tag or nil

          if tag then
            -- Verify it's a content window before processing
            local ok_config, config = pcall(api.nvim_win_get_config, win)
            if ok_config and config.relative ~= "win" and config.width > 1 and config.height > 1 then
              refresh_log_view(win, tag, timings.attempts, timings.retry_delay_ms)
            end
          end
    end
  end
end,
})
end

return {
  register_bufwinenter = register_bufwinenter,
}
