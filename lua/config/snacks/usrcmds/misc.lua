---@module 'config.snacks.usrcmds.misc'
---@brief Miscellaneous snacks usercommands
---@description
--- This module provides usercommands for miscellaneous snacks.nvim features
--- like file explorer, notifications, and command history.

local usercmd = require("lib.nvim.usercmd")
local notify = require("lib.nvim.notify").create("[config.snacks.usrcmds.misc]")

local M = {}

---@type config.snacks.usrcmds.MiscOpts
M.default_opts = {
  enabled = true,
  explorer = true,
  notifications = true,
  command_history = true,
}

---Safely call a snacks function
---@param module_path string Path to snacks module (e.g., "explorer")
---@param args? table Optional arguments to pass
---@return boolean success
---@private
local function safe_snacks_call(module_path, args)
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    notify.error("snacks.nvim not available")
    return false
  end

  -- Navigate to the correct module function
  local fn = snacks
  for part in module_path:gmatch("[^.]+") do
    if type(fn) ~= "table" then
      notify.error(("Invalid snacks path: %s"):format(module_path))
      return false
    end
    fn = fn[part]
  end

  if type(fn) ~= "function" then
    notify.error(("snacks.%s is not a function"):format(module_path))
    return false
  end

  local call_ok, err = pcall(fn, args)
  if not call_ok then
    notify.error(("snacks.%s failed: %s"):format(module_path, err))
    return false
  end

  return true
end

---Register miscellaneous commands
---@param opts config.snacks.usrcmds.MiscOpts
function M.register(opts)
  opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

  if not opts.enabled then
    return
  end

  -- Explorer
  if opts.explorer then
    usercmd.create("SnacksExplorer", function()
      safe_snacks_call("explorer")
    end, {
      desc = "[snacks] Open file explorer",
      nargs = 0,
    })
  end

  -- Notifications
  if opts.notifications then
    usercmd.create("SnacksNotifications", function()
      safe_snacks_call("picker.notifications")
    end, {
      desc = "[snacks] Open notification history",
      nargs = 0,
    })
  end

  -- Command History
  if opts.command_history then
    usercmd.create("SnacksCommandHistory", function()
      safe_snacks_call("picker.command_history")
    end, {
      desc = "[snacks] Open command history picker",
      nargs = 0,
    })
  end
end

return M
