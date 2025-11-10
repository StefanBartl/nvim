---@module 'config.snacks.custom_dashboard.init'
--- Public entrypoint for the modular custom Snacks dashboard.
--- This module wires submodules (autocmds, sessions, sections, commands, utils)
--- and exposes a single `setup()` function that performs safe initialization.
--- All heavy-lifting is delegated to submodules to keep responsibilities small.

local M = {}

--- Safe require wrapper for subsystems; returns (ok, module_or_error)
---@param name string
---@return boolean, any
local function safe_require(name)
  local ok, mod = pcall(require, name)
  if not ok then
    vim.notify(string.format("[custom_dashboard] failed to require %s: %s", name, tostring(mod)), vim.log.levels.WARN)
    return false, nil
  end
  return true, mod
end

--- Initialize submodules in a robust order:
--- utils -> sessions -> sections -> commands -> autocmds
--- This order respects dependency direction: low-level helpers first.
---@return boolean, string|nil
function M.setup()
  -- load utils (required)
  local ok_utils, utils = safe_require("config.snacks.custom_dashboard.utils")
  if not ok_utils then
    return false, "utils missing"
  end

  -- load sessions (depends on utils)
  local ok_sess, sessions = safe_require("config.snacks.custom_dashboard.sessions")
  if not ok_sess then
    -- sessions are optional: still continue but warn
    vim.notify("[custom_dashboard] sessions module not available; Sessions section will be empty", vim.log.levels.INFO)
  end

  -- load sections (reads sessions, utils)
  local ok_secs, sections = safe_require("config.snacks.custom_dashboard.sections")
  if not ok_secs then
    return false, "sections missing"
  end

  -- load commands (optional)
  safe_require("config.snacks.custom_dashboard.commands")

  -- load autocmds (optional, QOL)
  safe_require("config.snacks.custom_dashboard.autocmds")

  -- expose API for external usage (if needed)
  M.utils = utils
  M.sessions = sessions
  M.sections = sections

  return true
end

return M
