---@module 'custom.filecycle.usercommands'
require("custom.filecycle.@types")

local api = vim.api
local notify = require("lib.notify").create("[filecycle]")
local core = require("custom.filecycle.core")

local M = {}

--- Parse count argument from command args
---@param args string Command arguments
---@return integer count Parsed count (default: 1)
local function parse_count(args)
  if not args or args == "" then
    return 1
  end

  local count = tonumber(args)
  if not count or count < 1 then
    return 1
  end

  return math.floor(count)
end

---Parse target argument from user command
---@param arg string|nil User-provided argument
---@return "replace"|"current"|"background"|"split"|"vsplit"|"tab"
local function parse_target(arg)
  if not arg or arg == "" or arg == "%" then
    return "replace"  -- default: replace current buffer
  end

  local normalized = arg:lower()

  if normalized == "stay" then
    return "current"  -- new buffer, keep old, focus new
  elseif normalized == "new" or normalized == "bg" or normalized == "background" then
    return "background"
  elseif normalized == "split" then
    return "split"
  elseif normalized == "vsplit" then
    return "vsplit"
  elseif normalized == "tab" then
    return "tab"
  else
    return "replace"
  end
end

---@param opts FileCycle.Config
---@return nil
function M.enable(opts)
  -- NextFile: accepts target argument (%, stay, new/bg/background, split, vsplit, tab)
  api.nvim_create_user_command("NextFile", function(cmdopts)
    local dir, err = core.get_root_dir(opts)
    if not dir then
      notify.warn("[filecycle] " .. (err or "no directory"))
      return
    end

    local count = parse_count(cmdopts.args)
    local target = parse_target(cmdopts.fargs[1])

    local override = vim.tbl_extend("force", opts, { open_target = target })

    if cmdopts.bang then
      local prev = override.confirm_on_modified
      override.confirm_on_modified = false
      core.navigate(dir, "next", override, count)
      override.confirm_on_modified = prev
      return
    end

    core.navigate(dir, "next", override, count)
  end, {
    desc = "Open next file (default: replace buffer; args: %, stay, new/bg/background, split, vsplit, tab)",
    bang = true,
    nargs = "?",
    complete = function()
      return { "%", "stay", "new", "bg", "background", "split", "vsplit", "tab" }
    end
  })

  -- PreviousFile: same logic
  api.nvim_create_user_command("PreviousFile", function(cmdopts)
    local dir, err = core.get_root_dir(opts)
    if not dir then
      notify.warn("[filecycle] " .. (err or "no directory"))
      return
    end

    local count = parse_count(cmdopts.args)
    local target = parse_target(cmdopts.fargs[1])

    local override = vim.tbl_extend("force", opts, { open_target = target })

    if cmdopts.bang then
      local prev = override.confirm_on_modified
      override.confirm_on_modified = false
      core.navigate(dir, "prev", override, count)
      override.confirm_on_modified = prev
      return
    end

    core.navigate(dir, "prev", override, count)
  end, {
    desc = "Open previous file (default: replace buffer; args: %, stay, new/bg/background, split, vsplit, tab)",
    bang = true,
    nargs = "?",
    complete = function()
      return { "%", "stay", "new", "bg", "background", "split", "vsplit", "tab" }
    end
  })
end

return M
