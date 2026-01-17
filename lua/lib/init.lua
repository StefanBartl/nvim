---@module 'lib'
--- Aggregator module that re-exports single-function utilities under one namespace.

-- FIX: Sollte alle funktionen der lib exportieren

local M = {
  -- Re-export functions returned by their respective modules.

  -- Platform Detection
  is_windows = require("lib.cross.platform.is_windows"),
  is_wsl = require("lib.cross.platform.is_wsl"),
  is_macos = require("lib.cross.platform.is_macos"),
  is_linux = require("lib.cross.platform.is_linux"),
  is = require("lib.cross.platform.is"),

  text = require("lib.text"),
  require_dir = require("lib.require").dir,
  os = require("lib.os"), -- FIX: mix ups mit lib.cross auflösen. ws sind wirkliche cross plattform funktionen? welche hingegen beziehen sich auf das aktuelle OS (wie die 'is_ funktionen')?
}

return M
