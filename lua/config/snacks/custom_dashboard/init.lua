---@module 'config.snacks.custom_dashboard.init'
--- Public entrypoint for the modular custom Snacks dashboard.
--- Ensures sections are registered before calling snacks.setup(opts).

local M = {}
M.module_tag = "[snacks.custom_dashboard]: "

-- prefer lib.safe_require.safe_require if available; fallback to simple pcall wrapper
local ok_lib, lib = pcall(require, "lib.safe_require")
local function safe_require(name)
  if ok_lib and type(lib.safe_require) == "function" then
    local ok, res = lib.safe_require(name)
    return ok, res
  end
  local ok, mod = pcall(require, name)
  if not ok then
    return false, mod
  end
  return true, mod
end

--- Setup function called from the plugin spec.
--- @param snacks table -- the snacks module object
--- @param opts table|nil
--- @return boolean, string|nil
function M.setup(snacks, opts)
  if type(snacks) ~= "table" then
    return false, "invalid snacks module"
  end

  local ok_utils, utils = safe_require("config.snacks.custom_dashboard.utils")
  if not ok_utils then
    return false, "utils missing"
  end

  -- sessions module optional but register sections early
  local ok_sess, sessions = safe_require("config.snacks.custom_dashboard.sessions")
  if not ok_sess then
    vim.notify(M.module_tag .. "sessions module not available; Sessions section will show placeholder", vim.log.levels.INFO)
  end

  -- sections must register the custom section before snacks.setup
  local ok_secs, sections = safe_require("config.snacks.custom_dashboard.sections")
  if not ok_secs then
    return false, "sections missing"
  end

  -- non-blocking: commands, autocmds, mappings
  safe_require("config.snacks.custom_dashboard.commands")
  safe_require("config.snacks.custom_dashboard.autocmds")
  safe_require("config.snacks.custom_dashboard.mappings")

  -- finally call snacks.setup; the section is already registered by sections.lua
  local ok_setup, err = pcall(snacks.setup, opts or {})
  if not ok_setup then
    return false, tostring(err)
  end

  M.utils = utils
  M.sessions = (ok_sess and sessions) and sessions or nil
  M.sections = sections

  return true
end

return M
