---@module 'lib'
--- Aggregator module that re-exports single-function utilities under one namespace.

local M = {
  -- Re-export functions returned by their respective modules.
  is_wsl = require("lib.is_wsl"),
  text = require("lib.text"),
  require_dir = require("lib.require_dir"),
}

return M
