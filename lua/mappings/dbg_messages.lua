---@module 'mappings.dbg_messages'
--- Ensure bottom-of-buffer for :messages and Noice views without disturbing editor windows.
--- Avoids races by always addressing concrete window ids (never win=0 in async callbacks).

---@alias Win integer
---@alias Buf integer

---@class DbgMessagesKeymaps
---@field enable boolean
---@field map fun(mode:string,lhs:string,rhs:fun(),opts:table)

---@class DbgMessagesAutocmds
---@field enable boolean
---@field group_name string

---@class DbgMessagesTimings
---@field delay_messages_ms integer
---@field delay_noice_ms integer
---@field retry_delay_ms integer
---@field attempts integer

---@class DbgMessagesSetup
---@field keymaps DbgMessagesKeymaps|nil
---@field autocmds DbgMessagesAutocmds|nil
---@field timings DbgMessagesTimings|nil

local M = {}

-- Forward decls
---@private
---@param win Win
---@return boolean
---@diagnostic disable-next-line
local function at_bottom(win)
  return false
end

---@private
---@param win Win
---@param row integer
---@return boolean
---@diagnostic disable-next-line
local function safe_win_set_cursor(win, row)
  return false
end

---@private
---@param buf Buf
---@return boolean
---@diagnostic disable-next-line
local function is_target_view(buf)
  return false
end

---@private
---@param win Win
---@param attempts integer
---@param retry_delay integer
---@diagnostic disable-next-line
local function ensure_bottom(win, attempts, retry_delay) end

-- Check if window cursor already sits at the last line
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

-- Set cursor to target row in a specific window
function safe_win_set_cursor(win, row)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return false
  end
  local ok_buf, buf = pcall(vim.api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return false
  end
  return pcall(vim.api.nvim_win_set_cursor, win, { math.max(1, row), 0 })
end

-- Identify messages/noice buffers strictly by filetype (avoid filename heuristics)
function is_target_view(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return false
  end
  local ok_ft, ft = pcall(function()
    return vim.bo[buf].filetype
  end)
  if not ok_ft then
    return false
  end
  if ft == "messages" then
    return true
  end
  if ft == "noice" then
    local ok_bt, bt = pcall(function()
      return vim.bo[buf].buftype
    end)
    return ok_bt and (bt == "nofile" or bt == "")
  end
  return false
end

-- Move cursor to bottom with retries for late content
function ensure_bottom(win, attempts, retry_delay)
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  attempts = attempts or 1
  retry_delay = retry_delay or 60

  local ok_buf, buf = pcall(vim.api.nvim_win_get_buf, win)
  if not ok_buf or not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end

  local last = math.max(1, vim.api.nvim_buf_line_count(buf))
  safe_win_set_cursor(win, last)

  if attempts > 1 and not at_bottom(win) then
    vim.defer_fn(function()
      if win and vim.api.nvim_win_is_valid(win) then
        ensure_bottom(win, attempts - 1, retry_delay)
      end
    end, retry_delay)
  end
end

--- Configure module and register keymaps/autocmds
---@param cfg DbgMessagesSetup|nil
function M.setup(cfg)
  cfg = cfg or {}

  local timings = vim.tbl_extend("force", {
    delay_messages_ms = 30,
    delay_noice_ms = 50,
    retry_delay_ms = 60,
    attempts = 3,
  }, cfg.timings or {}) ---@as DbgMessagesTimings

  local km = vim.tbl_extend("force", {
    enable = true,
    map = vim.keymap and vim.keymap.set or function() end,
  }, cfg.keymaps or {}) ---@as DbgMessagesKeymaps

  local ac = vim.tbl_extend("force", {
    enable = true,
    group_name = "AutoBottomMessagesNoice",
  }, cfg.autocmds or {}) ---@as DbgMessagesAutocmds

  if km.enable then
    km.map("n", "<lt>m", function()
      vim.cmd("messages")
      local win = vim.api.nvim_get_current_win() -- capture new window
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
          ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
        end
      end, timings.delay_messages_ms)
    end, { desc = "[General] Open :messages at bottom", nowait = true, silent = true })

    km.map("n", "<lt>n", function()
      vim.cmd("Noice all")
      local win = vim.api.nvim_get_current_win()
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
          ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
        end
      end, timings.delay_noice_ms)
    end, { desc = "[Noice] All (auto-bottom)", silent = true })

    km.map("n", "<lt>e", function()
      vim.cmd("Noice errors")
      local win = vim.api.nvim_get_current_win()
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
          ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
        end
      end, timings.delay_noice_ms)
    end, { desc = "[Noice] Errors (auto-bottom)", silent = true })
  end

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
        if not is_target_view(ev.buf) then
          return
        end
        ---@diagnostic disable-next-line
        local win = ev.win or vim.api.nvim_get_current_win()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(win) then
            ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
          end
        end)
      end,
    })
  end
end

return M
