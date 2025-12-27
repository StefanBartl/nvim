---@module 'mappings.dbg_messages'
--- Ensure bottom-of-buffer for :messages and Noice views without disturbing editor windows.
--- Avoids races by always addressing concrete window ids (never win=0 in async callbacks).

local utils = require("lua.mappings.dbg_messages.utils")

local M = {}

local api = vim.api
local nvim_get_current_win, nvim_win_is_valid = api.nvim_get_current_win, api.nvim_win_is_valid
local defer_fn = vim.defer_fn
local ensure_bottom = utils.ensure_bottom

--- Configure module and register keymaps/autocmds
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
    km.map("n", "<lt>m", function()
      vim.cmd("messages")
      -- SOFORT ins Fenster springen
      local win = nvim_get_current_win()
      local buf = api.nvim_win_get_buf(win)
      local last = api.nvim_buf_line_count(buf)

      -- Cursor SOFORT ans Ende setzen
      pcall(api.nvim_win_set_cursor, win, { last, 0 })

      -- Zusätzlich mit defer_fn für Inhalte, die später kommen
      defer_fn(function()
        if nvim_win_is_valid(win) then
          ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
        end
      end, timings.delay_messages_ms)
    end, { desc = "[General] Open :messages at bottom", nowait = true, silent = true })

    km.map("n", "<lt>n", function()
      vim.cmd("Noice all")
      -- SOFORT ins Fenster springen
      local win = nvim_get_current_win()
      local buf = api.nvim_win_get_buf(win)
      local last = api.nvim_buf_line_count(buf)

      -- Cursor SOFORT ans Ende setzen
      pcall(api.nvim_win_set_cursor, win, { last, 0 })

    defer_fn(function()
        if nvim_win_is_valid(win) then
          ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
        end
      end, timings.delay_noice_ms)
    end, { desc = "[Noice] All (auto-bottom)", silent = true })

    km.map("n", "<lt>e", function()
      vim.cmd("Noice errors")
      -- SOFORT ins Fenster springen
      local win = nvim_get_current_win()
      local buf = api.nvim_win_get_buf(win)
      local last = api.nvim_buf_line_count(buf)

      -- Cursor SOFORT ans Ende setzen
      pcall(api.nvim_win_set_cursor, win, { last, 0 })

      defer_fn(function()
        if nvim_win_is_valid(win) then
          ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
        end
      end, timings.delay_noice_ms)
    end, { desc = "[Noice] Errors (auto-bottom)", silent = true })
  end

  if ac.enable then
    local AUG = api.nvim_create_augroup(ac.group_name, { clear = true })

    api.nvim_create_autocmd("FileType", {
      group = AUG,
      pattern = { "messages", "noice" },
      desc = "Auto-bottom when :messages/Noice filetype is set",
      callback = function(ev)
        defer_fn(function()
          local wins = vim.fn.win_findbuf(ev.buf) ---@type integer[]
          for i = 1, #wins do
            ensure_bottom(wins[i], timings.attempts, timings.retry_delay_ms)
          end
        end, 30)
      end,
    })

    api.nvim_create_autocmd("BufWinEnter", {
      group = AUG,
      desc = "Fallback auto-bottom for :messages/Noice on BufWinEnter",
      callback = function(ev)
        if not utils.is_target_view(ev.buf) then
          return
        end
        local win = ev.win or nvim_get_current_win()
        vim.schedule(function()
          if nvim_win_is_valid(win) then
            ensure_bottom(win, timings.attempts, timings.retry_delay_ms)
          end
        end)
      end,
    })
  end
end

return M
