---@module 'config.harpoon'
--- Harpoon (v2/v1 robust): sanitize persisted list and auto-add target files with context.

---@class HarpoonCfg
local M = {}

---@diagnostic disable

-- Hard-require harpoon; abort gracefully if missing
local ok_hp, harpoon = pcall(require, "harpoon")
if not ok_hp then
  vim.notify("[harpoon] not installed", vim.log.levels.WARN)
  return M
end

local ok_path, Path = pcall(require, "plenary.path")
if not ok_path then
  vim.notify("[harpoon] plenary not installed", vim.log.levels.ERROR)
  return M
end

local uv = vim.uv or vim.loop

-- Resolve to a canonical absolute path (resolve symlinks when possible).
-- Falls back to Path:absolute() if realpath is not available or fails.
---@param p String
---@return String
local function canon(p)
  if uv and uv.fs_realpath then
    local rp = uv.fs_realpath(p)
    if type(rp) == "string" and rp ~= "" then return rp end
  end
  return Path:new(p):absolute()
end

-- Here you can preset files for harpoon ui
-- Build targets (make sure these exist)
local env     = require("system.env").get()
local root    = env.repo_base
local targets = {

  canon(vim.fs.joinpath(root, "Notes", "MyNotes", "CLI-Notes", "CLI-Tools.md")),
}

--------------------------------------------------------------------------------
-- Versions-agnostische Adapter
--------------------------------------------------------------------------------

--- Versions-agnostisch setup() ausführen (v2: method-style; manche Builds: function-style).
local function safe_setup()
  if type(harpoon.setup) ~= "function" then
    return
  end
  local okinfo, info = pcall(debug.getinfo, harpoon.setup, "u")
  if okinfo and info and info.nparams and info.nparams >= 2 then
    -- method-style: expects (self, opts?)
    pcall(function()
      harpoon:setup {}
    end)
  else
    -- function-style: expects (opts?)
    pcall(function()
      harpoon.setup {}
    end)
  end
end

--- Hole die "files"-Liste in möglichst vielen Varianten.
--- v2: harpoon:list()  oder harpoon.get("files")
--- v1-Fallback: baue eine pseudo-Liste aus harpoon.mark.get_marked_files()
---@return table|nil list
local function get_files_list()
  -- v2: bevorzugt :list()
  if type(harpoon.list) == "function" then
    local ok, list = pcall(function()
      return harpoon:list()
    end)
    if ok and type(list) == "table" then
      return list
    end
  end
  -- manche v2-Snapshots: get("files")
  if type(harpoon.get) == "function" then
    local ok, list = pcall(harpoon.get, harpoon, "files")
    if ok and type(list) == "table" then
      return list
    end
  end
  -- v1-Fallback: Mark/Ui API
  local ok_mark, mark = pcall(require, "harpoon.mark")
  if ok_mark and type(mark.get_marked_files) == "function" then
    local items = {}
    local ok_files, files = pcall(mark.get_marked_files)
    if ok_files and type(files) == "table" then
      for _, path in ipairs(files) do
        table.insert(items, { value = path, context = { row = 1, col = 0 } })
      end
    end
    -- pseudo-Liste mit minimalen Methoden, die wir brauchen
    return {
      items = items,
      append = function(self, item)
        if type(item) == "table" and type(item.value) == "string" then
          pcall(mark.add_file, item.value)
          table.insert(self.items, item)
        end
      end,
      save = function() end, -- v1 speichert implizit
    }
  end
  return nil
end

--------------------------------------------------------------------------------
-- Normalisierung & Utilities
--------------------------------------------------------------------------------

--- Stelle sicher, dass jedes Item { value=..., context={row,col} } hat.
---@return boolean changed
local function sanitize_default_list()
  local list = get_files_list()
  if not list then
    vim.notify("[harpoon] no list API available (version mismatch)", vim.log.levels.WARN)
    return false
  end

  local changed = false
  for i, it in ipairs(list.items or {}) do
    if type(it) == "string" then
      list.items[i] = { value = it, context = { row = 1, col = 0 } }
      changed = true
    elseif type(it) == "table" then
      if it.value == nil and it.path then
        it.value = it.path
        changed = true
      end
      if it.context == nil then
        it.context = { row = 1, col = 0 }
        changed = true
      end
    end
  end

  if changed then
    -- v2: harpoon.save(self?) oder list:save()
    if type(harpoon.save) == "function" then
      pcall(harpoon.save, harpoon)
    elseif type(list.save) == "function" then
      pcall(list.save, list)
    end
  end
  return changed
end

--- Append mit Kontext, API-agnostisch.
---@param list table
---@param path string
local function append_with_context(list, path)
  local item = { value = path, context = { row = 1, col = 0 } }
  if type(list.append) == "function" then
    pcall(function()
      list:append(item)
    end)
  elseif type(list.add) == "function" then
    pcall(function()
      list:add(item)
    end)
  else
    -- v1-Fallback (pseudo-Liste)
    table.insert(list.items, item)
  end
end

--------------------------------------------------------------------------------
-- Autocmd: On VimEnter
--------------------------------------------------------------------------------

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    safe_setup()

    -- 1) sanitize existing items (verhindert nil-context Fehler)
    sanitize_default_list()

    -- 2) auto-add missing targets
    local list = get_files_list()
    if not list then
      return
    end

    local have = {}
    for _, it in ipairs(list.items or {}) do
      local val = (type(it) == "table") and it.value or it
      if type(val) == "string" then
        have[val] = true
      end
    end
    for _, p in ipairs(targets) do
      if type(p) == "string" and p ~= "" and not have[p] then
        append_with_context(list, p)
      end
    end
  end,
})

-- Optional: Command zum manuellen Normalisieren
vim.api.nvim_create_user_command("HarpoonSanitize", function()
  local changed = sanitize_default_list()
  vim.notify(("[harpoon] sanitize: %s"):format(changed and "changed" or "no change"), vim.log.levels.INFO)
end, { desc = "Normalize Harpoon items (add context/convert strings)" })

return M
