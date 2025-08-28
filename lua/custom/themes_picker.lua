---@module 'themes.picker'
--- FzfLua-based unified theme picker for Base46 and regular colorschemes.
--- Features:
---   • Aggregates Base46 themes from both `lua/base46/themes/*.lua` and `lua/themes/base46/*.lua`
---   • Aggregates all discoverable Vim/Neovim colorschemes via `getcompletion("", "color")`
---   • Live preview while navigating items; revert on close if not confirmed
---   • Persist selected theme to a JSON file and provide a startup loader
---   • Optional: disable Base46 when applying a regular colorscheme (to avoid highlight overrides)
---
--- Public API:
---   require('themes.picker').setup({ ... })        -- optional
---   require('themes.picker').pick()                -- open the FzfLua picker
---   require('themes.picker').apply_persisted()     -- apply persisted selection on startup
---   require('themes.picker').apply(kind, name)     -- programmatic apply ("base46"|"colorscheme", name)
---
--- Requirements:
---   • fzf-lua (runtime plugin)
---   • Base46 only if you intend to use "base46" kind
---
--- Notes:
---   • This module does not modify fzf-lua sources; it only uses the public API.
---   • Persistence is stored in stdpath("state")/theme_picker/selection.json.

local M = {}

---@type ThemePickerConfig
local DEFAULTS = {
  persist_dir = nil,  -- computed in setup()
  disable_base46_when_colorscheme = true,
  preview_window = "nohidden:right:0",
  height = 0.55,
  width = 0.32,
  prompt = "Themes❯ ",
}

---@return string dir
local function persist_dir()
  local cfg = M._cfg or DEFAULTS
  if cfg.persist_dir and cfg.persist_dir ~= "" then
    return cfg.persist_dir
  end
  -- Use stdpath("state") to avoid polluting the config/data dirs.
  local d = vim.fn.stdpath("state") .. "/theme_picker"
  return d
end

---@return string path
local function persist_file()
  return persist_dir() .. "/selection.json"
end

---@param dir string
local function ensure_dir(dir)
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end


---@return PersistedSelection|nil sel
local function read_persisted()
  local p = persist_file()
  if vim.fn.filereadable(p) == 0 then
    return nil
  end
  local ok, decoded = pcall(function()
    local content = table.concat(vim.fn.readfile(p), "\n")
    return vim.json.decode(content)
  end)
  if not ok or type(decoded) ~= "table" then
    return nil
  end
  if decoded.kind ~= "base46" and decoded.kind ~= "colorscheme" then
    return nil
  end
  if type(decoded.name) ~= "string" or decoded.name == "" then
    return nil
  end
  return decoded ---@as PersistedSelection
end

---@param kind ThemeKind
---@param name string
local function write_persisted(kind, name)
  ensure_dir(persist_dir())
  local payload = vim.json.encode({ kind = kind, name = name })
  vim.fn.writefile({ payload }, persist_file())
end

-- ---------- Base46 utilities ----------

---@return string|nil current
local function current_base46_theme()
  return vim.g.base46_theme or vim.g.nvchad_theme
end

---@param theme string
---@return boolean ok
local function apply_base46_theme(theme)
  -- Set compatibility globals expected by various NvChad/Base46 versions.
  vim.g.base46_theme = theme
  vim.g.nvchad_theme = theme

  -- Try known entry points, fall back gracefully.
  local ok, base46 = pcall(require, "base46")
  if ok then
    if type(base46.load_all) == "function" then
      base46.load_all()
    elseif type(base46.load_theme) == "function" then
      base46.load_theme(theme)
    elseif type(base46.setup) == "function" then
      base46.setup()
    end
  end

  -- Improve plugin heuristics that read `g.colors_name`.
  vim.g.colors_name = "base46-" .. theme
  vim.cmd("redraw!")
  return true
end

-- ---------- Colorscheme utilities ----------

---@return string|nil current
local function current_colorscheme()
  local n = vim.g.colors_name
  if type(n) == "string" and n ~= "" then
    return n
  end
  return nil
end

---@param name string
---@return boolean ok
local function apply_colorscheme(name)
  -- Optionally neutralize Base46 when switching to a regular :colorscheme.
  if M._cfg.disable_base46_when_colorscheme then
    vim.g.base46_theme = nil
    vim.g.nvchad_theme = nil
  end
  local ok = pcall(vim.cmd.colorscheme, name)
  if ok then
    vim.cmd("redraw!")
  else
    vim.notify("Failed to apply colorscheme: " .. name, vim.log.levels.WARN)
  end
  return ok
end

-- ---------- Discovery ----------

---@return string[] names
local function list_base46_themes()
  ---@type string[]
  local names = {}
  local seen = {}

  -- 1) Standard Base46 location(s)
  for _, f in ipairs(vim.api.nvim_get_runtime_file("lua/base46/themes/*.lua", true)) do
    local n = f:match("themes/(.+)%.lua$")
    if n and not seen[n] then
      seen[n] = true
      table.insert(names, n)
    end
  end

  -- 2) User-curated folder (this repo): lua/themes/base46/*.lua
  for _, f in ipairs(vim.api.nvim_get_runtime_file("lua/themes/base46/*.lua", true)) do
    local n = f:match("themes/base46/(.+)%.lua$")
    if n and not seen[n] then
      seen[n] = true
      table.insert(names, n)
    end
  end

  table.sort(names)
  return names
end

---@return string[] names
local function list_colorscheme_names()
  -- Use the canonical completion to include everything on the runtimepath,
  -- including unloaded Lazy.nvim plugins that fzf-lua surfaces as well.
  local got = vim.fn.getcompletion("", "color") ---@type string[]
  table.sort(got)
  return got
end

-- ---------- Application and persistence facade ----------

---@alias ThemeKind "base46"|"colorscheme"

---@class PersistedSelection
---@field kind ThemeKind
---@field name string

---Apply a theme and optionally persist the selection.
---This function routes to either `apply_base46_theme` or `apply_colorscheme`.
---It ensures correct control flow and handles persistence safely.
---@param kind ThemeKind           -- which theme family to apply
---@param name string              -- theme identifier (Base46 theme name or :colorscheme name)
---@param persist boolean|nil      -- if true, write persisted selection; defaults to false
---@return boolean ok              -- true when applying the theme succeeded
---@nodiscard
function M.apply(kind, name, persist)
  -- Normalize and guard inputs
  ---@cast kind ThemeKind
  if kind ~= "base46" and kind ~= "colorscheme" then
    vim.notify("Unknown theme kind: " .. tostring(kind), vim.log.levels.ERROR)
    return false
  end
  if type(name) ~= "string" or name == "" then
    vim.notify("Empty theme name", vim.log.levels.ERROR)
    return false
  end

  -- Coerce persist to boolean (nil -> false)
  persist = not not persist

  if kind == "base46" then
    -- Apply Base46 palette/theme
    local ok = apply_base46_theme(name)
    -- Persist only when apply succeeded
    if ok and persist then
      local ok_write, err = pcall(write_persisted, "base46", name)
      if not ok_write then
        vim.notify("Persist failed (base46): " .. tostring(err), vim.log.levels.WARN)
      end
    end
    return ok
  else
    -- Apply regular :colorscheme
    local ok = apply_colorscheme(name)
    if ok and persist then
      local ok_write, err = pcall(write_persisted, "colorscheme", name)
      if not ok_write then
        vim.notify("Persist failed (colorscheme): " .. tostring(err), vim.log.levels.WARN)
      end
    end
    return ok
  end
end


function M.apply_persisted()
  local sel = read_persisted()
  if not sel then
    return
  end
  M.apply(sel.kind, sel.name, false)
end

-- ---------- Picker ----------

---@param preview_kind ThemeKind
---@param preview_name string
local function preview_apply(preview_kind, preview_name)
  if preview_kind == "base46" then
    apply_base46_theme(preview_name)
  else
    apply_colorscheme(preview_name)
  end
end

---@param s string
---@return ThemeKind kind
---@return string name
local function parse_labeled_item(s)
  -- Items are labeled like: "[base46] rosepine" or "[cs] tokyonight"
  local k, n = s:match("^%[(.-)%]%s+(.*)$")
  if k == "base46" then
    return "base46", n
  else
    return "colorscheme", n
  end
end

--- Open FzfLua picker with unified theme list and live preview.
function M.pick()
  local fzf_ok, fzf = pcall(require, "fzf-lua")
  if not fzf_ok then
    vim.notify("fzf-lua not found", vim.log.levels.ERROR)
    return
  end

  -- Build sources
  local b46 = list_base46_themes()
  ---@type string[] labeled
  local items = {}
  for _, name in ipairs(b46) do
    table.insert(items, "[base46] " .. name)
  end
  for _, name in ipairs(list_colorscheme_names()) do
    table.insert(items, "[cs] " .. name)
  end

  -- Remember state to revert if user cancels.
  local prev_kind  = current_base46_theme() and "base46" or "colorscheme" ---@type ThemeKind
  local prev_name  = prev_kind == "base46" and (current_base46_theme() or "unknown")
                     or (current_colorscheme() or "default")
  local live_applied_kind ---@type ThemeKind|nil
  local live_applied_name ---@type string|nil
  local confirmed = false

  local shell = require("fzf-lua.shell")

  fzf.fzf_exec(items, {
    prompt  = M._cfg.prompt,
    winopts = {
      height = M._cfg.height,
      width  = M._cfg.width,
      on_close = function()
        if not confirmed and live_applied_kind and live_applied_name then
          -- Revert to previous theme if the user closed without confirming.
          M.apply(prev_kind, prev_name, false)
        end
      end,
    },
    fzf_opts = {
      ["--no-multi"]       = "",
      ["--tiebreak"]       = "begin",
      ["--preview-window"] = M._cfg.preview_window,
    },
    -- Preview handler executed on item focus; applies live
    preview = shell.stringify_data(function(selection)
      local sel = selection and selection[1]
      if not sel or sel == "" then
        return
      end
      local k, n = parse_labeled_item(sel)
      preview_apply(k, n)
      live_applied_kind, live_applied_name = k, n
    end, {}, "{}"),
    actions = {
      -- <CR> confirm selection: apply and persist
      ["default"] = function(selected)
        local sel = selected and selected[1]
        if not sel or sel == "" then
          return
        end
        local k, n = parse_labeled_item(sel)
        confirmed = true
        M.apply(k, n, true)
      end,
      -- <C-r> revert immediately to previous theme (handy if preview got messy)
      ["ctrl-r"] = function()
        confirmed = true
        M.apply(prev_kind, prev_name, false)
      end,
    },
  })
end

-- ---------- Setup ----------

---@param cfg ThemePickerConfig|nil
function M.setup(cfg)
  M._cfg = vim.tbl_deep_extend("force", {}, DEFAULTS, cfg or {})
  if not M._cfg.persist_dir or M._cfg.persist_dir == "" then
    M._cfg.persist_dir = persist_dir()
  end
  ensure_dir(M._cfg.persist_dir)
end

-- Initialize defaults immediately for single-file usage.
M.setup({})

return M
