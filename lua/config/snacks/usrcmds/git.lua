---@module 'config.snacks.usrcmds.git'
---@brief Git-related snacks usercommands
---@description
--- This module provides usercommands for git-related snacks.nvim picker features
--- like branches, log, status, stash, and diff.

local usercmd = require("lib.usercmd")
local notify = require("lib.notify").create("[config.snacks.usrcmds.git]")

local M = {}

---@type config.snacks.usrcmds.GitOpts
M.default_opts = {
  enabled = true,
  branches = true,
  log = true,
  log_line = true,
  status = true,
  stash = true,
  diff = true,
  log_file = true,
}

---Safely call a snacks picker function
---@param picker_name string Name of the picker (e.g., "git_branches")
---@param args? table Optional arguments to pass to the picker
---@return boolean success
---@private
local function safe_picker_call(picker_name, args)
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    notify.error("snacks.nvim not available")
    return false
  end

  if type(snacks.picker) ~= "table" then
    notify.error("snacks.picker not available")
    return false
  end

  local picker_fn = snacks.picker[picker_name]
  if type(picker_fn) ~= "function" then
    notify.error(("snacks.picker.%s is not a function"):format(picker_name))
    return false
  end

  local call_ok, err = pcall(picker_fn, args)
  if not call_ok then
    notify.error(("snacks.picker.%s failed: %s"):format(picker_name, err))
    return false
  end

  return true
end

---Register git-related commands
---@param opts config.snacks.usrcmds.GitOpts
function M.register(opts)
  opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

  if not opts.enabled then
    return
  end

  -- Git Branches
  if opts.branches then
    usercmd.create("SnacksGitBranches", function()
      safe_picker_call("git_branches")
    end, {
      desc = "[snacks] Git branches picker",
      nargs = 0,
    })
  end

  -- Git Log
  if opts.log then
    usercmd.create("SnacksGitLog", function()
      safe_picker_call("git_log")
    end, {
      desc = "[snacks] Git log picker",
      nargs = 0,
    })
  end

  -- Git Log Line
  if opts.log_line then
    usercmd.create("SnacksGitLogLine", function()
      safe_picker_call("git_log_line")
    end, {
      desc = "[snacks] Git log line picker",
      nargs = 0,
    })
  end

  -- Git Status
  if opts.status then
    usercmd.create("SnacksGitStatus", function()
      safe_picker_call("git_status")
    end, {
      desc = "[snacks] Git status picker",
      nargs = 0,
    })
  end

  -- Git Stash
  if opts.stash then
    usercmd.create("SnacksGitStash", function()
      safe_picker_call("git_stash")
    end, {
      desc = "[snacks] Git stash picker",
      nargs = 0,
    })
  end

  -- Git Diff
  if opts.diff then
    usercmd.create("SnacksGitDiff", function()
      safe_picker_call("git_diff")
    end, {
      desc = "[snacks] Git diff (hunks) picker",
      nargs = 0,
    })
  end

  -- Git Log File
  if opts.log_file then
    usercmd.create("SnacksGitLogFile", function()
      safe_picker_call("git_log_file")
    end, {
      desc = "[snacks] Git log file picker",
      nargs = 0,
    })
  end
end

return M
