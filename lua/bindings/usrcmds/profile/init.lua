---@module 'bindings.usrcmds.profile'
---@brief `:Profile [full|enterprise]` -- show or switch the config profile (see lua/profile.lua).
---@description
--- Without an argument it shows the active profile and where it came from. With one it
--- stores the profile for the next start; the running session keeps its plugin set, since
--- the specs are evaluated once at startup. `NVIM_PROFILE` wins over the stored value, so
--- switching while it is set only warns.

local usercmd = require("lib.nvim.bindings.usercmd")
local notify = require("lib.nvim.notify").create("[Profile]")
local profile = require("profile")

local M = {}

function M.enable()
  usercmd.create("Profile", function(args)
    local wanted = vim.trim(args.args or "")
    if wanted == "" then
      notify.info(("active: %s (from %s)"):format(profile.name(), profile.origin()))
      return
    end
    local ok, err = profile.set(wanted)
    if not ok then
      notify.error(err or "failed")
      return
    end
    if profile.origin() == "env" then
      notify.warn(("stored '%s', but NVIM_PROFILE=%s still wins"):format(wanted, profile.name()))
      return
    end
    notify.info(("'%s' stored, restart Neovim to apply"):format(wanted:lower()))
  end, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(profile.PROFILES)
    end,
    desc = "Show or switch the config profile (full|enterprise); applies on the next start",
  })
end

return M
