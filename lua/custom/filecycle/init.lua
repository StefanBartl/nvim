---@module 'custom.filecycle'
--- Navigate to the next/previous file in the current buffer's directory.
--- This module provides user commands and keymaps with count support.

local notify = require("lib.notify").create("[custom.filecycle]")

local DEFAULTS = {
  open_target = "current",
  keep_focus = true,
  include_hidden = false,
  wrap = true,
  follow_symlinks = true,
  root = "buffer_dir",
  confirm_on_modified = true,
  case_insensitive = true,
}

---@type FileCycle.State
local M = { opts = DEFAULTS, DEFAULTS = DEFAULTS }

--- Setup module options and create user commands & keymaps.
---@param user_opts FileCycle.Config|nil
---@return nil
function M.setup(user_opts)
  user_opts = user_opts or {}
  -- Merge options (shallow copy)
  local o = {} ---@type FileCycle.Config
  o.open_target = (user_opts.open_target ~= nil) and user_opts.open_target or DEFAULTS.open_target
  o.keep_focus = (user_opts.keep_focus ~= nil) and user_opts.keep_focus or DEFAULTS.keep_focus
  o.include_hidden = (user_opts.include_hidden ~= nil) and user_opts.include_hidden or DEFAULTS.include_hidden
  o.wrap = (user_opts.wrap ~= nil) and user_opts.wrap or DEFAULTS.wrap
  o.follow_symlinks = (user_opts.follow_symlinks ~= nil) and user_opts.follow_symlinks or DEFAULTS.follow_symlinks
  o.root = (user_opts.root ~= nil) and user_opts.root or DEFAULTS.root
  o.confirm_on_modified = (user_opts.confirm_on_modified ~= nil) and user_opts.confirm_on_modified
    or DEFAULTS.confirm_on_modified
  o.case_insensitive = (user_opts.case_insensitive ~= nil) and user_opts.case_insensitive or DEFAULTS.case_insensitive
  o.keymaps = (user_opts.keymaps ~= nil) and user_opts.keymaps or DEFAULTS.keymaps
  o.usercommands = (user_opts.usercommands ~= nil) and user_opts.usercommands or DEFAULTS.usercommands
  M.opts = o

  if M.opts.keymaps then
    require("custom.filecycle.keymaps").attach(M.opts)
  end

  if M.opts.usercommands then
    require("custom.filecycle.usercommands").enable(M.opts)
  end
end

--- Programmatic API: open next/prev with explicit options and count.
---@param mode FileCycle.Direction
---@param opts FileCycle.Config|nil
---@param count integer? Number of steps (default: 1)
---@return boolean ok
function M.open(mode, opts, count)
  local o = opts and vim.tbl_deep_extend("force", M.opts, opts) or M.opts
  if not o then
    notify.warn("[NextPrev] Config is nil")
    return false
  end

  local core = require("custom.filecycle.core")
  local dir, err = core.get_root_dir(o)
  if not dir then
    notify.warn("[NextPrev] " .. (err or "no directory"))
    return false
  end

  return core.navigate(dir, mode, o, count)
end

return M
