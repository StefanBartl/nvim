---@module 'wkdoptions.set_diff_profile.selector'
--- Sets the active diff profile in Neovim.

local lazy = require("lib.lua.lazy")
local diff_profiles = lazy.require("wkdoptions.set_diff_profile.profiles")

---@param profile DiffProfile
local function set(profile)
  local opts = diff_profiles[profile]

  if not opts then
    error(("Unknown diff profile: %s"):format(profile))
  end

  -- Join list into a valid diffopt string
  vim.o.diffopt = table.concat(opts, ",")
end

return set
