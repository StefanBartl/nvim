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

---@param opts FileCycle.Config
---@return nil
function M.enable(opts)
  -- NextFile with count argument support
  api.nvim_create_user_command("NextFile", function(cmdopts)
    local dir, err = core.get_root_dir(opts)
    if not dir then
      notify.warn("[filecycle] " .. (err or "no directory"))
      return
    end

    local count = parse_count(cmdopts.args)

    -- If bang, temporarily disable confirm and force edit
    if cmdopts.bang then
      local prev = opts.confirm_on_modified
      opts.confirm_on_modified = false
      local ok1 = core.navigate(dir, "next", opts, count)
      if not ok1 and prev ~= nil then
        opts.confirm_on_modified = prev
      end
      return
    end

    core.navigate(dir, "next", opts, count)
  end, {
    desc = "Open next file(s) in current directory",
    bang = true,
    nargs = "?",  -- Optional count argument
    complete = function()
      return {}
    end
  })

  -- PreviousFile with count argument support
  api.nvim_create_user_command("PreviousFile", function(cmdopts)
    local dir, err = core.get_root_dir(opts)
    if not dir then
      notify.warn("[filecycle] " .. (err or "no directory"))
      return
    end

    local count = parse_count(cmdopts.args)

    if cmdopts.bang then
      local prev = opts.confirm_on_modified
      opts.confirm_on_modified = false
      local ok1 = core.navigate(dir, "prev", opts, count)
      if not ok1 and prev ~= nil then
        opts.confirm_on_modified = prev
      end
      return
    end

    core.navigate(dir, "prev", opts, count)
  end, {
    desc = "Open previous file(s) in current directory",
    bang = true,
    nargs = "?",  -- Optional count argument
    complete = function()
      return {}
    end
  })
end

return M
