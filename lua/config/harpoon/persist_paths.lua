---@module 'config.harpoon.persist_paths'
--- Inject a curated set of absolute file paths into Harpoon on startup.
--- Paths are added if they exist and are not present already.
--- Items remain removable from the UI; they will be re-added on the next start.
---
--- Depends on:
---   - utils.harpoon_sanitize (sanitize + dedup, no full replace)
---   - plenary (only for robust absolute path fallback)
---   - harpoon v2 API (prefers :list():add(); falls back gracefully)

local notify = require("lib.nvim.notify").create("[config.harpoon.persist_paths]")
local usercmd = require("lib.nvim.usercmd")

local M = {}

local normkey = require("lib.nvim.fs.normkey")
local uv = vim.uv or vim.loop
local ok_path, Path = pcall(require, "plenary.path")
local sani = require("config.harpoon.utils.sanitize")
local Autocmd = require("lib.nvim.autocmd")

--------------------------------------------------------------------------------
-- Path normalization
--------------------------------------------------------------------------------

---Return a canonical absolute path (resolve symlinks if possible).
---@param p string
---@return string
local function canon(p)
  if type(p) ~= "string" or p == "" then
    return ""
  end
  if uv and uv.fs_realpath then
    local rp = uv.fs_realpath(p)
    if type(rp) == "string" and rp ~= "" then
      return rp
    end
  end
  if ok_path then
    return Path:new(p):absolute()
  end
  -- Fallback: normalize relative → absolute-ish
  return vim.fs.normalize(p)
end

---Check if path is an existing regular file.
---@param p string
---@return boolean
local function is_file(p)
  local st = uv and uv.fs_stat and uv.fs_stat(p) or nil
  return (st and st.type == "file") and true or false
end

--------------------------------------------------------------------------------
-- Target spec → absolute paths
--------------------------------------------------------------------------------

---@type string[][]
M.target_specs = {}

---@param sym string
---@return string
local function expand_var(sym)
  if sym == "$REPOS_DIR" then
    return vim.env.REPOS_DIR or ""
  elseif sym == "$HOME" then
    return (uv.os_homedir and uv.os_homedir()) or vim.fn.expand("~")
  elseif sym == "$NVIM_HOME" then
    return vim.fn.stdpath("config")
  end
  return sym
end

---@param segs string[]
---@return string
local function join_spec(segs)
  local parts = {} ---@type string[]
  -- Pre-allocate to avoid reallocations for known length
  parts[#parts + 1] = expand_var(segs[1] or "")
  for i = 2, #segs do
    parts[#parts + 1] = segs[i]
  end
  ---@diagnostic disable-next-line: deprecated
  local unpack = table.unpack or unpack
  return vim.fs.joinpath(unpack(parts))
end

---@return string[]
local function resolve_targets()
  local n = #M.target_specs
  local out = { [n] = "" }
  for i = 1, n do
    out[i] = canon(join_spec(M.target_specs[i]))
  end
  return out
end

--------------------------------------------------------------------------------
-- Injection
--------------------------------------------------------------------------------

---Add an item to the harpoon list using v2 API when available.
---@param list table
---@param path string
local function add_with_context(list, path)
  local item = { value = canon(path), context = { row = 1, col = 0 } }
  if type(list.add) == "function" then
    pcall(function()
      list:add(item)
    end)
  elseif type(list.append) == "function" then
    pcall(function()
      list:append(item)
    end)
  else
    -- Last resort (pure table)
    list.items = list.items or {}
    table.insert(list.items, item)
  end
end

---Perform the actual injection
---@return boolean changed
function M.inject_now()
  local ok_hp, harpoon = pcall(require, "harpoon")
  if not ok_hp then
    return false
  end

  local list = harpoon:list()
  if type(list) ~= "table" then
    return false
  end
  ---@cast list Cfg.Harpoon.List

  -- Ensure list shape and remove legacy duplicates
  sani.sanitize_items_in_place(list)

  local have = {} ---@type table<string, boolean>
  if type(list.items) == "table" then
    for i = 1, #list.items do
      local it = list.items[i]
      local v = (type(it) == "table") and it.value or it
      if type(v) == "string" then
        have[normkey(v)] = true
      end
    end
  end

  local targets = resolve_targets()
  local added = false
  for i = 1, #targets do
    local p = targets[i]
    if p ~= "" and is_file(p) then
      local k = normkey(p, { realpath = true })
      if not have[k] then
        add_with_context(list, p)
        have[k] = true
        added = true
      end
    end
  end

  -- Final dedup in case of races or overlaps
  local removed = (sani.dedup_in_place_safe(list) or 0) > 0

  if added or removed then
    if type(harpoon.save) == "function" then
      pcall(harpoon.save, harpoon)
    elseif type(list.save) == "function" then
      pcall(list.save, list)
    end
  end

  return added or removed
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

---@param opts Cfg.Harpoon.PersistPathsOpts|nil
---@return nil
function M.setup(opts)
  opts = opts or {}
  if opts.target_specs and type(opts.target_specs) == "table" then
    M.target_specs = opts.target_specs
  end

  local grp = Autocmd.group("HarpoonPersistPaths", true)
  Autocmd.create("VimEnter", function()
    vim.schedule(function()
      M.inject_now()
    end)
  end, {
    group = grp,
  })

  usercmd.create("HarpoonPersistPathsReload", function()
    local changed = M.inject_now()
    notify.info(string.format("[harpoon] persistpaths: %s", changed and "changed" or "no change"))
  end, { desc = "Re-inject persistent Harpoon paths" })
end

return M
