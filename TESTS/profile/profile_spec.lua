-- TESTS/profile/profile_spec.lua -- `profile` resolution (NVIM_PROFILE > state file > "full"),
-- `set()` validation, and `apply_cleanup()`: lazy.clean runs exactly once after a switch to
-- "enterprise", never for "full", and the applied profile is recorded.

return function(H)
  local eq, ok = H.eq, H.ok

  local saved = {
    env_profile = vim.env.NVIM_PROFILE,
    env_state = vim.env.XDG_STATE_HOME,
    lazy = package.loaded["lazy"],
    profile = package.loaded["profile"],
  }

  local cleans = 0
  package.loaded["lazy"] = {
    clean = function()
      cleans = cleans + 1
    end,
  }

  ---@return table
  local function fresh()
    package.loaded["profile"] = nil
    return require("profile")
  end

  local done, err = pcall(function()
    vim.env.XDG_STATE_HOME = H.tmpdir()
    vim.env.NVIM_PROFILE = nil

    local p = fresh()
    eq(p.name(), "full", "no env, no state file: full")
    eq(p.origin(), "default", "origin of the fallback")

    local set_ok = p.set("Enterprise")
    ok(set_ok, "a known profile is stored (case-insensitive)")
    ok(not p.set("nope"), "an unknown profile is rejected")
    eq(p.name(), "full", "set() does not change the running session")

    p = fresh()
    eq(p.name(), "enterprise", "the state file is read on the next start")
    eq(p.origin(), "state", "origin of the stored value")

    vim.env.NVIM_PROFILE = "full"
    p = fresh()
    eq(p.name(), "full", "NVIM_PROFILE wins over the state file")
    eq(p.origin(), "env", "origin of the env value")

    p.apply_cleanup()
    eq(cleans, 0, "full after full: nothing to clean")

    vim.env.NVIM_PROFILE = "enterprise"
    p = fresh()
    p.apply_cleanup()
    eq(cleans, 1, "switch to enterprise cleans once")
    p.apply_cleanup()
    eq(cleans, 1, "second start with the same profile does not clean again")

    vim.env.NVIM_PROFILE = "full"
    p = fresh()
    p.apply_cleanup()
    eq(cleans, 1, "switch back to full cleans nothing (lazy reinstalls missing plugins)")
  end)

  vim.env.NVIM_PROFILE = saved.env_profile
  vim.env.XDG_STATE_HOME = saved.env_state
  package.loaded["lazy"] = saved.lazy
  package.loaded["profile"] = saved.profile
  if not done then
    error(err, 0)
  end
end
