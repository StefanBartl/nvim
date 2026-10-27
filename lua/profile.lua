---@module 'profile'
---@brief Config profile switch: "full" (everything) or "enterprise" (no AI, no third-party APIs).
---@description
--- The profile decides which personal plugins a corporate machine may load. Unlike
--- `machine` (where am I?), it answers "what is allowed here?", so the two are
--- independent: a workstation can run "full" for a test, a home PC "enterprise".
---
--- Resolution, first hit wins:
---   1. `NVIM_PROFILE` environment variable (case-insensitive), e.g. `setx NVIM_PROFILE enterprise`
---   2. the state file written by `:Profile <name>` (`stdpath("state")/profile`)
---   3. "full"
---
--- What "enterprise" turns off lives in plugins/personal/core/source.lua (ENTERPRISE_OFF):
--- the specs get `enabled = false` there. On the first start after a switch,
--- `M.apply_cleanup()` lets lazy delete the now-disabled plugins from the data
--- folder; switching back needs nothing, lazy's `install.missing` clones them again.
--- The lockfile is shared: lazy keeps the entries of disabled plugins.

local M = {}

local notify = require("lib.nvim.notify").create("[profile]")

---@alias ConfigProfile "full"|"enterprise"

---@type table<string, boolean>
M.PROFILES = { full = true, enterprise = true }

local STATE_FILE = vim.fn.stdpath("state") .. "/profile"
-- Profile whose plugin set the data folder currently holds (written after a cleanup).
local APPLIED_FILE = vim.fn.stdpath("state") .. "/profile_applied"

---@param path string
---@return string|nil
local function read_word(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local word = (f:read("*l") or ""):match("^%s*(%S+)")
  f:close()
  return word and word:lower() or nil
end

---@param path string
---@param word string
---@return boolean ok
local function write_word(path, word)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = io.open(path, "w")
  if not f then
    return false
  end
  f:write(word, "\n")
  f:close()
  return true
end

---@type ConfigProfile
local profile = "full"
---@type "env"|"state"|"default"
local origin = "default"

do
  local env_value = vim.env.NVIM_PROFILE
  local stored = read_word(STATE_FILE)
  if type(env_value) == "string" and env_value ~= "" then
    if M.PROFILES[env_value:lower()] then
      profile, origin = env_value:lower(), "env"
    else
      notify.warn(("Unknown NVIM_PROFILE '%s', ignored"):format(env_value))
    end
  end
  if origin == "default" and stored and M.PROFILES[stored] then
    profile, origin = stored, "state"
  end
end

---@return ConfigProfile
function M.name()
  return profile
end

---@return "env"|"state"|"default"
function M.origin()
  return origin
end

---@param p ConfigProfile
---@return boolean
function M.is(p)
  return profile == p
end

--- Store the profile for the next start (does not change the running session:
--- the specs are evaluated once at startup).
---@param p string
---@return boolean ok
---@return string|nil err
function M.set(p)
  p = p:lower()
  if not M.PROFILES[p] then
    return false, ("unknown profile '%s'"):format(p)
  end
  if not write_word(STATE_FILE, p) then
    return false, "cannot write " .. STATE_FILE
  end
  return true
end

--- After a switch: remove the plugins the active profile disables. No-op when the
--- data folder already matches. A missing APPLIED_FILE means "full" (the state
--- before this switch existed), so the first "full" start deletes nothing.
function M.apply_cleanup()
  local applied = read_word(APPLIED_FILE) or "full"
  if applied == profile then
    return
  end
  -- "full" disables nothing beyond the per-repo table, so only a switch to a
  -- narrower profile has anything to clean.
  if profile ~= "full" then
    require("lazy").clean({ wait = false, show = false })
    notify.info(("'%s' active: removing disabled plugins from the data folder"):format(profile))
  end
  write_word(APPLIED_FILE, profile)
end

return M
