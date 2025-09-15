---@module 'mappings.dbg_messages'
--- Ensure bottom-of-buffer for :messages and Noice views, including the very first open.
--- This module exposes a single public setup() function and keeps all helpers private.
--- It provides configurable retry/delay timings and optional keymap registration.
--- Configuration and dependencies (e.g. keymap setter) can be injected for testability.
---
--- Design goals:
---   - Strong guards for buffer/window handles in async callbacks
---   - No global state; autocmd group is created inside setup()
---   - Configurable delays/retries instead of magic numbers
---   - Fully annotated API for LuaLS/EmmyLua users

---@version 1.1.0

---@alias Win integer           # Neovim window id
---@alias Buf integer           # Neovim buffer id

---@class DbgMessagesKeymaps
---@field enable boolean        # Register default keymaps or not
---@field map fun(mode:string,lhs:string,rhs:fun(),opts:table)  # Injection point; defaults to vim.keymap.set

---@class DbgMessagesAutocmds
---@field enable boolean        # Create FileType/BufWinEnter autocmds
---@field group_name string     # Name of the autocmd group

---@class DbgMessagesTimings
---@field delay_messages_ms integer   # Initial nudge for :messages window
---@field delay_noice_ms integer      # Initial nudge for Noice windows
---@field retry_delay_ms integer      # Delay between ensure_bottom retries
---@field attempts integer            # Max number of retries

---@class DbgMessagesSetup
---@field keymaps DbgMessagesKeymaps|nil
---@field autocmds DbgMessagesAutocmds|nil
---@field timings DbgMessagesTimings|nil

local M = {}

-- ============================================================================
-- Private helpers
-- ============================================================================

-- Forward declarations keep private helpers local and readable
---@private
---@param win Win
---@return boolean
---@diagnostic disable-next-line
local function at_bottom(win) return false end

---@private
---@param win Win
---@param row integer
---@return boolean
---@diagnostic disable-next-line
local function safe_win_set_cursor(win, row) return false end

---@private
---@param buf Buf
---@return boolean
---@diagnostic disable-next-line
local function is_target_view(buf) return false end

---@private
---@param win Win|0|nil
---@param attempts integer
---@param retry_delay integer
---@return nil
---@diagnostic disable-next-line
local function ensure_bottom(win, attempts, retry_delay) end

-- Check if window cursor already sits at the last line
---@private
---@param win Win
---@return boolean
function at_bottom(win)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return true
  end
  local ok_buf, buf = pcall(vim.api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return true
  end
  local last = vim.api.nvim_buf_line_count(buf)
  local row = vim.api.nvim_win_get_cursor(win)[1]
  return row >= last
end

-- Set cursor to a target row safely; protects against invalid handles
---@private
---@param win Win
---@param row integer
---@return boolean
function safe_win_set_cursor(win, row)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return false
  end
  local ok_buf, buf = pcall(vim.api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return false
  end
  return pcall(vim.api.nvim_win_set_cursor, win, { row, 0 })
end

-- Identify :messages or Noice buffers by filetype/name; hardened with pcall
---@private
---@param buf Buf
---@return boolean
function is_target_view(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return false
  end
  local ok_ft, ft = pcall(function() return vim.bo[buf].filetype end)
  if ok_ft and (ft == "messages" or ft == "noice") then
    return true
  end
  local name = (vim.api.nvim_buf_get_name(buf) or ""):lower()
  return name:find("messages", 1, true) ~= nil or name:find("noice", 1, true) ~= nil
end

-- Move cursor to bottom with a few retries to tolerate late content arrival
---@private
---@param win Win|0|nil  # 0 = current window
---@param attempts integer
---@param retry_delay integer
---@return nil
function ensure_bottom(win, attempts, retry_delay)
  win = win or 0
  attempts = attempts or 1
  retry_delay = retry_delay or 60

  if attempts <= 0 or not vim.api.nvim_win_is_valid(win) then
    return
  end

  local ok_buf, buf = pcall(vim.api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end

  local last = math.max(1, vim.api.nvim_buf_line_count(buf))
  safe_win_set_cursor(win, last)

  if not at_bottom(win) then
    vim.defer_fn(function()
      ensure_bottom(win, attempts - 1, retry_delay)
    end, retry_delay)
  end
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Configure module and (optionally) register keymaps and autocmds.
---@param cfg DbgMessagesSetup|nil
---@return nil
function M.setup(cfg)
  cfg = cfg or {}

  -- Timings (defaults mirror the working values from earlier iterations)
  local timings = vim.tbl_extend("force", {
    delay_messages_ms = 30,
    delay_noice_ms = 50,
    retry_delay_ms = 60,
    attempts = 3,
  }, cfg.timings or {}) ---@as DbgMessagesTimings

  -- Keymap injection/fallback
  local km = vim.tbl_extend("force", {
    enable = true,
    map = vim.keymap and vim.keymap.set or function() end,
  }, cfg.keymaps or {}) ---@as DbgMessagesKeymaps

  -- Autocmd control
  local ac = vim.tbl_extend("force", {
    enable = true,
    group_name = "AutoBottomMessagesNoice",
  }, cfg.autocmds or {}) ---@as DbgMessagesAutocmds

  -- Register keymaps (optional)
  if km.enable then
    km.map("n", "<lt>m", function()
      vim.cmd("messages")
      vim.defer_fn(function()
        ensure_bottom(0, timings.attempts, timings.retry_delay_ms)
      end, timings.delay_messages_ms)
    end, { desc = "[General] Open :messages at bottom", nowait = true, silent = true })

    km.map("n", "<lt>n", function()
      vim.cmd("Noice all")
      vim.defer_fn(function()
        ensure_bottom(0, timings.attempts, timings.retry_delay_ms)
      end, timings.delay_noice_ms)
    end, { desc = "[Noice] All (auto-bottom)", silent = true })

    km.map("n", "<lt>e", function()
      vim.cmd("Noice errors")
      vim.defer_fn(function()
        ensure_bottom(0, timings.attempts, timings.retry_delay_ms)
      end, timings.delay_noice_ms)
    end, { desc = "[Noice] Errors (auto-bottom)", silent = true })
  end

  -- Create autocmds (optional)
  if ac.enable then
    local AUG = vim.api.nvim_create_augroup(ac.group_name, { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = AUG,
      pattern = { "messages", "noice" },
      desc = "Auto-bottom when :messages/Noice filetype is set",
      callback = function(ev)
        vim.defer_fn(function()
          local wins = vim.fn.win_findbuf(ev.buf) ---@type integer[]
          for i = 1, #wins do
            ensure_bottom(wins[i], timings.attempts, timings.retry_delay_ms)
          end
        end, 30)
      end,
    })

    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = AUG,
      desc = "Fallback auto-bottom for :messages/Noice on BufWinEnter",
      callback = function(ev)
        if is_target_view(ev.buf) then
          vim.schedule(function()
            ensure_bottom(0, timings.attempts, timings.retry_delay_ms)
          end)
        end
      end,
    })
  end
end

return M
