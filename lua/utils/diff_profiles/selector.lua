---@module 'utils.diff_profiles.selector'
-- @description
-- This module provides functionality to set different diff profiles in Neovim.

local diff_profiles = require("utils.diff_profiles.profiles")

---@param profile DiffProfile
local function set (profile)
  local opts = diff_profiles[profile]

  if not opts then
    error(("Unknown diff profile: %s"):format(profile))
  end

  -- Join list into a valid diffopt string
  vim.o.diffopt = table.concat(opts, ",")
end

return set
