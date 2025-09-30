---@module 'sessions/init'
---@brief Entry point that composes sessions modules and exposes a minimal API.
---@description
--- This module is intentionally thin. Requiring it triggers setup of commands, keymaps,
--- and autocmds. It also exposes a small, explicit API should other modules need to interact
--- with sessions programmatically.

---@class SessionsAPI
local M = {}

local autocmds = require("sessions.autocmds")
local usercmds = require("sessions.usercmds")
local keymaps = require("sessions.keymaps")
--- Save a session (wrapper around core.sav
--- e).
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

--- Enable Autocommands, Usercommands and Keymaps for sessions
---@param cfg EnableConfig
---@return nil
function M.enable(cfg)
  if not cfg then return end
	if cfg.autocommands then autocmds.enable() end
	if cfg.usercmds then usercmds.enable() end
	if cfg.keymaps then keymaps.enable() end
end

return M

