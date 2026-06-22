---@module 'config.snacks.usrcmds.github'
---@brief GitHub-related snacks usercommands
---@description
--- This module provides usercommands for GitHub-related snacks.nvim picker features
--- like issues and pull requests.

local usercmd = require("lib.nvim.usercmd")
local notify = require("lib.nvim.notify").create("[config.snacks.usrcmds.github]")

local M = {}

---@type config.snacks.usrcmds.GithubOpts
M.default_opts = {
  enabled = true,
  issues = true,
  issues_all = true,
  prs = true,
  prs_all = true,
}

---Safely call a snacks picker function
---@param picker_name string Name of the picker (e.g., "gh_issue")
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

---Register GitHub-related commands
---@param opts config.snacks.usrcmds.GithubOpts
function M.register(opts)
  opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

  if not opts.enabled then
    return
  end

  -- GitHub Issues (open)
  if opts.issues then
    usercmd.create("SnacksGithubIssues", function()
      safe_picker_call("gh_issue")
    end, {
      desc = "[snacks] GitHub issues (open) picker",
      nargs = 0,
    })
  end

  -- GitHub Issues (all)
  if opts.issues_all then
    usercmd.create("SnacksGithubIssuesAll", function()
      safe_picker_call("gh_issue", { state = "all" })
    end, {
      desc = "[snacks] GitHub issues (all) picker",
      nargs = 0,
    })
  end

  -- GitHub Pull Requests (open)
  if opts.prs then
    usercmd.create("SnacksGithubPRs", function()
      safe_picker_call("gh_pr")
    end, {
      desc = "[snacks] GitHub pull requests (open) picker",
      nargs = 0,
    })
  end

  -- GitHub Pull Requests (all)
  if opts.prs_all then
    usercmd.create("SnacksGithubPRsAll", function()
      safe_picker_call("gh_pr", { state = "all" })
    end, {
      desc = "[snacks] GitHub pull requests (all) picker",
      nargs = 0,
    })
  end
end

return M
