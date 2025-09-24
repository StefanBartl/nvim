---@module 'sessions/init'
---@brief Entry point that composes sessions modules and exposes a minimal API.
---@description
--- This module is intentionally thin. Requiring it triggers setup of commands, keymaps,
--- and autocmds. It also exposes a small, explicit API should other modules need to interact
--- with sessions programmatically.

---@class SessionsAPI
local M = {}

-- Import order per project rules:
-- 1) core libs (vim, uv) – implicit
-- 2) debug/notify – here we rely on vim.notify only
-- 3) config and utils
-- 4) state (none required)
-- 5) UI (commands) – defines user commands, maps, autocommands

local ok_cmds, _ = pcall(require, "sessions.commands")
if not ok_cmds then
  vim.notify("[sessions] failed to initialize commands", vim.log.levels.ERROR)
end

--- Save a session (wrapper around core.save).
---@param name string|nil
---@return boolean, string|nil
function M.save(name)
  return require("sessions.core").save(name)
end

--- Load a session (wrapper around core.load).
---@param name string|nil
---@return boolean, string|nil
function M.load(name)
  return require("sessions.core").load(name)
end

--- List available sessions.
---@return string[]
function M.list()
  return require("sessions.core").list()
end

return M

