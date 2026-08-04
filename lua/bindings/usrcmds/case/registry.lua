---@module 'bindings.usrcmds.case.registry'
--- Discovers existing cases on disk. Flat by design: a case is
--- `<cases_root>/<state>/<short>` for one of `config.states` — no company
--- nesting, no separate top-level Closed/ (see MIGRATION.md for the
--- one-time move off the old, uneven layout, handled by migrate.lua).
---
--- Cached per session (cases don't appear/disappear inside one editing
--- session often enough to justify rescanning on every :Case call);
--- M.invalidate() drops the cache after anything that creates/moves a case.

local config = require("bindings.usrcmds.case.config")

local M = {}

local uv = vim.uv or vim.loop

---@class Lib.Case.RegistryEntry
---@field short string
---@field dir string
---@field state string

---@type Lib.Case.RegistryEntry[]|nil
local cache = nil

---@param dir string
---@return string[] names
local function subdirs(dir)
  local names = {}
  local fd = uv.fs_scandir(dir)
  if not fd then
    return names
  end
  while true do
    local name, typ = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    if typ == "directory" then
      names[#names + 1] = name
    end
  end
  return names
end

---@param state string
---@return Lib.Case.RegistryEntry[]
local function scan_state(state)
  local dir = config.state_dir(state)
  local entries = {}
  for _, short in ipairs(subdirs(dir)) do
    if short:match("^%d+$") then
      entries[#entries + 1] = { short = short, dir = dir .. "/" .. short, state = state }
    end
  end
  return entries
end

--- Drop the cache — call after any create/move that changes what's on disk.
function M.invalidate()
  cache = nil
end

---@return Lib.Case.RegistryEntry[]
function M.list()
  if cache then
    return cache
  end
  local all = {}
  for _, state in ipairs(config.states) do
    vim.list_extend(all, scan_state(state))
  end
  cache = all
  return all
end

---@param short string
---@return Lib.Case.RegistryEntry|nil
function M.find(short)
  for _, e in ipairs(M.list()) do
    if e.short == short then
      return e
    end
  end
  return nil
end

---@param short string
---@return boolean
function M.exists(short)
  return M.find(short) ~= nil
end

--- `<Tab>` completion source for the CASE argument type.
---@param lead string
---@return string[]
function M.complete(lead)
  local out = {}
  for _, e in ipairs(M.list()) do
    if lead == "" or e.short:sub(1, #lead) == lead then
      out[#out + 1] = e.short
    end
  end
  table.sort(out)
  return out
end

--- Where a brand-new case's folder is created.
---@param short string
---@return string
function M.new_dir(short)
  return config.state_dir(config.default_state) .. "/" .. short
end

return M
