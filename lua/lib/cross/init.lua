---@module 'lib.cross'
---Cross-platform utilities for Neovim/Lua
---Provides platform detection, path normalization, and shell helpers

local M = {}

-- Platform Detection
M.is_windows = require("lib.cross.platform.is_windows")
M.is_wsl = require("lib.cross.platform.is_wsl")
M.is_macos = require("lib.cross.platform.is_macos")
M.is_linux = require("lib.cross.platform.is_linux")
M.is = require("lib.cross.platform.is")

-- Filesystem
M.fs = {
  cwd = require("lib.cross.fs._cwd"),
  has_win_sep = require("lib.cross.fs.separators.has_win_sep"),
  normalize = require("lib.cross.fs.separators.normalize"),
}

-- UV/Loop compatibility
M.uv = {
  spawn_command = require("lib.cross.uv.spawn_command"),
  spawn_shell_command = require("lib.cross.uv.spawn_shell_command"),
}

return M
