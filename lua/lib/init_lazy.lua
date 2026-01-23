---@module 'lib'
--- Lazy-loaded aggregator for lib utilities.
--- Modules are only loaded when first accessed.

---@class Lib
local LIB = {}

-- ============================================================================
-- Lazy Loading Setup
-- ============================================================================

---Create a lazy-loading proxy for a module
---@param module_path string
---@return any
local function lazy_module(module_path)
  local loaded = nil
  return setmetatable({}, {
    __index = function(_, key)
      if not loaded then
        loaded = require(module_path)
      end
      return loaded[key]
    end,
    __call = function(_, ...)
      if not loaded then
        loaded = require(module_path)
      end
      if type(loaded) == "function" then
        return loaded(...)
      end
      error(string.format("Module '%s' is not callable", module_path))
    end
  })
end

-- ============================================================================
-- Core Utilities (always loaded - frequently used)
-- ============================================================================

-- Lazy and memo are used internally, so load them eagerly
LIB.lazy = require("lib.lazy")
LIB.memo = require("lib.memo")

-- ============================================================================
-- Lazy-loaded Modules
-- ============================================================================

-- === NVIM ===
LIB.simple_echo = lazy_module("lib.nvim.simple_echo")

-- === CROSS-PLATFORM ===
LIB.is_windows = lazy_module("lib.cross.platform.is_windows")
LIB.is_wsl = lazy_module("lib.cross.platform.is_wsl")
LIB.is_macos = lazy_module("lib.cross.platform.is_macos")
LIB.is_linux = lazy_module("lib.cross.platform.is_linux")
LIB.is = lazy_module("lib.cross.platform.is")

-- Run
do
  local cross_run
  LIB.shell = function()
    cross_run = cross_run or require("lib.cross.run")
    return cross_run.shell()
  end
  LIB.run = function(...)
    cross_run = cross_run or require("lib.cross.run")
    return cross_run.run(...)
  end
  LIB.run_blocking = function(...)
    cross_run = cross_run or require("lib.cross.run")
    return cross_run.run_blocking(...)
  end
end

-- === Clipboard ===
LIB.copy_to_clipboard = lazy_module("lib.cross.copy_to_clipboard")

-- === FUNCTIONS ===

LIB.noop = lazy_module("lib.functions.meta").noop
LIB.identity = lazy_module("lib.functions.meta").identity
LIB.always_true = lazy_module("lib.functions.meta").always_true
LIB.always_false = lazy_module("lib.functions.meta").always_false
LIB.const = lazy_module("lib.functions.meta").const
LIB.raise  = lazy_module("lib.functions.meta").raise

-- === FILESYSTEM ===
do
  local fs_path
  LIB.joinpath = function(...)
    fs_path = fs_path or require("lib.fs.path")
    return fs_path.joinpath(...)
  end
  LIB.ensure_dir = function(...)
    fs_path = fs_path or require("lib.fs.path")
    return fs_path.ensure_dir(...)
  end
end

LIB.is_subpath = lazy_module("lib.fs.is_subpath")
LIB.is_dir = lazy_module("lib.fs.is_dir")
LIB.relpath = lazy_module("lib.fs.relpath")
LIB.find_upward_dir = lazy_module("lib.fs.find_upward_dir")
LIB.path_shorten = lazy_module("lib.fs.path_shorten")

-- === REQUIRE ===
do
  local lib_require
  LIB.require_safe = function(...)
    lib_require = lib_require or require("lib.require")
    return lib_require.safe(...)
  end
  LIB.require_dir = function(...)
    lib_require = lib_require or require("lib.require")
    return lib_require.dir(...)
  end
  LIB.require_lazy = function(...)
    lib_require = lib_require or require("lib.require")
    return lib_require.lazy(...)
  end
end

-- === BUFFER ===
LIB.is_markdown_buf = lazy_module("lib.buffer.is_markdown_buf")
LIB.insert_lines = lazy_module("lib.buffer.insert_lines")

-- === TABLES ===
LIB.with = lazy_module("lib.tables.with")

-- Table submodules (lazy proxies)
LIB.array = lazy_module("lib.tables.array")
LIB.core = lazy_module("lib.tables.core")
LIB.dict = lazy_module("lib.tables.dict")
LIB.set = lazy_module("lib.tables.set")
LIB.functional = lazy_module("lib.tables.functional")
LIB.safe = lazy_module("lib.tables.safe")

-- === JSON ===
LIB.json_is_array_like = lazy_module("lib.json.decode.to_string_array").is_array_like
LIB.json_ensure_string_array = lazy_module("lib.json.decode.to_string_array").ensure_string_array
LIB.json_table_to_string_array = lazy_module("lib.json.decode.to_string_array").table_to_string_array

-- === STRINGS ===
-- Strings module is frequently used, but we still lazy-load it
do
  local strings
  local function get_strings()
    strings = strings or require("lib.strings")
    return strings
  end

  -- Export strings module
  LIB.strings = setmetatable({}, {
    __index = function(_, key)
      return get_strings()[key]
    end
  })

  -- Individual string functions (lazy-loaded)
  LIB.trim = function(...) return get_strings().trim(...) end
  LIB.slugify = function(...) return get_strings().slugify(...) end
  LIB.kebab_case = function(...) return get_strings().kebab_case(...) end
  LIB.starts_with = function(...) return get_strings().starts_with(...) end
  LIB.ends_with = function(...) return get_strings().ends_with(...) end
  LIB.contains = function(...) return get_strings().contains(...) end
  LIB.split = function(...) return get_strings().split(...) end
  LIB.join = function(...) return get_strings().join(...) end
  LIB.replace_all = function(...) return get_strings().replace_all(...) end
  LIB.capitalize = function(...) return get_strings().capitalize(...) end
  LIB.uncapitalize = function(...) return get_strings().uncapitalize(...) end
  LIB.snake_case = function(...) return get_strings().snake_case(...) end
  LIB.camel_case = function(...) return get_strings().camel_case(...) end
  LIB.pad_start = function(...) return get_strings().pad_start(...) end
  LIB.pad_end = function(...) return get_strings().pad_end(...) end
  LIB.pad_center = function(...) return get_strings().pad_center(...) end
  LIB.indent = function(...) return get_strings().indent(...) end
  LIB.dedent = function(...) return get_strings().dedent(...) end
  LIB.is_empty_or_space = function(...) return get_strings().is_empty_or_space(...) end
  LIB.remove_prefix = function(...) return get_strings().remove_prefix(...) end
  LIB.uri_decode = function(...) return get_strings().uri_decode(...) end
  LIB.normalize_anchor = function(...) return get_strings().normalize_anchor(...) end
  LIB.has_scheme = function(...) return get_strings().has_scheme(...) end
  LIB.is_web_url = function(...) return get_strings().is_web_url(...) end
  LIB.url_under_cursor = function(...) return get_strings().url_under_cursor(...) end
  LIB.escape_lua_magic = function(...) return get_strings().escape_lua_magic(...) end
  LIB.find_plain = function(...) return get_strings().find_plain(...) end
  LIB.replace_plain = function(...) return get_strings().replace_plain(...) end
  LIB.surround = function(...) return get_strings().surround(...) end
end

LIB.hex_to_string = lazy_module("lib.strings.convert.hex_to_string")

-- === TERMINAL ===
do
  local terminal
  LIB.terminal_escape = function(...)
    terminal = terminal or require("lib.terminal")
    return terminal.escape(...)
  end
  LIB.is_terminal_buf = function(...)
    terminal = terminal or require("lib.terminal")
    return terminal.is_terminal_buf(...)
  end
  LIB.delete_terminal_buf = function(...)
    terminal = terminal or require("lib.terminal")
    return terminal.delete_terminal_buf(...)
  end
end

-- === UI ===
LIB.hover_select = lazy_module("lib.ui.hover_select")
LIB.hl = lazy_module("lib.ui.hl")

-- === AUTOCMD/KEYMAP ===
LIB.autocmd = lazy_module("lib.autocmd")
LIB.augroup = lazy_module("lib.autocmd.augroup")
LIB.map = lazy_module("lib.map")
LIB.usercmd = lazy_module("lib.usercmd")

-- === NOTIFY ===
LIB.notify = lazy_module("lib.notify")
LIB.resolve_log_level = lazy_module("lib.notify.resolve_log_level")

-- === TIME ===
LIB.time_diff = lazy_module("lib.time.diff")

-- === NORMALIZE ===
LIB.normalize = lazy_module("lib.normalize")

---@type Lib
return LIB
