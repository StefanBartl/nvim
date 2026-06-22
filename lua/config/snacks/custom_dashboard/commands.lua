---@module 'config.snacks.custom_dashboard.commands'
--- Dashboard-specific commands and keymaps.
--- Keep mappings local, minimal, and guarded.

local notify = require("lib.nvim.notify").create("[config.snacks.custom_dashboard.commands]")

local api = vim.api
local utils_ok, utils = pcall(require, "config.snacks.custom_dashboard.utils")
if not utils_ok then
  -- Do not fail startup; just skip commands if utils missing
  return {}
end

local M = {}

--- Register user commands that help interact with the custom dashboard.
--- Commands are idempotent and guarded.
function M.setup_commands()
  local create_cmd = api.nvim_create_user_command
  if type(create_cmd) ~= "function" then
    return
  end

  -- Example: :SnacksOpen -> open the snacks dashboard if available and safe
  create_cmd("SnacksOpen", function()
    local ok_dash, dash = pcall(require, "snacks.dashboard")
    if not ok_dash or type(dash.open) ~= "function" then
      notify.warn("[custom_dashboard] snacks.dashboard not available")
      return
    end
    -- Only open when safe according to utilities
    local bufnr = vim.api.nvim_get_current_buf()
    if not utils.is_special_buf(bufnr) and utils.is_modifiable(bufnr) and utils.is_empty_buffer(bufnr) then
      pcall(dash.open)
    else
      notify.info("[custom_dashboard] unsafe to open dashboard in current buffer")
    end
  end, { desc = "Open Snacks custom dashboard (safe)" })

  -- Example: :SnacksSessionsReload -> clears session cache
  create_cmd("SnacksSessionsReload", function()
    local ok_sess, sessions = pcall(require, "config.snacks.custom_dashboard.sessions")
    if ok_sess and type(sessions.clear_cache) == "function" then
      sessions.clear_cache()
      notify.debug("[custom_dashboard] session cache cleared")
    else
      notify.warn("[custom_dashboard] sessions module not available")
    end
  end, { desc = "Clear sessions cache used by the dashboard" })
end

--- Setup function invoked by init.lua
function M.setup()
  local ok, _ = pcall(M.setup_commands)
  if not ok then
    -- swallow but notify
    notify.error("[custom_dashboard] failed to register commands")
  end
end

-- Attempt to setup eagerly but do not error on require-time failure.
pcall(M.setup)

return M
