---@module 'config.harpoon'
--- Harpoon bootstrap with robust path normalization & deduplication.
--- This version prefers the Harpoon v2 API (list:add), falls back to append for older builds,
--- and provides a v1-compatible pseudo list. It prevents duplicate inserts across sessions.

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
local IS_WIN = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

--------------------------------------------------------------------------------
-- Path helpers
--------------------------------------------------------------------------------

---Return a canonical absolute path (resolve symlinks when possible).
---@param p string
---@return string
local function canon(p)
  if uv and uv.fs_realpath then
    local rp = uv.fs_realpath(p)
    if type(rp) == "string" and rp ~= "" then
      return rp
    end
  end
  return Path:new(p):absolute()
end

---Normalize a path to a stable comparison key across OS/filesystems.
---@param p string
---@return string
local function normkey(p)
  local abs = canon(p)
  if IS_WIN then
    abs = abs:gsub("/", "\\"):lower() -- case-insensitive FS, unify "\"
  else
    abs = abs:gsub("\\", "/")         -- cosmetic unification on Unix
  end
  return abs
end

---Check if path is an existing regular file.
---@param p string
---@return boolean
local function is_file(p)
  local st = uv and uv.fs_stat and uv.fs_stat(p) or nil
  return (st and st.type == "file") and true or false
end

--------------------------------------------------------------------------------
-- Harpoon accessors (v2 preferred, v1 fallback)
--------------------------------------------------------------------------------

---Setup harpoon (support method- and function-style signatures).
local function safe_setup()
  if type(harpoon.setup) ~= "function" then
    return
  end
  local okinfo, info = pcall(debug.getinfo, harpoon.setup, "u")
  if okinfo and info and info.nparams and info.nparams >= 2 then
    pcall(function() harpoon:setup({}) end)
  else
    pcall(function() harpoon.setup({}) end)
  end
end

---Obtain the default files list with broad compatibility.
---@return table|nil
local function get_files_list()
  -- v2 preferred: list()
  if type(harpoon.list) == "function" then
    local ok, list = pcall(function() return harpoon:list() end)
    if ok and type(list) == "table" then
      return list
    end
  end
  -- some v2 snapshots: get("files")
  if type(harpoon.get) == "function" then
    local ok, list = pcall(harpoon.get, harpoon, "files")
    if ok and type(list) == "table" then
      return list
    end
  end
  -- v1 fallback: synthesize a list via harpoon.mark
  local ok_mark, mark = pcall(require, "harpoon.mark")
  if ok_mark and type(mark.get_marked_files) == "function" then
    local items = {} ---@type { value: string, context: {row: integer, col: integer} }[]
    local ok_files, files = pcall(mark.get_marked_files)
    if ok_files and type(files) == "table" then
      for _, path in ipairs(files) do
        items[#items + 1] = { value = path, context = { row = 1, col = 0 } }
      end
    end
    -- Provide v2-like methods: prefer :add; keep :append as a thin wrapper (no deprecation).
    return {
      items = items,
      ---@param self table
      ---@param item { value: string, context: {row: integer, col: integer} }
      add = function(self, item)
        if type(item) == "table" and type(item.value) == "string" then
          pcall(mark.add_file, item.value)
          table.insert(self.items, item)
        end
      end,
      ---@param self table
      ---@param item table
      append = function(self, item) self:add(item) end,
      save = function() end, -- v1 persists implicitly
    }
  end
  return nil
end

---Persist list changes where possible.
---@param list table
local function save_list(list)
  if type(harpoon.save) == "function" then
    pcall(harpoon.save, harpoon)
  elseif type(list.save) == "function" then
    pcall(list.save, list)
  end
end

--------------------------------------------------------------------------------
-- Sanitize & dedup
--------------------------------------------------------------------------------

---Ensure each item is a normalized table and value is canonical absolute.
---@param list table
---@return boolean changed
local function sanitize_in_place(list)
  local changed = false
  for i, it in ipairs(list.items or {}) do
    if type(it) == "string" then
      list.items[i] = { value = canon(it), context = { row = 1, col = 0 } }
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
      if type(it.value) == "string" then
        local c = canon(it.value)
        if c ~= it.value then
          it.value = c
          changed = true
        end
      end
    end
  end
  return changed
end

---Remove duplicates based on normalized keys (keep first occurrence).
---@param list table
---@return boolean changed
local function dedup_in_place(list)
  local seen = {}
  local new_items = {}
  local changed = false

  for _, it in ipairs(list.items or {}) do
    local v = (type(it) == "table") and it.value or it
    if type(v) == "string" then
      local key = normkey(v)
      if not seen[key] then
        seen[key] = true
        if type(it) == "table" then
          new_items[#new_items + 1] = it
        else
          new_items[#new_items + 1] = { value = canon(v), context = { row = 1, col = 0 } }
          changed = true
        end
      else
        changed = true
      end
    end
  end

  if changed then
    list.items = new_items
  end
  return changed
end

---Add one path with context, preferring v2's :add to avoid deprecation.
---@param list table
---@param path string
local function add_with_context(list, path)
  local item = { value = canon(path), context = { row = 1, col = 0 } }
  if type(list.add) == "function" then
    -- v2 (preferred)
    pcall(function() list:add(item) end)
  elseif type(list.append) == "function" then
    -- older builds: still available; no deprecation in our pseudo v1 adapter
    pcall(function() list:append(item) end)
  else
    -- last resort (pure table)
    table.insert(list.items, item)
  end
end

--------------------------------------------------------------------------------
-- Targets
--------------------------------------------------------------------------------

---@type string[][]
local target_specs = {
  { "Notes", "MyNotes", "Notes.md" },
  { "Notes", "Neovim", "Neovim.md" },
  { "Notes", "MyNotes", "Wezterm.md" },
}

---Resolve target specs to absolute canonical paths using REPOS_DIR.
---@return string[]
local function resolve_targets()
  local root = vim.env.REPOS_DIR
  if type(root) ~= "string" or root == "" then
    vim.notify("[harpoon] REPOS_DIR not set; skip auto targets", vim.log.levels.WARN)
    return {}
  end
  ---@type string[]
  local out = {}
  for i = 1, #target_specs do
    local spec = target_specs[i]
    out[#out + 1] = canon(vim.fs.joinpath(root, unpack(spec)))
  end

  out[#out + 1] = canon(vim.fs.joinpath(vim.fn.stdpath('config'), "lua", "mynotes/", "spickzettel.md"))
	return out
end

--------------------------------------------------------------------------------
-- Autocmd (guarded in augroup)
--------------------------------------------------------------------------------

local aug = vim.api.nvim_create_augroup("HarpoonBootstrap", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = aug,
  callback = function()
    safe_setup()

    local list = get_files_list()
    if not list then
      vim.notify("[harpoon] no list API available (version mismatch)", vim.log.levels.WARN)
      return
    end

    local c1 = sanitize_in_place(list)
    local c2 = dedup_in_place(list)

    local have = {}
    for _, it in ipairs(list.items or {}) do
      local v = (type(it) == "table") and it.value or it
      if type(v) == "string" then
        have[normkey(v)] = true
      end
    end

    local targets = resolve_targets()
    local added = false
    for i = 1, #targets do
      local p = targets[i]
      local k = normkey(p)
      if not have[k] and is_file(p) then
        add_with_context(list, p) -- uses :add when available
        have[k] = true
        added = true
      end
    end

    if c1 or c2 or added then
      save_list(list)
    end
  end,
})

vim.api.nvim_create_user_command("HarpoonSanitize", function()
  local list = get_files_list()
  if not list then
    vim.notify("[harpoon] no list API available", vim.log.levels.WARN)
    return
  end
  local c1 = sanitize_in_place(list)
  local c2 = dedup_in_place(list)
  if c1 or c2 then
    save_list(list)
  end
  vim.notify(("[harpoon] sanitize: %s"):format((c1 or c2) and "changed" or "no change"), vim.log.levels.INFO)
end, { desc = "Normalize + deduplicate Harpoon items" })

return M
