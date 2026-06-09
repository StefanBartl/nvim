---@module 'custom.dir_picker.core'
---@brief Core resolution and engine dispatch logic for dir_picker.

local notify  = require("lib.notify").create("[dir_picker.core]")
local cfg_mod = require("custom.dir_picker.config")

local M = {}

-- ---------------------------------------------------------------------------
-- Internal: path resolution
-- ---------------------------------------------------------------------------

--- Resolves a numeric depth to an absolute path by walking CWD upward.
---@param depth integer  Number of directory levels to ascend (0 = CWD).
---@return string        Normalized absolute path.
local function resolve_by_depth(depth)
  local cwd = vim.uv.cwd() or vim.fn.getcwd()
  if depth <= 0 then return vim.fs.normalize(cwd) end
  return vim.fs.normalize(cwd .. string.rep("/..", depth))
end

--- Resolves any accepted depth argument (integer, alias string) to an absolute path.
---@param arg DirPickerDepthArg|string|integer|nil
---@return string|nil
local function resolve_path_from_depth(arg)
  local cfg = cfg_mod.get()

  if arg == nil or arg == "" then
    return vim.fs.normalize(vim.uv.cwd() or vim.fn.getcwd())
  end

  local as_str  = tostring(arg):lower():match("^%s*(.-)%s*$")
  local resolver = cfg.depth_aliases[as_str]
  if resolver then
    local ok, result = pcall(resolver)
    if ok and type(result) == "string" then
      return vim.fs.normalize(result)
    end
    notify.error("Alias resolver for '" .. as_str .. "' failed.")
    return nil
  end

  local depth = tonumber(arg)
  if depth then
    if depth < 0 then
      notify.warn("Negative depth clamped to 0.")
      depth = 0
    end
    return resolve_by_depth(math.floor(depth))
  end

  notify.error("Unrecognised depth argument: '" .. tostring(arg) .. "'")
  return nil
end

--- Expands and normalizes an explicit path string.
--- Handles ~, environment variables, and both POSIX and Windows separators.
---@param raw string  Raw path string as given by the user.
---@return string|nil
local function resolve_explicit_path(raw)
  -- Expand leading ~ to the home directory
  local home = vim.uv.os_homedir() or vim.fn.expand("~")
  local expanded = raw:gsub("^~", home)
  -- Expand %ENVVAR% (Windows) and $ENVVAR (POSIX) style variables
  expanded = expanded:gsub("%%([^%%]+)%%", function(var)
    return os.getenv(var) or ("%" .. var .. "%")
  end)
  expanded = expanded:gsub("%$([%w_]+)", function(var)
    return os.getenv(var) or ("$" .. var)
  end)
  return vim.fs.normalize(expanded)
end

--- Parses a single raw argument string for a `path=<value>` prefix.
--- Returns the path value if found, nil otherwise.
---@param raw string|nil
---@return string|nil
local function extract_path_arg(raw)
  if type(raw) ~= "string" then return nil end
  -- Accept:  path=/foo/bar   path=c:\tools   path="c:\program files\x"
  local value = raw:match("^[Pp][Aa][Tt][Hh]=(.+)$")
  if not value then return nil end
  -- Strip optional surrounding quotes added by shells or the user
  value = value:match('^"(.*)"$') or value:match("^'(.*)'$") or value
  return value ~= "" and value or nil
end

-- ---------------------------------------------------------------------------
-- Internal: engine availability probing
-- ---------------------------------------------------------------------------

---@return boolean
local function has_telescope()
  return pcall(require, "telescope.builtin")
end

---@return boolean
local function has_fzf()
  return pcall(require, "fzf-lua")
end

--- Resolves the effective engine, honouring config and availability.
---@param requested string|nil
---@return DirPickerEngine|nil
local function resolve_engine(requested)
  local cfg  = cfg_mod.get()
  local want = requested and tostring(requested):lower() or cfg.default_engine
  if want == "fzf-lua" or want == "fzf_lua" then want = "fzf" end

  local probes = { telescope = has_telescope, fzf = has_fzf }

  for _, candidate in ipairs({ want, cfg.fallback_engine }) do
    local probe = probes[candidate]
    if probe and probe() then return candidate end
  end

  notify.error("No supported picker engine is available (tried: telescope, fzf).")
  return nil
end

-- ---------------------------------------------------------------------------
-- Internal: engine launchers
-- ---------------------------------------------------------------------------

---@param path string
local function launch_telescope(path)
  local _, builtin = pcall(require, "telescope.builtin")
  builtin.find_files({ cwd = path })
end

---@param path string
local function launch_fzf(path)
  local _, fzf = pcall(require, "fzf-lua")
  fzf.files({ cwd = path })
end

local launchers = {
  telescope = launch_telescope,
  fzf       = launch_fzf,
}

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Resolves the target directory and opens the configured picker.
---
--- Argument parsing priority:
---   1. If any element of `args` starts with `path=`, that explicit path is used.
---   2. Otherwise `depth_arg` is resolved (integer, alias, or nil → CWD).
---   3. `engine_arg` selects the picker; falls back to config + auto-detect.
---
---@param depth_arg  DirPickerDepthArg|string|integer|nil
---@param engine_arg DirPickerEngine|string|nil
---@param raw_args   string[]|nil  Full raw argument list (for path= scanning).
---@return nil
function M.pick(depth_arg, engine_arg, raw_args)
  -- Scan raw_args first so that `path=` can appear at any position
  local explicit_path = nil
  if type(raw_args) == "table" then
    for _, token in ipairs(raw_args) do
      explicit_path = extract_path_arg(token)
      if explicit_path then break end
    end
  end
  -- Also check depth_arg itself in case the caller passes path= directly
  if not explicit_path then
    explicit_path = extract_path_arg(tostring(depth_arg or ""))
  end

  local path
  if explicit_path then
    path = resolve_explicit_path(explicit_path)
    if not path then
      notify.error("Could not resolve explicit path: '" .. explicit_path .. "'")
      return
    end
  else
    path = resolve_path_from_depth(depth_arg)
    if not path then return end
  end

  if vim.fn.isdirectory(path) == 0 then
    notify.error("Path does not exist or is not a directory: " .. path)
    return
  end

  local engine = resolve_engine(engine_arg)
  if not engine then return end

  local launcher = launchers[engine]
  if not launcher then
    notify.error("Internal: no launcher for engine '" .. engine .. "'")
    return
  end

  launcher(path)
end

--- Returns all registered alias names, sorted, for use in completion.
---@return string[]
function M.alias_names()
  local names = {}
  local i = 0
  for k in pairs(cfg_mod.get().depth_aliases) do
    i = i + 1
    names[i] = k
  end
  table.sort(names)
  return names
end

return M
