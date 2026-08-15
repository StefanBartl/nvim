---@module 'wkdoptions.set_diff_profile.profiles'
---@description
-- This module defines different diff profiles for Neovim.

---@type table<DiffProfile, string[]>
local diff_profiles = {

  -- Minimal, fast diff with least context
  minimal = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "linematch:60",
    "algorithm:histogram",
    "indent-heuristic",
    "iwhite",
  },

  -- Reduced context for quick reviews
  context = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "context:3",
    "linematch:60",
    "algorithm:patience",
    "indent-heuristic",
    "iwhite",
  },

  -- Standard review profile with moderate context
  review = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "context:8",
    "linematch:80",
    "algorithm:histogram",
    "indent-heuristic",
    "iwhite",
  },

  -- Strict profile showing all changes in detail
  strict = {
    "internal",
    "filler",
    "closeoff",
    "vertical",
    "linematch:80",
    "algorithm:myers",
    "indent-heuristic",
  },
}

return diff_profiles
