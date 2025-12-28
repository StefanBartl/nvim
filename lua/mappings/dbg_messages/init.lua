---@module 'mappings.dbg_messages'
---Deterministic handling for :messages and Noice log views.
---Guarantees:
---  - explicit window/buffer identification via tags
---  - focus + cursor always at last line
---  - safe refresh on WinEnter / BufWinEnter
---  - automatic refresh on new content
---  - no reliance on current window (win=0)
---  - modular, extensible architecture
require("mappings.dbg_messages.@types")

local capture = require("lib.buf_win_tab.capture")
local utils = require("mappings.dbg_messages.utils")

local M = {}

local api = vim.api

--------------------------------------------------------------------------------
-- State tracking
--------------------------------------------------------------------------------

---@type DbgMsgs.WindowRegistry
---@diagnostic disable-next-line: unused-local
local WINDOWS = {
  messages = nil,
  noice_all = nil,
  noice_errors = nil,
}

--------------------------------------------------------------------------------
-- Core primitives
--------------------------------------------------------------------------------

---@param win integer
---@param attempts integer
---@param retry_delay integer
local function focus_and_bottom(win, attempts, retry_delay)
  -- CRITICAL: Validate window exists and is valid
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

  -- Ensure deterministic focus and cursor visibility
  utils.make_focusable(win)
  utils.force_focus(win)

  -- Additional validation after focus attempt
  if not api.nvim_win_is_valid(win) then
    return
  end

  local ok_buf, buf = pcall(api.nvim_win_get_buf, win)
  if not ok_buf or not api.nvim_buf_is_valid(buf) then
    return
  end

  local last = api.nvim_buf_line_count(buf)

  -- Logical cursor position
  pcall(api.nvim_win_set_cursor, win, { last, 0 })

  -- Visual scroll (required for log buffers)
  vim.cmd("normal! G")

  -- Async-safe retry (content may grow)
  utils.ensure_bottom(win, attempts, retry_delay)
end

---@param tag string
---@return integer|nil
local function find_window_by_tag(tag)
  for _, win in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_is_valid(win) then
      local win_tag = vim.w[win] and vim.w[win].custom_tag or nil

      if win_tag == tag then
        -- Additional check: ensure it's a content window
        local ok_config, config = pcall(api.nvim_win_get_config, win)
        if ok_config and config.relative ~= "win" and config.width > 1 and config.height > 1 then
          return win
        end
      end
    end
  end
  return nil
end

---@param win integer
---@return string|nil
local function get_window_tag(win)
  if not api.nvim_win_is_valid(win) then
    return nil
  end
  return vim.w[win] and vim.w[win].custom_tag or nil
end

--------------------------------------------------------------------------------
-- Command execution with window reuse
--------------------------------------------------------------------------------

---@param tag string
---@param cmd string
---@param attempts integer
---@param retry_delay integer
local function execute_and_refresh(tag, cmd, attempts, retry_delay)
  local existing_win = find_window_by_tag(tag)

  if existing_win and api.nvim_win_is_valid(existing_win) then
    -- Reuse existing window: make focusable, focus, execute command, scroll to bottom
    utils.make_focusable(existing_win)
    utils.force_focus(existing_win)
    vim.cmd(cmd)
    vim.defer_fn(function()
      if api.nvim_win_is_valid(existing_win) then
        focus_and_bottom(existing_win, attempts, retry_delay)
      end
    end, 50)
    return
  end

  -- Create new window via capture
  capture.capture(cmd, {
    timeout = 500,
    tag = { buf = tag, win = tag },
  }, function(result)
    for _, win in ipairs(result.wins or {}) do
      if api.nvim_win_is_valid(win) then
        ---@diagnostic disable-next-line: unused-local
        WINDOWS[tag] = win

        -- CRITICAL: Make window focusable immediately after creation
        utils.make_focusable(win)

        -- Add explicit delay to ensure UI stabilization
        vim.defer_fn(function()
          if api.nvim_win_is_valid(win) then
            focus_and_bottom(win, attempts, retry_delay)
          end
        end, 30)
      end
    end
  end)
end
--------------------------------------------------------------------------------
-- Refresh logic for existing windows
--------------------------------------------------------------------------------

---@param win integer
---@param tag string
---@param attempts integer
---@param retry_delay integer
local function refresh_log_view(win, tag, attempts, retry_delay)
  if not api.nvim_win_is_valid(win) then
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

--------------------------------------------------------------------------------
-- Setup helpers
--------------------------------------------------------------------------------

---@param timings DbgMsgs.Timings
---@param km DbgMsgs.Keymaps
local function setup_keymaps(timings, km)
  km.map("n", "<lt>m", function()
    execute_and_refresh("messages", "messages", timings.attempts, timings.retry_delay_ms)
  end, {
    desc = "[General] Open :messages (deterministic, auto-bottom)",
    nowait = true,
    silent = true,
  })

  km.map("n", "<lt>n", function()
    execute_and_refresh("noice_all", "Noice all", timings.attempts, timings.retry_delay_ms)
  end, {
    desc = "[Noice] All (deterministic, auto-bottom)",
    silent = true,
  })

  km.map("n", "<lt>e", function()
    execute_and_refresh("noice_errors", "Noice errors", timings.attempts, timings.retry_delay_ms)
  end, {
    desc = "[Noice] Errors (deterministic, auto-bottom)",
    silent = true,
  })
end

---@param timings DbgMsgs.Timings
---@param ac DbgMsgs.Autocmds
local function setup_autocmds(timings, ac)
  local AUG = api.nvim_create_augroup(ac.group_name, { clear = true })

  -- Refresh when entering tagged log windows
  api.nvim_create_autocmd("WinEnter", {
    group = AUG,
    desc = "Refresh tagged log window on WinEnter",
    callback = function()
      local win = api.nvim_get_current_win()
      local tag = get_window_tag(win)
      if not tag then
        return
      end

      vim.defer_fn(function()
        if api.nvim_win_is_valid(win) and api.nvim_get_current_win() == win then
          refresh_log_view(win, tag, timings.attempts, timings.retry_delay_ms)
        end
      end, 30)
    end,
  })

  -- Fallback for newly attached windows
  api.nvim_create_autocmd("BufWinEnter", {
    group = AUG,
    desc = "Refresh tagged log window on BufWinEnter",
    callback = function(ev)
      local win = vim.fn.bufwinid(ev.buf)
      if win == -1 then
        return
      end

      local tag = get_window_tag(win)
      if not tag then
        return
      end

      vim.defer_fn(function()
        if api.nvim_win_is_valid(win) then
          refresh_log_view(win, tag, timings.attempts, timings.retry_delay_ms)
        end
      end, 30)
    end,
  })

  -- Hook for capture module
  api.nvim_create_autocmd("User", {
    group = AUG,
    pattern = "BufWinCapture",
    desc = "Ensure cursor at bottom after capture",
    callback = function(ev)
      for _, win in ipairs(ev.data and ev.data.wins or {}) do
        if api.nvim_win_is_valid(win) then
          utils.ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
        end
      end
    end,
  })

  -- Auto-refresh messages window when :messages updates
  api.nvim_create_autocmd("CmdlineLeave", {
    group = AUG,
    pattern = "*",
    desc = "Auto-refresh messages window after command",
    callback = function()
      local messages_win = find_window_by_tag("messages")
      if messages_win and api.nvim_win_is_valid(messages_win) then
        vim.defer_fn(function()
          if api.nvim_win_is_valid(messages_win) then
            refresh_log_view(messages_win, "messages", timings.attempts, timings.retry_delay_ms)
          end
        end, 100)
      end
    end,
  })
end

--------------------------------------------------------------------------------
-- Public setup
--------------------------------------------------------------------------------

---@param cfg DbgMsgs.Setup|nil
function M.setup(cfg)
  cfg = cfg or {}

  local timings = vim.tbl_extend("force", {
    delay_messages_ms = 30,
    delay_noice_ms = 50,
    retry_delay_ms = 60,
    attempts = 3,
  }, cfg.timings or {}) ---@as DbgMsgs.Timings

  local km = vim.tbl_extend("force", {
    enable = true,
    map = vim.keymap and vim.keymap.set or function() end,
  }, cfg.keymaps or {}) ---@as DbgMsgs.Keymaps

  local ac = vim.tbl_extend("force", {
    enable = true,
    group_name = "AutoBottomMessagesNoice",
  }, cfg.autocmds or {}) ---@as DbgMsgs.Autocmds

  if km.enable then
    setup_keymaps(timings, km)
  end

  if ac.enable then
    setup_autocmds(timings, ac)
  end
end

return M
