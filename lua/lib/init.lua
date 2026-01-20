---@module 'lib'
--- Aggregator module that re-exports single-function utilities under one namespace.
-- FIX: Sollte alle funktionen der lib exportieren

---@class OsShell
---@field prog string        -- executable to spawn (e.g. "sh" or "powershell")
---@field args string[]      -- arguments vector (no command yet)
---@field is_powershell boolean

---@class OsRunResult
---@field code integer
---@field signal integer
---@field stdout string
---@field stderr string

---@alias Lib.Cross.Platform.PlatformName
---| '"windows"'
---| '"wsl"'
---| '"macos"'
---| '"linux"'

---@class Lib
--- Lib.Cross.Platform
---@field is_windows fun(): boolean # returns true if corrent os is windows
---@field is_wsl fun(): boolean # returns true if corrent os is wsl
---@field is_macos fun(): boolean # returns true if corrent os is macos
---@field is_linux fun(): boolean # returns true if corrent os is linux
---@field is fun(): Lib.Cross.Platform.PlatformName # This module returns a single function with dual behavior:
---| 1) When called without arguments, it returns the current platform as a string
---| 2) When called with a platform name, it returns whether the current platform matches it
-- Lib.Cross.Run
---@field shell fun(): OsShell # Pick a shell suitable for the platform
---@field run fun(cmd: string, cb: fun(ok:boolean, res:OsRunResult): nil): nil # Async run using vim.system when available; falls back to jobstart
---@field run_blocking fun(cmd: string): OsRunResult # Blocking run (utility for quick conversions / probing)
---Lib.Cross.CopyToClipboard
---@field copy_to_clipboard fun(text: string): boolean # Copy text to system clipboard using platform-appropriate backend
---
---Lib.Fs.Path
---@field joinpath fun(parts: string[]): string # Joins variable strings to one path
---@field ensure_dir fun(path: string): boolean, string? # ensure directory for a given path exists; returns true on success.
---
--- Lib.Require
---@field require_safe fun(name: string): boolean, any # Safe require with structured error handling
---@field require_dir fun(dir: string, calls?: string|string[]|""): nil # Load all modules in a directory
---@field require_lazy fun(module_name: string): fun(): table # Lazy-loading wrapper
---
---
--- Lib.Buffer
---@field is_markdown_buf fun(bufnr_arg: integer|nil): integer|nil # Returns the current buffer number if the buffer is a valid loaded markdown buffer
---
--- Lib.Tables
---@field with fun(base: table|nil, extra: table|nil): table # Utility to merge two option tables. Returns a new table if base is nil
---
--- Lib.terminal
---@field terminal_escape fun(path: string): string # Cross-platform path escaping for terminal commands
---@field is_terminal_buf fun(bufnr: integer): boolean|nil # Checks if buffer is a terminal buffer
---@field delete_terminal_buf fun(bufnr: integer): boolean|nil # deletes a terminal buffer
---
---
--- Lib.Nvim
---@field simple_echo fun(msg: string, hl: string|nil, is_error: boolean|nil): integer|string # This module returns a single function that echoes messages using vim.api.nvim_echo

---@type Lib
local M = {

  simple_echo = require("lib.nvim.simple_echo"),

  --- === CROSS ===
  -- Platform Detection
  is_windows = require("lib.cross.platform.is_windows"),
  is_wsl = require("lib.cross.platform.is_wsl"),
  is_macos = require("lib.cross.platform.is_macos"),
  is_linux = require("lib.cross.platform.is_linux"),
  is = require("lib.cross.platform.is"),
  -- Run
  shell = require("lib.cross.run").shell,
  run = require("lib.cross.run").run,
  run_blocking = require("lib.cross.run").run_blocking,
  -- Copy to clipboard
  copy_to_clipboard = require("lib.cross.copy_to_clipboard"),

  -- === FS ===
  -- Path
  joinpath = require("lib.fs.path").joinpath,
  ensure_dir = require("lib.fs.path").ensure_dir,

  -- === REQUIRE ===
  require_safe = require("lib.require").safe,
  require_dir = require("lib.require").dir,
  require_lazy = require("lib.require").lazy,

  -- === FS ===
  is_markdown_buf = require("lib.buffer.is_markdown_buf"),

  -- === TABLES ===
  with = require("lib.tables.with"),

  -- === TERMINAL ===
  terminal_escape = require("lib.terminal").escape,
  is_terminal_buf = require("lib.terminal").is_terminal_buf,
  delete_terminal_buf = require("lib.terminal").delete_terminal_buf,
}

return M
