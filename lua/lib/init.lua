---@module 'lib'
--- Ultra-lazy aggregator using metatable-based module proxy.
--- Nothing is loaded until first access.

---@class Lib
local LIB = {}

-- ============================================================================
-- Module Registry
-- ============================================================================

local MODULE_MAP = {
  -- NVIM
  simple_echo = "lib.nvim.simple_echo",

  -- CROSS-PLATFORM
  is_windows = "lib.cross.platform.is_windows",
  is_wsl = "lib.cross.platform.is_wsl",
  is_macos = "lib.cross.platform.is_macos",
  is_linux = "lib.cross.platform.is_linux",
  is = "lib.cross.platform.is",
  copy_to_clipboard = "lib.cross.copy_to_clipboard",
  run_argv = "lib.cross.run_argv",

  -- FILESYSTEM
  is_subpath = "lib.fs.is_subpath",
  is_dir = "lib.fs.is_dir",
  relpath = "lib.fs.relpath",
  find_upward_dir = "lib.fs.find_upward_dir",
  path_shorten = "lib.fs.path_shorten",
  write_to_file = "lib.fs.write.to_file",

  -- BUFFER
  is_markdown_buf = "lib.buffer.is_markdown_buf",
  insert_lines = "lib.buffer.insert_lines",

  -- TABLES
  with = "lib.tables.with",
  array = "lib.tables.array",
  core = "lib.tables.core",
  dict = "lib.tables.dict",
  set = "lib.tables.set",
  functional = "lib.tables.functional",
  safe = "lib.tables.safe",

  -- UI
  hover_select = "lib.ui.hover_select",
  hl = "lib.ui.hl",

  -- AUTOCMD/KEYMAP
  autocmd = "lib.autocmd",
  map = "lib.map",
  usercmd = "lib.usercmd",

  -- NOTIFY
  notify = "lib.notify",
  resolve_log_level = "lib.notify.resolve_log_level",

  -- LAZY/MEMO (eager - used internally)
  lazy = "lib.lazy",
  memo = "lib.memo",

  -- TIME
  time_diff = "lib.time.diff",

  -- NORMALIZE
  normalize = "lib.normalize",

  -- TERMINAL
  terminal_escape = "lib.terminal",
  is_terminal_buf = "lib.terminal",
  delete_terminal_buf = "lib.terminal",

  -- HEX
  hex_to_string = "lib.strings.convert.hex_to_string",
}

-- Special handlers for modules with multiple exports
local SPECIAL_HANDLERS = {

  augroup_create_clear = { "lib.autocmd.augroup.create", key = "clear"},

  -- lib.nvim
  has_exec = { mod = "lib.nvim", key = "has_exec" },

  -- lib.cross.run exports multiple functions
  shell = { mod = "lib.cross.run", key = "shell" },
  run = { mod = "lib.cross.run", key = "run" },
  run_blocking = { mod = "lib.cross.run", key = "run_blocking" },

  -- functions
  noop = { mod = "lib.functions.meta", kex = "noop" },
  identity = { mod = "lib.functions.meta", kex = "identity" },
  always_true = { mod = "lib.functions.meta", kex = "always_true" },
  always_false = { mod = "lib.functions.meta", kex = "always_false" },
  const = { mod = "lib.functions.meta", kex = "const" },
  raise = { mod = "lib.functions.meta", kex = "raise" },

  -- lib.fs.path exports multiple functions
  joinpath = { mod = "lib.fs.path", key = "joinpath" },
  ensure_dir = { mod = "lib.fs.path", key = "ensure_dir" },

  -- lib.require exports multiple functions
  require_safe = { mod = "lib.require", key = "safe" },
  require_dir = { mod = "lib.require", key = "dir" },
  require_lazy = { mod = "lib.require", key = "lazy" },

  -- lib.terminal exports multiple functions
  terminal_escape = { mod = "lib.terminal", key = "escape" },
  is_terminal_buf = { mod = "lib.terminal", key = "is_terminal_buf" },
  delete_terminal_buf = { mod = "lib.terminal", key = "delete_terminal_buf" },

  -- lib.strings is special - we want to expose both the module and individual functions
  strings = { mod = "lib.strings", whole = true },
  trim = { mod = "lib.strings", key = "trim" },
  slugify = { mod = "lib.strings", key = "slugify" },
  kebab_case = { mod = "lib.strings", key = "kebab_case" },
  starts_with = { mod = "lib.strings", key = "starts_with" },
  ends_with = { mod = "lib.strings", key = "ends_with" },
  contains = { mod = "lib.strings", key = "contains" },
  split = { mod = "lib.strings", key = "split" },
  join = { mod = "lib.strings", key = "join" },
  replace_all = { mod = "lib.strings", key = "replace_all" },
  capitalize = { mod = "lib.strings", key = "capitalize" },
  uncapitalize = { mod = "lib.strings", key = "uncapitalize" },
  snake_case = { mod = "lib.strings", key = "snake_case" },
  camel_case = { mod = "lib.strings", key = "camel_case" },
  pad_start = { mod = "lib.strings", key = "pad_start" },
  pad_end = { mod = "lib.strings", key = "pad_end" },
  pad_center = { mod = "lib.strings", key = "pad_center" },
  indent = { mod = "lib.strings", key = "indent" },
  dedent = { mod = "lib.strings", key = "dedent" },
  is_empty_or_space = { mod = "lib.strings", key = "is_empty_or_space" },
  remove_prefix = { mod = "lib.strings", key = "remove_prefix" },
  uri_decode = { mod = "lib.strings", key = "uri_decode" },
  normalize_anchor = { mod = "lib.strings", key = "normalize_anchor" },
  has_scheme = { mod = "lib.strings", key = "has_scheme" },
  is_web_url = { mod = "lib.strings", key = "is_web_url" },
  url_under_cursor = { mod = "lib.strings", key = "url_under_cursor" },
  escape_lua_magic = { mod = "lib.strings", key = "escape_lua_magic" },
  find_plain = { mod = "lib.strings", key = "find_plain" },
  replace_plain = { mod = "lib.strings", key = "replace_plain" },
  surround = { mod = "lib.strings", key = "surround" },
  count_lines = { mod = "lib.strings", key = "count_lines" },

  -- json decode
  json_decode_to_string_array = { mod = "lib.json.decode.to_string_array", key = "json_decode" },
}

-- ============================================================================
-- Module Cache
-- ============================================================================

local loaded = {}

-- ============================================================================
-- Metatable-based Lazy Loading
-- ============================================================================

setmetatable(LIB, {
  __index = function(_, key)
    -- Check if already loaded
    if loaded[key] then
      return loaded[key]
    end

    -- Check special handlers first
    local handler = SPECIAL_HANDLERS[key]
    if handler then
      local mod = require(handler.mod)
      if handler.whole then
        loaded[key] = mod
        return mod
      elseif handler.key then
        local value = mod[handler.key]
        loaded[key] = value
        return value
      end
    end

    -- Check module map
    local mod_path = MODULE_MAP[key]
    if mod_path then
      local mod = require(mod_path)
      loaded[key] = mod
      return mod
    end

    -- Not found
    error(string.format("lib: unknown key '%s'", key))
  end,
})

---@type Lib
return LIB
