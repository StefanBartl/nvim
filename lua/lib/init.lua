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
--- === Cross-Platform ===
---@field is_windows fun(): boolean # returns true if corrent os is windows
---@field is_wsl fun(): boolean # returns true if corrent os is wsl
---@field is_macos fun(): boolean # returns true if corrent os is macos
---@field is_linux fun(): boolean # returns true if corrent os is linux
---@field is fun(platform?: Lib.Cross.Platform.PlatformName): boolean|Lib.Cross.Platform.PlatformName # Dual behavior: returns platform name or boolean check
-- Lib.Cross.Run
---@field shell fun(): OsShell # Pick a shell suitable for the platform
---@field run fun(cmd: string, cb: fun(ok:boolean, res:OsRunResult): nil): nil # Async run using vim.system when available; falls back to jobstart
---@field run_blocking fun(cmd: string): OsRunResult # Blocking run (utility for quick conversions / probing)
---Lib.Cross.CopyToClipboard
---@field copy_to_clipboard fun(text: string): boolean # Copy text to system clipboard using platform-appropriate backend
---
--- === Filesystem ===
---@field find_upward_dir fun(names: string[], from: string): string|nil # Find directory containing files
---@field dedup fun(entries: string[]): string[] # Deduplicate filesystem paths
---@field path_shorten fun(path: string, max_len: integer): string # Shorten path for display
---Lib.Fs.Path
---@field joinpath fun(parts: string[]): string # Joins variable strings to one path
---@field ensure_dir fun(path: string): boolean, string? # Ensure directory exists
---@field is_subpath fun(path: string, base: string): boolean # Check if path is subpath of base
---@field is_dir fun(p: string): boolean # Check if path is a directory
---@field relpath fun(path: string, base: string): string # Compute relative path
---
--- === Require ===
---@field require_safe fun(name: string): boolean, any # Safe require with structured error handling
---@field require_dir fun(dir: string, calls?: string|string[]|""): nil # Load all modules in a directory
---@field require_lazy fun(module_name: string): fun(): table # Lazy-loading wrapper
---
--- === Buffer ===
---@field is_markdown_buf fun(bufnr_arg: integer|nil): integer|nil # Returns buffer number if valid markdown buffer
---@field insert_lines fun(lines: string[], pos?: Lib.Buf.InsertLinesPos): nil # Insert lines into buffer
---
--- === Tables ===
---@field with fun(base: table|nil, extra: table|nil): table # Merge two option tables
---@field array table # Array utilities
---@field core table # Core table utilities
---@field dict table # Dictionary utilities
---@field set table # Set utilities
---@field functional table # Functional helpers
---@field safe table # Safe table operations
---
--- === Strings ===
---@field strings Lib.Strings.ALL # All string functions
---@field trim fun(s: any): string # Trim whitespace
---@field slugify fun(s: string): string # Convert to slug
---@field kebab_case fun(s: string): string # Convert to kebab-case
---@field starts_with fun(s: string, prefix: string): boolean # Check string prefix
---@field ends_with fun(s: string, suffix: string): boolean # Check string suffix
---@field contains fun(s: string, needle: string): boolean # Check if string contains
---@field split fun(s: string, sep: string): string[] # Split string
---@field join fun(parts: string[], sep: string): string # Join strings
---@field replace_all fun(s: string, from: string, to: string): string # Replace all occurrences
---@field capitalize fun(s: string): string # Capitalize first letter
---@field uncapitalize fun(s: string): string # Uncapitalize first letter
---@field snake_case fun(s: string): string # Convert to snake_case
---@field camel_case fun(s: string): string # Convert to camelCase
---@field pad_start fun(s: string, width: integer): string # Pad string start
---@field pad_end fun(s: string, width: integer): string # Pad string end
---@field pad_center fun(s: string, width: integer): string # Pad string center
---@field indent fun(s: string, n: integer): string # Indent string
---@field dedent fun(s: string): string # Dedent string
---@field is_empty_or_space fun(s: any): boolean # Check if empty or whitespace
---@field remove_prefix fun(s: string, list?: string[]): string # Remove common prefixes
---@field uri_decode fun(s: string): string # Decode URI
---@field normalize_anchor fun(s: string): string # Normalize anchor
---@field has_scheme fun(s: string): boolean # Check if URL has scheme
---@field is_web_url fun(s: string): boolean # Check if web URL
---@field url_under_cursor fun(line: string, col: integer): string|nil # Get URL under cursor
---@field escape_lua_magic fun(s: string): string # Escape Lua pattern magic
---@field find_plain fun(s: string, needle: string): integer|nil, integer|nil # Plain string find
---@field replace_plain fun(s: string, from: string, to: string): string # Plain string replace
---@field surround fun(s: string, left: string, right: string): string # Surround string
---@field hex_to_string fun(hex: string): string # Convert hex to UTF-8 string
---
--- === Terminal ===
---@field terminal_escape fun(path: string): string # Cross-platform path escaping
---@field is_terminal_buf fun(bufnr: integer): boolean|nil # Checks if buffer is terminal
---@field delete_terminal_buf fun(bufnr: integer): boolean|nil # Deletes terminal buffer
---
--- === UI ===
---@field hover_select table # Hover select module
---@field hl table # Highlight utilities
---
--- === Autocmd/Keymap ===
---@field autocmd table # Autocmd utilities
---@field augroup table # Augroup utilities
---@field map fun(modes: string|string[], lhs: string, rhs: string|function, opts?: table, desc?: string): nil # Keymap helper
---@field usercmd table # User command utilities
---
--- === Notify ===
---@field notify table # Notification utilities
---@field resolve_log_level fun(level?: LogLevel, default?: LogLevelNumber): integer # Resolve log level
---
--- === Lazy ===
---@field lazy table # Lazy loading utilities
---
--- === Memo ===
---@field memo table # Memoization utilities
---
--- === Time ===
---@field time_diff fun(): TimeDiff # Create time diff instance
---
--- === Normalize ===
---@field normalize table # Normalization utilities
---
--- === Nvim ===
---@field simple_echo fun(msg: string, hl: string|nil, is_error: boolean|nil): integer|string # This module returns a single function that echoes messages using vim.api.nvim_echo

local LIB = {}

-- === NVIM ===
LIB.simple_echo = require("lib.nvim.simple_echo")

-- === CROSS-PLATFORM ===
LIB.is_windows = require("lib.cross.platform.is_windows")
LIB.is_wsl = require("lib.cross.platform.is_wsl")
LIB.is_macos = require("lib.cross.platform.is_macos")
LIB.is_linux = require("lib.cross.platform.is_linux")
LIB.is = require("lib.cross.platform.is")
-- Run
local cross_run = require("lib.cross.run")
LIB.shell = cross_run.shell
LIB.run = cross_run.run
LIB.run_blocking = cross_run.run_blocking
-- Clipboard
LIB.copy_to_clipboard = require("lib.cross.copy_to_clipboard")

-- === FILESYSTEM ===
local fs_path = require("lib.fs.path")
LIB.joinpath = fs_path.joinpath
LIB.ensure_dir = fs_path.ensure_dir

LIB.is_subpath = require("lib.fs.is_subpath")
LIB.is_dir = require("lib.fs.is_dir")
LIB.relpath = require("lib.fs.relpath")
LIB.find_upward_dir = require("lib.fs.find_upward_dir")
LIB.dedup = require("lib.tables.dedup")
LIB.path_shorten = require("lib.fs.path_shorten")

-- === REQUIRE ===
local lib_require = require("lib.require")
LIB.require_safe = lib_require.safe
LIB.require_dir = lib_require.dir
LIB.require_lazy = lib_require.lazy

-- === BUFFER ===
LIB.is_markdown_buf = require("lib.buffer.is_markdown_buf")
LIB.insert_lines = require("lib.buffer.insert_lines")

-- === TABLES ===
LIB.with = require("lib.tables.with")
LIB.array = require("lib.tables.array")
LIB.core = require("lib.tables.core")
LIB.dict = require("lib.tables.dict")
LIB.set = require("lib.tables.set")
LIB.functional = require("lib.tables.functional")
LIB.safe = require("lib.tables.safe")

-- === STRINGS ===
local strings = require("lib.strings")
LIB.strings = strings

-- Export individual string functions
LIB.trim = strings.trim
LIB.slugify = strings.slugify
LIB.kebab_case = strings.kebab_case
LIB.starts_with = strings.starts_with
LIB.ends_with = strings.ends_with
LIB.contains = strings.contains
LIB.split = strings.split
LIB.join = strings.join
LIB.replace_all = strings.replace_all
LIB.capitalize = strings.capitalize
LIB.uncapitalize = strings.uncapitalize
LIB.snake_case = strings.snake_case
LIB.camel_case = strings.camel_case
LIB.pad_start = strings.pad_start
LIB.pad_end = strings.pad_end
LIB.pad_center = strings.pad_center
LIB.indent = strings.indent
LIB.dedent = strings.dedent
LIB.is_empty_or_space = strings.is_empty_or_space
LIB.remove_prefix = strings.remove_prefix
LIB.uri_decode = strings.uri_decode
LIB.normalize_anchor = strings.normalize_anchor
LIB.has_scheme = strings.has_scheme
LIB.is_web_url = strings.is_web_url
LIB.url_under_cursor = strings.url_under_cursor
LIB.escape_lua_magic = strings.escape_lua_magic
LIB.find_plain = strings.find_plain
LIB.replace_plain = strings.replace_plain
LIB.surround = strings.surround
LIB.hex_to_string = require("lib.strings.convert.hex_to_string")

-- === TERMINAL ===
local terminal = require("lib.terminal")
LIB.terminal_escape = terminal.escape
LIB.is_terminal_buf = terminal.is_terminal_buf
LIB.delete_terminal_buf = terminal.delete_terminal_buf

-- === UI ===
LIB.hover_select = require("lib.ui.hover_select")
LIB.hl = require("lib.ui.hl")

-- === AUTOCMD/KEYMAP ===
LIB.autocmd = require("lib.autocmd")
LIB.augroup = require("lib.autocmd.augroup")
LIB.map = require("lib.map")
LIB.usercmd = require("lib.usercmd")

-- === NOTIFY ===
LIB.notify = require("lib.notify")
LIB.resolve_log_level = require("lib.notify.resolve_log_level")

-- === LAZY ===
LIB.lazy = require("lib.lazy")

-- === MEMO ===
LIB.memo = require("lib.memo")

-- === TIME ===
LIB.time_diff = require("lib.time.diff")

-- === NORMALIZE ===
LIB.normalize = require("lib.normalize")

---@type Lib
return LIB
