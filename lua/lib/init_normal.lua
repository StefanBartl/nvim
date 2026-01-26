---@module 'lib'
--- Aggregator module that re-exports single-function utilities under one namespace.

local LIB = {}

-- === NVIM ===
LIB.simple_echo = require("lib.nvim.simple_echo")
LIB.has_exec = require("lib.nvim").has_exec

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
LIB.run_argv = require("lib.cross.run_argv")
-- Clipboard
LIB.copy_to_clipboard = require("lib.cross.copy_to_clipboard")

-- === FUNCTIONS ===

LIB.noop = require("lib.functions.meta").noop
LIB.identity = require("lib.functions.meta").identity
LIB.always_true = require("lib.functions.meta").always_true
LIB.always_false = require("lib.functions.meta").always_false
LIB.const = require("lib.functions.meta").const
LIB.raise  = require("lib.functions.meta").raise

-- === FILESYSTEM ===
local fs_path = require("lib.fs.path")
LIB.joinpath = fs_path.joinpath
LIB.ensure_dir = fs_path.ensure_dir

LIB.is_subpath = require("lib.fs.is_subpath")
LIB.is_dir = require("lib.fs.is_dir")
LIB.relpath = require("lib.fs.relpath")
LIB.find_upward_dir = require("lib.fs.find_upward_dir")
LIB.path_shorten = require("lib.fs.path_shorten")
LIB.write_to_file = require("lib.fs.write.to_file")

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
LIB.count_lines = strings.count_lines

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
LIB.map = require("lib.map")
LIB.usercmd = require("lib.usercmd")

-- === NOTIFY ===
LIB.notify = require("lib.notify")
LIB.resolve_log_level = require("lib.notify.resolve_log_level")

-- === LAZY ===
LIB.lazy = require("lib.lazy")

-- === JSON ===
LIB.json = require("lib.json")
LIB.json.is_array_like = require("lib.json.decode.to_string_array").is_array_like
LIB.json.ensure_string_array = require("lib.json.decode.to_string_array").ensure_string_array
LIB.json.table_to_string_array =require("lib.json.decode.to_string_array").table_to_string_array

-- === MEMO ===
LIB.memo = require("lib.memo")

-- === TIME ===
LIB.time_diff = require("lib.time.diff")

-- === NORMALIZE ===
LIB.normalize = require("lib.normalize")

---@type Lib
return LIB
