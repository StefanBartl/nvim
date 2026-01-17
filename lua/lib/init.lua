--- AUDIT: notwenig und wenn ja, safe call? oder eigener folder und init?
---@module 'lib'
--- Aggregator module that re-exports single-function utilities under one namespace.

local M = {
  -- Re-export functions returned by their respective modules.

  -- Platform Detection
  is_windows = require("lib.cross.platform.is_windows"),
  is_wsl = require("lib.cross.plattform.is_wsl"),
  is_macos = require("lib.cross.platform.is_macos"),
  is_linux = require("lib.cross.platform.is_linux"),
  is = require("lib.cross.platform.is"),

  text = require("lib.text"),
  require_dir = require("lib.require_dir"),
  os = require("lib.os"),
}

return M
