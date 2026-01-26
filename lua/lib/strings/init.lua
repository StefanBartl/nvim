---@module 'lib.strings'

local M = {}

M.remove_prefix = require("lib.strings.remove_prefix")
-- core module
M.trim =require("lib.strings.core").trim
M.slugify = require("lib.strings.core").slugify
M.kebab_case = require("lib.strings.core").kebab_case
M.starts_with = require("lib.strings.core").starts_with
M.ends_with = require("lib.strings.core").ends_with
M.contains = require("lib.strings.core").contains
M.split = require("lib.strings.core").split
M.join = require("lib.strings.core").join
M.replace_all = require("lib.strings.core").replace_all
M.normalize_ws = require("lib.strings.core").normalize_ws
M.capitalize = require("lib.strings.core").capitalize
M.uncapitalize = require("lib.strings.core").uncapitalize
M.snake_case = require("lib.strings.core").snake_case
M.camel_case = require("lib.strings.core").camel_case
M.pad_start = require("lib.strings.core").pad_start
M.pad_end = require("lib.strings.core").pad_end
M.pad_center = require("lib.strings.core").pad_center
M.indent  = require("lib.strings.core").indent
M.dedent = require("lib.strings.core").dedent
M.is_empty_or_space = require("lib.strings.core").is_empty_or_space
M.count_lines = require("lib.strings.core").count_lines

-- patterns module
M.escape_lua_magic = require("lib.strings.patterns").escape_lua_magic
M.find_plain = require("lib.strings.patterns").find_plain
M.replace_plain = require("lib.strings.patterns").replace_plain
M.surround = require("lib.strings.patterns").surround

-- links module
M.uri_decode = require("lib.strings.links").uri_decode
M.normalize_ws = require("lib.strings.links").normalize_ws
M.has_scheme = require("lib.strings.links").has_scheme
M.is_web_url = require("lib.strings.links").is_web_url
M.url_under_cursor = require("lib.strings.links").url_under_cursor

return M

