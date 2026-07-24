---@module 'wkdoptions.hl_config.breadcrumbs.ctx.utils.text_utils'
---@brief Text manipulation utilities using lib.strings
---
--- All string operations are delegated to lib.strings for consistency
--- Pattern extraction is memoized per (text, lang) pair

local lazy = require("lib.lua.lazy")
local memo = lazy.require("lib.lua.memo")
local trim = lazy.require("lib.lua.strings.core").trim
local split = lazy.require("lib.lua.strings.core").split

local M = {}

-----------------------------------------------------------
-- Deduplication
-----------------------------------------------------------

--- Remove consecutive duplicate segments
--- Uses lib.table.array if available, fallback to manual
---@nodiscard
---@param parts string[]
---@return string[]
function M.dedupe_consecutive(parts)
  if type(parts) ~= "table" or #parts == 0 then
    return {}
  end

  -- Try lib.table.array first
  local ok, array_utils = pcall(require, "lib.lua.tables.array")
  if ok and type(array_utils.dedup_consecutive) == "function" then
    return array_utils.dedup_consecutive(parts)
  end

  -- Fallback: manual dedup
  local result = {}
  local last = nil

  for i = 1, #parts do
    local current = parts[i]
    if current ~= "" and current ~= last then
      result[#result + 1] = current
      last = current
    end
  end

  return result
end

-----------------------------------------------------------
-- Pattern Extraction (Memoized)
-----------------------------------------------------------

--- Extract identifier from text based on language (memoized)
--- Returns the most relevant identifier or nil
---@nodiscard
M.extract_identifier = memo.fn(function(text, lang)
  if type(text) ~= "string" or text == "" then
    return nil
  end

  text = trim(text)
  lang = lang or "generic"

  -- Language-specific patterns (priority order)
  local patterns = {
    lua = {
      -- M.function, obj:method
      "([%w_]+)[%.:]([%w_]+)%()",
      -- function name()
      "function%s+([%w_%.]+)%s*%(",
      -- M.key =, ["key"] =
      "([%w_]+)%s*=",
      -- Plain identifier
      "^([%w_]+)$",
    },
    javascript = {
      -- class.method(), obj.prop
      "([%w_$]+)%.([%w_$]+)",
      -- function name()
      "function%s+([%w_$]+)%s*%(",
      -- const name =
      "const%s+([%w_$]+)%s*=",
      -- Plain identifier
      "^([%w_$]+)$",
    },
    python = {
      -- obj.method, Class.attr
      "([%w_]+)%.([%w_]+)",
      -- def name()
      "def%s+([%w_]+)%s*%(",
      -- class Name
      "class%s+([%w_]+)",
      -- Plain identifier
      "^([%w_]+)$",
    },
    go = {
      -- func (r Type) Method()
      "func%s+%([^%)]*%*?([%w_]+)%)%s*([%w_]+)%s*%(",
      -- func Name()
      "func%s+([%w_]+)%s*%(",
      -- Plain identifier
      "^([%w_]+)$",
    },
  }

  local lang_patterns = patterns[lang] or patterns.lua

  -- Try each pattern in order
  for _, pattern in ipairs(lang_patterns) do
    local matches = { text:match(pattern) }
    if #matches > 0 then
      -- Return last capture (most specific)
      local result = matches[#matches]
      if result and #result > 0 then
        return result
      end
    end
  end

  return nil
end, { weak = "kv", size = 128 })

-----------------------------------------------------------
-- Path Manipulation
-----------------------------------------------------------

--- Split dotted path into segments
--- "a.b.c" → {"a", "b", "c"}
---@nodiscard
---@param path string
---@return string[]
function M.split_dotted(path)
  if type(path) ~= "string" or path == "" then
    return {}
  end

  return split(path, ".")
end

--- Join segments with separator
---@nodiscard
---@param parts string[]
---@param sep string
---@return string
function M.join_parts(parts, sep)
  if type(parts) ~= "table" or #parts == 0 then
    return ""
  end

  sep = sep or "."
  return table.concat(parts, sep)
end

-----------------------------------------------------------
-- Pattern Escaping
-----------------------------------------------------------

--- Escape string for use in Lua pattern
--- Delegates to lib.strings if available
---@nodiscard
---@param s string
---@return string
function M.escape_pattern(s)
  if type(s) ~= "string" then
    return ""
  end

  -- Try lib.strings.pattern.escape first
  local ok, pattern_utils = pcall(require, "lib.lua.strings.patterns")
  if ok and type(pattern_utils.escape) == "function" then
    return pattern_utils.escape(s)
  end

  -- Fallback: vim.pesc
  return vim.pesc(s)
end

-----------------------------------------------------------
-- Cleanup Helpers
-----------------------------------------------------------

--- Remove quotes from string
---@nodiscard
---@param s string
---@return string
function M.unquote(s)
  if type(s) ~= "string" or s == "" then
    return ""
  end

  -- Remove surrounding quotes (single or double)
  -- gsub returns (result, count), wir brauchen nur result
  local result = s:gsub('^["\']', ""):gsub('["\']$', "")
  return result
end

--- Extract key from Lua field syntax
--- "key = value" → "key"
--- '["key"] = value' → "key"
---@nodiscard
M.extract_lua_field_key = memo.fn(function(text)
  if type(text) ~= "string" or text == "" then
    return nil
  end

  text = trim(text)

  -- Plain identifier: key =
  local plain = text:match("^([%w_]+)%s*=")
  if plain then
    return plain
  end

  -- Quoted key: ["key"] =
  local quoted = text:match("^%[(['\"])(.-)%1%]%s*=")
  if quoted then
    return quoted
  end

  return nil
end, { weak = "kv", size = 64 })

--- Extract key from JS/TS object literal
--- "key: value" → "key"
--- "'key': value" → "key"
---@nodiscard
M.extract_js_object_key = memo.fn(function(text)
  if type(text) ~= "string" or text == "" then
    return nil
  end

  text = trim(text)

  -- Plain identifier: key:
  local plain = text:match("^([%w_$]+)%s*:")
  if plain then
    return plain
  end

  -- Quoted key: "key": or 'key':
  local quoted = text:match("^['\"]([^'\"]+)['\"]%s*:")
  if quoted then
    return quoted
  end

  return nil
end, { weak = "kv", size = 64 })

-----------------------------------------------------------
-- Container Path Building
-----------------------------------------------------------

--- Build container path from segments
--- Removes last segment (current field) if specified
---@nodiscard
---@param segments string[]
---@param drop_last boolean
---@param join_char string
---@return string|nil
function M.build_container(segments, drop_last, join_char)
  if type(segments) ~= "table" or #segments == 0 then
    return nil
  end

  join_char = join_char or "."

  local parts = {}
  local limit = drop_last and (#segments - 1) or #segments

  for i = 1, limit do
    if segments[i] and segments[i] ~= "" then
      parts[#parts + 1] = segments[i]
    end
  end

  return #parts > 0 and table.concat(parts, join_char) or nil
end

return M
