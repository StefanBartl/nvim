---@module 'config.snacks.usrcmds.grep'
---@brief Grep-related snacks usercommands
---@description
--- This module provides usercommands for grep-related snacks.nvim picker features
--- like grep, buffer lines, grep buffers, and grep word/selection.

local usercmd = require("lib.usercmd")
local notify = require("lib.notify").create("[config.snacks.usrcmds.grep]")

local M = {}

---@type config.snacks.usrcmds.GrepOpts
M.default_opts = {
  enabled = true,
  grep = true,
  lines = true,
  buffers = true,
  word = true,
}

---Safely call a snacks picker function
---@param picker_name string Name of the picker (e.g., "grep")
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

---Register grep-related commands
---@param opts config.snacks.usrcmds.GrepOpts
function M.register(opts)
  opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})

  if not opts.enabled then
    return
  end

  -- Grep
  if opts.grep then
    usercmd.create("SnacksGrep", function()
      safe_picker_call("grep")
    end, {
      desc = "[snacks] Grep picker",
      nargs = 0,
    })
  end

  -- Buffer Lines
  if opts.lines then
    usercmd.create("SnacksGrepLines", function()
      safe_picker_call("lines")
    end, {
      desc = "[snacks] Buffer lines picker",
      nargs = 0,
    })
  end

  -- Grep Open Buffers
  if opts.buffers then
    usercmd.create("SnacksGrepBuffers", function()
      safe_picker_call("grep_buffers")
    end, {
      desc = "[snacks] Grep open buffers picker",
      nargs = 0,
    })
  end

  -- Grep Word/Selection
  if opts.word then
    usercmd.create("SnacksGrepWord", function()
      safe_picker_call("grep_word")
    end, {
      desc = "[snacks] Grep word/selection picker",
      nargs = 0,
    })
  end
end

return M
