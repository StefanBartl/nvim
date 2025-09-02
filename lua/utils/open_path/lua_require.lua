---@module 'utils.open_path.lua_require'
--- Resolve and open Lua modules referenced by require(...) or EmmyLua @module.
--- Works with Neovim's runtimepath (lua/**) and Lua's package.path.
--- Provides edit/split/vsplit/tab openers and a gf-like fallback.
---
--- Usage:
---   require('utils.open_path.lua_require').gf_lua_smart()    -- maps well to `gf`
---   require('utils.open_path.lua_require').open_in_vsplit()  -- vsplit
---   require('utils.open_path.lua_require').open_in_hsplit()  -- horizontal split
---   require('utils.open_path.lua_require').open_in_tab()     -- tab

---@class LuaRequire
local M = {}

-- ---------------------------------------------------------------------------
-- Small helpers (kept local to avoid external deps)
-- ---------------------------------------------------------------------------

---@alias _str string

--- Extract module name under cursor from require(...) or EmmyLua @module.
--- Supports: require "x.y", require('x.y'), require([[x.y]]), ---@module 'x.y'
---@return _str|nil
local function module_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local cur_col = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- search window around cursor
  local start_col = math.max(1, cur_col - 120)
  local end_col   = math.min(#line, cur_col + 120)
  local seg = line:sub(start_col, end_col)

  -- Use [=[ ... ]=] so that inner ']]' in patterns doesn't close the string.
  local PAT_REQUIRE_PARENS  = [=[require%s*%(%s*["']([%w%._%-/]+)["']%s*%)]=]
  local PAT_REQUIRE_BARE    = [=[require%s*["']([%w%._%-/]+)["']]=]
  local PAT_REQUIRE_LONGSTR = [=[require%s*%(%s*%[%[([%w%._%-/]+)%]%]%s*%)]=]
  local PAT_EMMY_MODULE     = [=[%-%-%-@module%s*["']([%w%._%-/]+)["']]=]

  -- 1) require("x.y") / require('x.y')
  local mod = seg:match(PAT_REQUIRE_PARENS)
  if not mod then
    -- 2) require "x.y"
    mod = seg:match(PAT_REQUIRE_BARE)
  end
  if not mod then
    -- 3) require([[x.y]])
    mod = seg:match(PAT_REQUIRE_LONGSTR)
  end
  if not mod then
    -- 4) ---@module 'x.y'
    mod = seg:match(PAT_EMMY_MODULE)
  end

  if not mod or mod == "" then
    return nil
  end
  return mod
end

--- Convert module 'a.b.c' to candidate runtime-relative paths.
---@param mod string
---@return string[] files, string[] inits
local function module_to_relpaths(mod)
  -- Tolerate '/' to support users typing 'a/b/c' as well as 'a.b.c'
  local dotted = mod:gsub("/", ".")
  local base = dotted:gsub("%.", "/") -- a.b.c -> a/b/c
  ---@type string[]
  local files = { ("lua/%s.lua"):format(base) }
  ---@type string[]
  local inits = { ("lua/%s/init.lua"):format(base) }
  return files, inits
end

--- Resolve a module to absolute filesystem paths.
--- Search order:
---   1) runtimepath hits via nvim_get_runtime_file('lua/x/y.lua')
---   2) runtimepath hits via nvim_get_runtime_file('lua/x/y/init.lua')
---   3) package.searchpath(mod, package.path) as a fallback
---@param mod string
---@return string[]  -- absolute paths, de-duplicated, best-first
local function resolve_module_paths(mod)
  local files, inits = module_to_relpaths(mod)
  local results ---@type string[]
  results = {}

  local function add(paths)
    for _, p in ipairs(paths or {}) do
      if p and p ~= "" then
        results[#results + 1] = p
      end
    end
  end

  -- runtimepath: direct file
  for _, rel in ipairs(files) do
    add(vim.api.nvim_get_runtime_file(rel, true))
  end
  -- runtimepath: init.lua
  for _, rel in ipairs(inits) do
    add(vim.api.nvim_get_runtime_file(rel, true))
  end

  -- package.path fallback (e.g., luarocks modules on plain Lua path)
  local ok, pkg = pcall(function()
    return package.searchpath(mod, package.path)
  end)
  if ok and pkg and pkg ~= "" then
    results[#results + 1] = pkg
  end

  -- De-duplicate while preserving order
  local seen = {} ---@type table<string, boolean>
  local dedup ---@type string[]
  dedup = {}
  for _, p in ipairs(results) do
    if not seen[p] then
      seen[p] = true
      dedup[#dedup + 1] = p
    end
  end

  -- Lightweight ranking: prefer near current buffer, else shorter path
  local bufdir = vim.fn.expand("%:p:h")
  table.sort(dedup, function(a, b)
    local aa = (bufdir ~= "" and a:find(bufdir, 1, true)) and 1 or 0
    local bb = (bufdir ~= "" and b:find(bufdir, 1, true)) and 1 or 0
    if aa ~= bb then return aa > bb end
    return #a < #b
  end)

  return dedup
end

--- Open helper using :edit/:split/:vsplit/:tabedit.
---@param cmd '"edit"'|'"split"'|'"vsplit"'|'"tabedit"'
---@param path string
local function open_with(cmd, path)
  vim.api.nvim_cmd({ cmd = cmd, args = { path } }, {})
end

--- Open the Lua module under cursor; return true if opened.
---@param how '"buffer"'|'"vsplit"'|'"hsplit"'|'"tab"'
---@return boolean
function M.open_under_cursor(how)
  local mod = module_under_cursor()
  if not mod then
    return false
  end
  local paths = resolve_module_paths(mod)
  local path = paths[1]
  if not path then
    return false
  end

  if how == "buffer" then
    open_with("edit", path)
  elseif how == "vsplit" then
    open_with("vsplit", path)
  elseif how == "hsplit" then
    open_with("split", path)
  else
    open_with("tabedit", path)
  end
  return true
end

--- gf-like smart opener for Lua: try module under cursor, else native gf.
---@return nil
function M.gf_lua_smart()
  if not M.open_under_cursor("buffer") then
    vim.cmd.normal({ args = { "gf" }, bang = true })
  end
end

--- Convenience wrappers
---@return boolean
function M.open_in_buffer()  return M.open_under_cursor("buffer") end
---@return boolean
function M.open_in_vsplit()  return M.open_under_cursor("vsplit") end
---@return boolean
function M.open_in_hsplit()  return M.open_under_cursor("hsplit") end
---@return boolean
function M.open_in_tab()     return M.open_under_cursor("tab")    end

return M
