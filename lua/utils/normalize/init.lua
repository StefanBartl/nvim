---@module 'utils.normalize'
--- A small, dependency-free normalization toolkit for plugin configs.
--- Focus:
---   * Strict typing at the boundary (apply_* never writes nil into typed fields).
---   * Common coercions (int/float/bool/enum/string/list/path/severity/loglevel).
---   * Utilities for schema-driven config merging.
--- Notes:
---   * All functions are side-effect free except apply_* helpers which mutate the provided table.
---   * Neovim APIs are used when available (vim.fs.normalize, vim.uv); fall back gracefully.

---@class Normalize
local M = {}

-- Locals ----------------------------------------------------------------------

local uv = vim and (vim.uv or vim.loop) or nil


-- Small helpers ---------------------------------------------------------------

--- Trim leading/trailing ASCII whitespace.
---@param s any
---@return string
local function trim(s)
  if type(s) ~= "string" then return "" end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Clamp number into [min,max] (inclusive); nil min/max are ignored.
---@param n number
---@param min number|nil
---@param max number|nil
---@return number
local function clamp(n, min, max)
  if min and n < min then n = min end
  if max and n > max then n = max end
  return n
end

--- Coalesce: return the first non-nil argument.
---@generic T
---@param ... T?
---@return T|nil
local function coalesce(...)
  local args = { ... }
  for i = 1, #args do
    if args[i] ~= nil then return args[i] end
  end
  return nil
end

--- Deduplicate a string list while preserving order.
---@param list StringList
---@return StringList
local function dedup_strings(list)
  local seen = {} ---@type table<string, boolean>
  local out = {}  ---@type StringList
  for i = 1, #list do
    local v = list[i]
    if type(v) == "string" then
      if not seen[v] then
        seen[v] = true
        out[#out + 1] = v
      end
    end
  end
  return out
end

--- Normalize a filesystem path using Neovim facilities if present.
---@param p any
---@return string
local function normalize_path(p)
  if type(p) ~= "string" or p == "" then return "" end
  if vim and vim.fs and vim.fs.normalize then
    return vim.fs.normalize(p)
  end
  -- Fallback: collapse consecutive slashes and strip trailing slash (except root)
  local s = p:gsub("[/\\]+", "/")
  if #s > 1 and s:sub(-1) == "/" then s = s:sub(1, -2) end
  return s
end

--- Return "file", "directory" or "" (does not exist) if libuv is available.
---@param p string
---@return string
local function path_kind(p)
  if not uv or p == "" then return "" end
  local st = uv.fs_stat(p)
  return (st and st.type) or ""
end

-- Public: direct value normalizers --------------------------------------------

--- Convert value into a boolean (loose parsing).
--- Accepts booleans; numbers 0/1; strings "true/false/yes/no/on/off/1/0" (case-insensitive).
---@param v any
---@return boolean|nil
function M.to_bool(v)
  local t = type(v)
  if t == "boolean" then return v end
  if t == "number" then
    if v == 0 then return false end
    if v == 1 then return true end
    return nil
  end
  if t == "string" then
    local s = v:lower()
    if s == "true" or s == "yes" or s == "on" or s == "1" then return true end
    if s == "false" or s == "no" or s == "off" or s == "0" then return false end
  end
  return nil
end

--- Convert value to integer; optionally clamp.
---@param v any
---@param min integer|nil
---@param max integer|nil
---@return integer|nil
function M.to_int(v, min, max)
  local n = tonumber(v)
  if not n then return nil end
  n = math.floor(n + 0) -- truncate toward zero
  ---@cast n integer
  if min or max then
    n = clamp(n, min, max)
  end
  return n
end

--- Convert value to float; optionally clamp and round to a given precision.
---@param v any
---@param min number|nil
---@param max number|nil
---@param precision integer|nil  -- number of fractional digits to keep (>=0)
---@return number|nil
function M.to_float(v, min, max, precision)
  local n = tonumber(v)
  if not n then return nil end
  if min or max then
    n = clamp(n, min, max)
  end
  if precision and precision >= 0 then
    local k = 10 ^ precision
    n = math.floor(n * k + 0.5) / k
  end
  return n
end

--- Return string if non-empty; optionally trim.
---@param v any
---@param allow_empty boolean|nil
---@param do_trim boolean|nil
---@return string|nil
function M.to_string(v, allow_empty, do_trim)
  if type(v) ~= "string" then return nil end
  local s = do_trim and trim(v) or v
  if not allow_empty and s == "" then return nil end
  return s
end

--- Map a value to an enum entry (case-insensitive by default).
---@param v any
---@param allowed StringList
---@param case_insensitive boolean|nil
---@return string|nil
function M.to_enum(v, allowed, case_insensitive)
  if type(v) ~= "string" then return nil end
  local s = v
  if case_insensitive ~= false then
    s = s:lower()
  end
  for i = 1, #allowed do
    local a = allowed[i]
    if case_insensitive ~= false then
      if type(a) == "string" and a:lower() == s then
        return a
      end
    else
      if a == s then
        return a
      end
    end
  end
  return nil
end

--- Convert value into a list of strings.
--- Accepts:
---   * string with separators (comma/space by default) → split
---   * list of strings → filtered to strings, option to dedup and trim
---@param v any
---@param opts {sep?:string, trim?:boolean, dedup?:boolean}|nil
---@return StringList|nil
function M.to_string_list(v, opts)
  opts = opts or {}
  local sep = opts.sep or "[%s,]+"
  local out = {} ---@type StringList
  if type(v) == "string" then
    for token in v:gmatch("[^" .. sep .. "]+") do
      local s = opts.trim and trim(token) or token
      if s ~= "" then out[#out + 1] = s end
    end
  elseif type(v) == "table" then
    for i = 1, #v do
      if type(v[i]) == "string" then
        local s = opts.trim and trim(v[i]) or v[i]
        if s ~= "" then out[#out + 1] = s end
      end
    end
  else
    return nil
  end
  if opts.dedup then
    out = dedup_strings(out)
  end
  return out
end

--- Convert a shell-like command (string or argv) into argv (best-effort).
--- Supports simple double-quoted segments; does not resolve escapes comprehensively.
---@param v any
---@return StringList|nil
function M.to_argv(v)
  if type(v) == "table" then
    local out = {} ---@type StringList
    for i = 1, #v do
      if type(v[i]) == "string" and v[i] ~= "" then
        out[#out + 1] = v[i]
      else
        return nil
      end
    end
    return #out > 0 and out or nil
  elseif type(v) == "string" then
    local s = trim(v)
    if s == "" then return nil end
    local out = {} ---@type StringList
    local i, len = 1, #s
    while i <= len do
      while i <= len and s:sub(i, i):match("%s") do i = i + 1 end
      if i > len then break end
      local ch = s:sub(i, i)
      if ch == '"' then
        local j = i + 1
        while j <= len and s:sub(j, j) ~= '"' do j = j + 1 end
        out[#out + 1] = s:sub(i + 1, j - 1)
        i = j + 1
      else
        local j = i
        while j <= len and not s:sub(j, j):match("%s") do j = j + 1 end
        out[#out + 1] = s:sub(i, j - 1)
        i = j
      end
    end
    return #out > 0 and out or nil
  end
  return nil
end

--- Map a user severity to vim.diagnostic.severity or nil.
--- Accepts "error|warn|warning|info|hint|all|''" and numeric pass-through.
---@param v any
---@return integer|nil
function M.to_diagnostic_severity(v)
  if type(v) == "number" then return v end
  if type(v) ~= "string" then return nil end
  local s = v:lower()
  if s == "" or s == "all" then return nil end
  if s == "error" or s == "err" then return vim.diagnostic.severity.ERROR end
  if s == "warn" or s == "warning" then return vim.diagnostic.severity.WARN end
  if s == "info" then return vim.diagnostic.severity.INFO end
  if s == "hint" then return vim.diagnostic.severity.HINT end
  return nil
end

--- Map a user level to vim.log.levels.* or nil.
--- Accepts "trace|debug|info|warn|error|off" and numeric pass-through.
---@param v any
---@return integer|nil
function M.to_log_level(v)
  if type(v) == "number" then return v end
  if type(v) ~= "string" then return nil end
  local s = v:lower()
  if s == "trace" then return vim.log.levels.TRACE end
  if s == "debug" then return vim.log.levels.DEBUG end
  if s == "info"  then return vim.log.levels.INFO  end
  if s == "warn"  then return vim.log.levels.WARN  end
  if s == "error" then return vim.log.levels.ERROR end
  if s == "off"   then return nil end
  return nil
end

--- Normalize a filesystem path and optionally ensure existence/type.
--- type_filter: "file"|"directory"|nil
---@param v any
---@param type_filter string|nil
---@param must_exist boolean|nil
---@return string|nil
function M.to_path(v, type_filter, must_exist)
  local s = M.to_string(v, false, true)
  if not s then return nil end
  s = normalize_path(s)
  if must_exist then
    local kind = path_kind(s)
    if kind == "" then return nil end
    if type_filter and kind ~= type_filter then return nil end
  end
  return s
end

-- Public: validators with (ok,val,err) ----------------------------------------

--- Validate that a value is an integer meeting a minimum bound, with optional nil allowance.
--- Contract:
---   * If v == nil and allow_nil == true  → ok=true, val=nil,  err=nil (caller can keep default)
---   * If v == nil and allow_nil == false → ok=false, val=nil,  err="<name> is required"
---   * If v is a number but not an integer (e.g. 1.5) → ok=false, err="<name> must be an integer"
---   * If v < min → ok=false, err="<name> must be ≥ <min>"
---   * Otherwise → ok=true, val=<integer>, err=nil
--- Rationale:
---   * This style produces a single, user-friendly error message without throwing.
---   * Returning the parsed integer (or nil) avoids re-parsing at call sites.
--- Example:
---   local ok, n, err = M.as_int("inner_pad", user.inner_pad, 0, false)
---   if not ok then return false, nil, err end
---@param name string            -- logical option name for readable error messages
---@param v any                  -- user-provided value to check
---@param min integer            -- inclusive minimum bound the integer must satisfy
---@param allow_nil boolean      -- whether nil is acceptable (useful for optional fields)
---@return boolean ok            -- true if valid or allowed-nil; false on validation failure
---@return integer|nil val       -- normalized integer (or nil if allowed-nil case)
---@return string|nil err        -- non-empty error message on failure; nil on success
function M.as_int(name, v, min, allow_nil)
  if v == nil then
    if allow_nil then return true, nil, nil end
    return false, nil, name .. " is required"
  end
  if type(v) ~= "number" or v ~= math.floor(v) then
    return false, nil, name .. " must be an integer"
  end
  if v < min then
    return false, nil, string.format("%s must be ≥ %d", name, min)
  end
  ---@cast v integer
  return true, v, nil
end

--- Validate that a value is strictly boolean (true/false).
--- Contract:
---   * Only Lua booleans are accepted. Strings like "true"/"false" are NOT coerced here.
---   * On success → ok=true, val=<boolean>, err=nil
---   * On failure → ok=false, val=nil, err="<name> must be a boolean"
--- Rationale:
---   * Use strict validation at config boundaries to avoid surprising coercions.
---   * For permissive conversion, prefer `to_bool()` + `apply_bool_loose()`.
--- Example:
---   local ok, b, err = M.as_bool("auto_width", user.auto_width)
---   if not ok then return false, nil, err end
---@param name string            -- logical option name for readable error messages
---@param v any                  -- user-provided value to check
---@return boolean ok            -- true if v is a boolean
---@return boolean|nil val       -- boolean value on success; nil on failure
---@return string|nil err        -- non-empty error message on failure; nil on success
function M.as_bool(name, v)
  if type(v) ~= "boolean" then
    return false, nil, name .. " must be a boolean"
  end
  return true, v, nil
end

-- Public: in-place appliers (write only when valid) ---------------------------

--- Apply an integer option if present; clamp to optional bounds.
--- Returns true if applied.
---@param tbl table
---@param key string
---@param val any
---@param min integer|nil
---@param max integer|nil
---@return boolean
function M.apply_int(tbl, key, val, min, max)
  local n = M.to_int(val, min, max)
  if n == nil then return false end
  ---@cast n integer
  tbl[key] = n
  return true
end

--- Apply a non-negative integer (>=0).
---@param tbl table
---@param key string
---@param val any
---@return boolean
function M.apply_nonneg_int(tbl, key, val)
  return M.apply_int(tbl, key, val, 0, nil)
end

--- Apply a strictly positive integer (>=1).
---@param tbl table
---@param key string
---@param val any
---@return boolean
function M.apply_pos_int(tbl, key, val)
  return M.apply_int(tbl, key, val, 1, nil)
end

--- Apply a float option if present; optional clamp and precision.
---@param tbl table
---@param key string
---@param val any
---@param min number|nil
---@param max number|nil
---@param precision integer|nil
---@return boolean
function M.apply_float(tbl, key, val, min, max, precision)
  local n = M.to_float(val, min, max, precision)
  if n == nil then return false end
  tbl[key] = n
  return true
end

--- Apply a boolean option; strict (accepts only true/false).
---@param tbl table
---@param key string
---@param val any
---@return boolean
function M.apply_bool(tbl, key, val)
  if type(val) == "boolean" then
    tbl[key] = val
    return true
  end
  return false
end

--- Apply a boolean option; loose parsing via to_bool().
---@param tbl table
---@param key string
---@param val any
---@return boolean
function M.apply_bool_loose(tbl, key, val)
  local b = M.to_bool(val)
  if b == nil then return false end
  tbl[key] = b
  return true
end

--- Apply string if non-empty; optionally trim.
---@param tbl table
---@param key string
---@param val any
---@param allow_empty boolean|nil
---@param do_trim boolean|nil
---@return boolean
function M.apply_string(tbl, key, val, allow_empty, do_trim)
  local s = M.to_string(val, allow_empty, do_trim)
  if not s then return false end
  tbl[key] = s
  return true
end

--- Apply enum value if allowed; optionally case-insensitive.
---@param tbl table
---@param key string
---@param val any
---@param allowed StringList
---@param case_insensitive boolean|nil
---@return boolean
function M.apply_enum(tbl, key, val, allowed, case_insensitive)
  local s = M.to_enum(val, allowed, case_insensitive)
  if not s then return false end
  tbl[key] = s
  return true
end

--- Apply a list of strings; supports splitting strings and filtering.
---@param tbl table
---@param key string
---@param val any
---@param opts {sep?:string, trim?:boolean, dedup?:boolean}|nil
---@return boolean
function M.apply_string_list(tbl, key, val, opts)
  local list = M.to_string_list(val, opts)
  if not list or #list == 0 then return false end
  tbl[key] = list
  return true
end

--- Apply argv (command) from string or list; best-effort quoted split.
---@param tbl table
---@param key string
---@param val any
---@return boolean
function M.apply_argv(tbl, key, val)
  local argv = M.to_argv(val)
  if not argv or #argv == 0 then return false end
  tbl[key] = argv
  return true
end

--- Apply path with optional existence/type checks.
---@param tbl table
---@param key string
---@param val any
---@param type_filter string|nil  -- "file"|"directory"|nil
---@param must_exist boolean|nil
---@return boolean
function M.apply_path(tbl, key, val, type_filter, must_exist)
  local p = M.to_path(val, type_filter, must_exist)
  if not p then return false end
  tbl[key] = p
  return true
end

--- Apply vim.diagnostic severity (numeric) or nil (for "all"/empty).
---@param tbl table
---@param key string
---@param val any
---@return boolean
function M.apply_diagnostic_severity(tbl, key, val)
  local s = M.to_diagnostic_severity(val)
  if s == nil then
    -- Do not write nil into typed numeric fields; caller should handle optionality.
    return false
  end
  tbl[key] = s
  return true
end

--- Apply vim.log level (numeric) or skip on "off"/invalid.
---@param tbl table
---@param key string
---@param val any
---@return boolean
function M.apply_log_level(tbl, key, val)
  local lvl = M.to_log_level(val)
  if lvl == nil then return false end
  tbl[key] = lvl
  return true
end

--- Apply function if type matches; optionally validate arity on debug builds.
---@param tbl table
---@param key string
---@param val any
---@param min_arity integer|nil
---@param max_arity integer|nil
---@return boolean
function M.apply_fun(tbl, key, val, min_arity, max_arity)
  if type(val) ~= "function" then return false end
  -- Lua does not expose arity reliably; keep placeholders for future checks.
  tbl[key] = val
  return true
end

-- Schema-driven merge ---------------------------------------------------------

---@class NormalizerField
---@field apply FnApplier        -- applier(state, key, value) -> boolean
---@field default any            -- default value written if nothing applied (copied)
---@field required boolean|nil   -- if true and value missing, default must cover it; otherwise caller validates

---@class NormalizerSchema
---@field [string] NormalizerField

--- Merge opts into state per schema. Writes defaults first, then applies values.
--- Unknown keys are ignored. Returns state.
---@param state table
---@param opts table|nil
---@param schema NormalizerSchema
---@return table
function M.apply_schema(state, opts, schema)
  -- defaults
  for k, field in pairs(schema) do
    -- Deepcopy simple tables to avoid aliasing
    local dv = field.default
    if type(dv) == "table" then
      state[k] = vim.deepcopy(dv)
    else
      state[k] = dv
    end
  end
  -- user values
  if type(opts) == "table" then
    for k, field in pairs(schema) do
      if opts[k] ~= nil then
        local ok = field.apply(state, k, opts[k])
        if not ok then
          -- keep default; do not write nil into typed fields
        end
      end
    end
  end
  return state
end

-- Expose utilities ------------------------------------------------------------

M.trim = trim
M.clamp = clamp
M.coalesce = coalesce
M.normalize_path = normalize_path
M.path_kind = path_kind
M.dedup_strings = dedup_strings

return M
