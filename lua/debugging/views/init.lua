---@module 'debugging.views'
---Unified debug views: :messages, Noice, with capture, display, window management
require("debugging.views.@types")

local capture = require("debugging.views.capture")
local display = require("debugging.views.display")
local keymaps = require("debugging.views.keymaps")
local autocmds = require("debugging.views.autocmds")

local M = {}

---@param cfg DebugViews.Setup|nil
function M.setup(cfg)
  cfg = cfg or {}

  local timings = vim.tbl_extend("force", {
    delay_messages_ms = 30,
    delay_noice_ms = 50,
    retry_delay_ms = 60,
    attempts = 3,
  }, cfg.timings or {})

  local km = vim.tbl_extend("force", {
    enable = true,
    map = vim.keymap and vim.keymap.set or function() end,
    -- prefix = "<leader>d",
     prefix = "<lt>",
  }, cfg.keymaps or {})

  local ac = vim.tbl_extend("force", {
    enable = true,
    group_name = "DebugViewsAuto",
    auto_refresh = true,
  }, cfg.autocmds or {})

  keymaps.setup(km, timings)
  autocmds.setup(ac, timings)

  vim.api.nvim_create_user_command("DebugMessagesCapture", function()
    capture.capture_messages({ debug = false })
  end, { desc = "[Debug] Capture :messages to file+clipboard" })

  vim.api.nvim_create_user_command("DebugMessagesShow", function()
    display.execute_and_refresh("messages", "messages", timings)
  end, { desc = "[Debug] Show messages window" })

  vim.api.nvim_create_user_command("DebugWindowsClear", function()
    display.clear_all()
  end, { desc = "[Debug] Clear all debug windows" })
end

return M

