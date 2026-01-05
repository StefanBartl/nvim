---@module 'debugging.views'
---Unified debug views: :messages, Noice, with capture, display, window management
require("debugging.views.@types")

local capture = require("debugging.views.capture")
local display = require("debugging.views.display")
local keymaps = require("debugging.views.keymaps")
local autocmds = require("debugging.views.autocmds")

local M = {}

---@param opts Dbg.Views.Modules|nil
function M.setup(opts)
  opts = opts or {}

  -- Timings defaults
  local timings = vim.tbl_extend("force", {
    delay_messages_ms = 30,
    delay_noice_ms = 50,
    retry_delay_ms = 60,
    attempts = 3,
  }, opts.timings or {})

  -- Keymaps defaults
  local km = vim.tbl_extend("force", {
    enable = true,
    map = vim.keymap and vim.keymap.set or function() end,
    prefix = "<lt>", -- default prefix, "<leader>d" oder "<lt>"
  }, opts.keymaps or {})

  -- Autocmds defaults
  local ac = vim.tbl_extend("force", {
    enable = true,
    group_name = "DebugViewsAuto",
    auto_refresh = true,
  }, opts.autocmds or {})

  -- Keymaps nur registrieren, wenn aktiviert
  if km.enable then
    keymaps.setup(km, timings)
  end

  -- Autocmds nur registrieren, wenn aktiviert
  if ac.enable then
    autocmds.setup(ac, timings)
  end

  -- Capture Commands nur registrieren, wenn opts.capture vorhanden
  if opts.capture ~= false then
    if opts.capture and opts.capture.output_dir then
      capture.base_dir = opts.capture.output_dir
    end

    vim.api.nvim_create_user_command("DebugMessagesCapture", function()
      capture.capture_messages({ debug = false })
    end, { desc = "[Debug] Capture :messages to file+clipboard" })
  end

  -- Display Commands
  if opts.capture ~= false then
    vim.api.nvim_create_user_command("DebugMessagesShow", function()
      display.execute_and_refresh("messages", "messages", timings)
    end, { desc = "[Debug] Show messages window" })
  end

  -- Clear windows
  if opts.capture ~= false then
    vim.api.nvim_create_user_command("DebugWindowsClear", function()
      display.clear_all()
    end, { desc = "[Debug] Clear all debug windows" })
  end
end

return M
