---@module 'usrcmds.migrate.notify.refactor'
---@brief Main refactor orchestrator

local import = require("usrcmds.migrate.notify.refactor.import")
local cleanup = require("usrcmds.migrate.notify.refactor.cleanup")
local apply = require("usrcmds.migrate.notify.refactor.apply")

local M = {}

-- Re-export functions
M.inject_import = import.inject
M.remove_aliases = cleanup.remove_aliases
M.apply_match = apply.apply_match

return M
