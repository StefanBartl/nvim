---@module 'custom.filecycle.usercommands'
require("lua.custom.filecycle.@types")

local api = vim.api
local notify = require("lib.notify").create("[filecycle]")
local core = require("custom.filecycle.core")

local M = {}

---@param opts FileCycle.Config
---@return nil
function M.enable(opts)
  -- User commands with -bang to allow forced edit
  api.nvim_create_user_command("NextFile", function(cmdopts)
    local dir, err = core.get_root_dir(M.opts)
    if not dir then
      notify.warn("[filecycle] " .. (err or "no directory"))
      return
    end
    -- If bang, temporarily disable confirm and force edit!
    if cmdopts.bang then
      local prev = opts.confirm_on_modified
      opts.confirm_on_modified = false
      local ok1 = core.navigate(dir, "next", opts)
      if not ok1 and prev ~= nil then
        opts.confirm_on_modified = prev
      end
      -- force write of changed buffer is deliberately not done here
      return
    end
    core.navigate(dir, "next", opts)
  end, { desc = "Open next file in current directory", bang = true })

  api.nvim_create_user_command("PreviousFile", function(cmdopts)
    local dir, err = core.get_root_dir(opts)
    if not dir then
      notify.warn("[filecycle] " .. (err or "no directory"))
      return
    end
    if cmdopts.bang then
      local prev = opts.confirm_on_modified
      opts.confirm_on_modified = false
      local ok1 = core.navigate(dir, "prev", opts)
      if not ok1 and prev ~= nil then
        opts.confirm_on_modified = prev
      end
      return
    end
    core.navigate(dir, "prev", opts)
  end, { desc = "Open previous file in current directory", bang = true })
end

return M
