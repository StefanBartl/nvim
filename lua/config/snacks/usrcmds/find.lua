---@module 'config.snacks.usrcmds.find'
---@brief Find-related snacks usercommands
---@description
--- This module provides usercommands for find-related snacks.nvim picker features
--- like finding files, buffers, git files, recent files, and projects.

local usercmd = require("lib.usercmd")
local notify = require("lib.notify").create("[config.snacks.usrcmds.find]")

local M = {}

---@type config.snacks.usrcmds.FindOpts
M.default_opts = {
  enabled = true,
  buffers = true,
  files = true,
  git_files = true,
  config = true,
  recent = true,
  projects = true,
}

---Safely call a snacks picker function
---@param picker_name string Name of the picker (e.g., "files", "buffers")
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

---Register find-related commands
---@param opts config.snacks.usrcmds.FindOpts
function M.register(opts)
  opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

  if not opts.enabled then
    return
  end

  -- Buffers
  if opts.buffers then
    usercmd.create("SnacksFindBuffers", function()
      safe_picker_call("buffers")
    end, {
      desc = "[snacks] Find buffers",
      nargs = 0,
    })
  end

  -- Files
  if opts.files then
    usercmd.create("SnacksFindFiles", function()
      safe_picker_call("files")
    end, {
      desc = "[snacks] Find files",
      nargs = 0,
    })
  end

  -- Git Files
  if opts.git_files then
    usercmd.create("SnacksFindGitFiles", function()
      safe_picker_call("git_files")
    end, {
      desc = "[snacks] Find git files",
      nargs = 0,
    })
  end

  -- Config Files
  if opts.config then
    usercmd.create("SnacksFindConfig", function()
      safe_picker_call("files", { cwd = vim.fn.stdpath("config") })
    end, {
      desc = "[snacks] Find config files",
      nargs = 0,
    })
  end

  -- Recent Files
  if opts.recent then
    usercmd.create("SnacksFindRecent", function()
      safe_picker_call("recent")
    end, {
      desc = "[snacks] Find recent files",
      nargs = 0,
    })
  end

  -- Projects
  if opts.projects then
    usercmd.create("SnacksFindProjects", function()
      safe_picker_call("projects")
    end, {
      desc = "[snacks] Find projects",
      nargs = 0,
    })
  end
end

return M
