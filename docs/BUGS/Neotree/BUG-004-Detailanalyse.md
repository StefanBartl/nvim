# Neo-tree Reveal-Problem: Vollständige Analyse

## Table of content

  - [🔴 Kritische Probleme](#kritische-probleme)
    - [1. CWD-Sync überschreibt reveal aggressiv](#1-cwd-sync-berschreibt-reveal-aggressiv)
    - [2. open/init.lua fehlt reveal_file komplett](#2-openinitlua-fehlt-reveal_file-komplett)
    - [3. updir.lua bricht reveal](#3-updirlua-bricht-reveal)
    - [4. Position-Chaos](#4-position-chaos)
  - [🟡 Sicherheits- und Performance-Probleme](#sicherheits-und-performance-probleme)
    - [5. Race Conditions in cwd_sync](#5-race-conditions-in-cwd_sync)
    - [6. Buffer-Validierung fehlt](#6-buffer-validierung-fehlt)
    - [7. Fehlende Cleanup in Keymaps](#7-fehlende-cleanup-in-keymaps)
    - [8. Memory Leaks in Trash](#8-memory-leaks-in-trash)
  - [🟢 Struktur-Verbesserungen](#struktur-verbesserungen)
    - [9. Fehlende Types](#9-fehlende-types)
    - [10. Code-Duplikation](#10-code-duplikation)
  - [📋 Implementierungs-Checkliste](#implementierungs-checkliste)
    - [Sofort (Kritisch):](#sofort-kritisch)
    - [Kurzfristig (Performance):](#kurzfristig-performance)
    - [Mittelfristig (Struktur):](#mittelfristig-struktur)
  - [🎯 Die finale reveal_file Lösung](#die-finale-reveal_file-lsung)
    - [Neue Datei: reveal_manager.lua](#neue-datei-reveal_managerlua)
  - [🔧 Anpassungen in bestehenden Dateien](#anpassungen-in-bestehenden-dateien)
    - [plugins/neotree.lua](#pluginsneotreelua)
  - [📊 Zusammenfassung](#zusammenfassung)
    - [Root Cause des Problems:](#root-cause-des-problems)
    - [Die Lösung in 3 Schritten:](#die-lsung-in-3-schritten)
    - [Performance-Gewinn:](#performance-gewinn)
    - [Code-Qualität:](#code-qualitt)

---

## 🔴 Kritische Probleme

### 1. CWD-Sync überschreibt reveal aggressiv

**Problem in `cwd_sync.lua` (Zeilen 95-165):**

```lua
-- PROBLEM: sync_now() wird ständig getriggert
-- und überschreibt die reveal_file Position
function sync_now(cfg)
  -- ...
  if S.last_dir == dir then
    return  -- ❌ Zu früh! File könnte unterschiedlich sein
  end
  -- ...
end
```

**Warum das problematisch ist:**
- `last_dir` prüft nur Verzeichnis, nicht File
- Selbst wenn User manuell navigiert, wird nach 2s überschrieben
- `user_navigated` Flag ist unzuverlässig

**Lösung:**
```lua
---@class NeoTreeCwdSyncState
local S = {
  timer = nil,
  pending = false,
  last_dir = nil,
  last_file = nil,  -- ✅ NEU: Auch File tracken
  user_navigated = false,
  last_user_action = 0,
  pause_until = 0,  -- ✅ NEU: Explizite Pause
}

function sync_now(cfg)
  -- ✅ Prüfe auch File
  if S.last_dir == dir and S.last_file == path then
    return
  end

  -- ✅ Respektiere Pause
  if vim.loop.now() < S.pause_until then
    return
  end

  -- ✅ Immer reveal_file setzen
  cmd.execute({
    action = "show",
    source = "filesystem",
    dir = dir,
    reveal = true,
    reveal_file = path,  -- ✅ WICHTIG!
  })

  S.last_dir = dir
  S.last_file = path  -- ✅ NEU
end
```

---

### 2. open/init.lua fehlt reveal_file komplett

**Problem in `open/init.lua` (Zeilen 43-56):**

```lua
local function make_neotree_opener(position)
  -- ...
  return function()
    local opts = vim.tbl_extend("force", base_opts, { position = position })
    NeoCmd.execute(opts)
    -- ❌ Kein reveal_file! Öffnet immer bei cwd root
  end
end
```

**Lösung:**
```lua
local function make_neotree_opener(position)
  local ok_nt, NeoCmd = pcall(require, "neo-tree.command")
  if not ok_nt then
    vim.notify("[neotree.open] neo-tree.command not available", 2)
    return
  end

  return function()
    -- ✅ Hole aktuellen Buffer
    local current_buf = vim.api.nvim_get_current_buf()
    local current_file = vim.api.nvim_buf_get_name(current_buf)

    -- ✅ Bestimme Verzeichnis
    local dir = nil
    if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
      dir = vim.fn.fnamemodify(current_file, ":p:h")
    end

    local opts = vim.tbl_extend("force", base_opts, {
      position = position,
      dir = dir,  -- ✅ NEU
      reveal_file = current_file ~= "" and current_file or nil,  -- ✅ NEU
    })

    NeoCmd.execute(opts)

    -- ✅ Signalisiere manuelles Öffnen an cwd_sync
    local ok_sync, sync = pcall(require, "config.neotree.cwd_sync")
    if ok_sync and sync.pause_sync then
      sync.pause_sync(2000)  -- Pause 2 Sekunden
    end
  end
end
```

---

### 3. updir.lua bricht reveal

**Problem in `updir.lua` (Zeilen 14-76):**

```lua
function M.up_one_level(state)
  -- ...
  -- ❌ Nach updir ist keine Node selektiert
  -- ❌ User verliert Kontext wo er war
end
```

**Lösung:**
```lua
function M.up_one_level(state)
  -- Signalisiere an cwd_sync: "User navigiert manuell!"
  local ok_sync, sync_state = pcall(require, "config.neotree.cwd_sync")
  if ok_sync and sync_state.pause_sync then
    sync_state.pause_sync(3000)  -- ✅ 3s Pause
  end

  -- ... existing code ...

  -- ✅ NEU: Merke alte Position für Wiederauswahl
  local old_path = current_root

  -- Navigate up
  if state.commands and state.commands.navigate_up then
    state.commands.navigate_up(state)
  end

  -- ✅ NEU: Selektiere alte Position im Parent
  vim.defer_fn(function()
    local tree = state.tree
    if tree then
      -- Finde Node die altes Verzeichnis repräsentiert
      local parent_node = tree:get_node()
      if parent_node and parent_node.children then
        for _, child in ipairs(parent_node.children) do
          local child_path = child.path or child:get_id()
          if child_path == old_path then
            tree:focus_node(child)
            break
          end
        end
      end
    end
  end, 100)
end
```

---

### 4. Position-Chaos

**Problem:** Multiple Quellen setzen Position unterschiedlich:
- `cwd_sync`: forciert "left"
- `open/init.lua`: User wählt position
- `updir`: keine Position-Awareness

**Lösung: Zentrales Position-Management**

```lua
-- Neue Datei: lua/config/neotree/position_manager.lua
---@module 'config.neotree.position_manager'

local M = {}

---@type NeoTreePosition
local preferred_position = "left"

---@param pos NeoTreePosition
function M.set_preferred(pos)
  preferred_position = pos
end

---@return NeoTreePosition
function M.get_preferred()
  return preferred_position
end

---@return NeoTreePosition|nil
function M.get_current()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok then return nil end
  local state = manager.get_state("filesystem")
  return state and state.window and state.window.position
end

---@return boolean
function M.is_open()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        return true
      end
    end
  end
  return false
end

return M
```

---

## 🟡 Sicherheits- und Performance-Probleme

### 5. Race Conditions in cwd_sync

**Problem:**
```lua
-- Timer kann mehrfach starten
function schedule_sync(cfg)
  local timer = get_timer()
  timer:stop()  -- ❌ Nicht atomic!
  timer:start(cfg.debounce_ms, 0, function()
    -- Race wenn mehrere Events schnell kommen
  end)
end
```

**Lösung:**
```lua
local sync_scheduled = false

function schedule_sync(cfg)
  if sync_scheduled then return end  -- ✅ Guard
  sync_scheduled = true

  local timer = get_timer()
  timer:stop()

  timer:start(cfg.debounce_ms, 0, function()
    vim.schedule(function()
      sync_scheduled = false  -- ✅ Reset

      if vim.loop.now() < S.pause_until then
        return
      end

      sync_now(cfg)
    end)
  end)
end
```

---

### 6. Buffer-Validierung fehlt

**Problem in mehreren Dateien:**
```lua
local current_buf = vim.api.nvim_get_current_buf()
local name = vim.api.nvim_buf_get_name(current_buf)
-- ❌ Keine Prüfung ob Buffer gültig/geladen
```

**Lösung:**
```lua
---@param buf integer
---@return boolean
local function is_valid_reveal_buffer(buf)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end

  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end

  local buftype = vim.bo[buf].buftype
  if buftype ~= "" then
    return false  -- Terminal, Help, etc.
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then
    return false
  end

  -- Prüfe ob File existiert
  return vim.fn.filereadable(name) == 1
end
```

---

### 7. Fehlende Cleanup in Keymaps

**Problem in `keymaps/init.lua`:**
```lua
["<CR>"] = {
  function(state)
    -- ❌ Kein Error-Handling
    -- ❌ Preview wird nicht immer geschlossen
    pcall(function()
      local preview = require("neo-tree.sources.common.preview")
      if preview and preview.hide then
        preview.hide()
      end
    end)
    -- ...
  end
}
```

**Lösung:**
```lua
-- Wiederverwendbare Helper
local function safe_hide_preview()
  local ok = pcall(function()
    local preview = require("neo-tree.sources.common.preview")
    if preview and preview.hide then
      preview.hide()
    end
  end)
  return ok
end

local function safe_window_picker_open(state)
  local ok = pcall(function()
    local picker = require("window-picker")
    if picker then
      state.commands.open_with_window_picker(state)
    else
      state.commands.open(state)
    end
  end)

  if not ok then
    -- Fallback
    pcall(state.commands.open, state)
  end
end

["<CR>"] = {
  function(state)
    local node = state.tree:get_node()
    if not node then return end

    safe_hide_preview()

    if node.type == "directory" or (node:has_children() and not node:is_expanded()) then
      state.commands.toggle_node(state)
      return
    end

    safe_window_picker_open(state)
  end,
  desc = "Safe expand/collapse and open"
}
```

---

### 8. Memory Leaks in Trash

**Problem in `trash.lua`:**
```lua
local function cleanup_neotree_watchers(path)
  pcall(function()
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    -- ❌ Watchers werden nicht immer freigegeben
    if watcher and watcher.stop_all then
      watcher.stop_all()
    end
  end)
end
```

**Lösung:**
```lua
local active_watchers = {}  -- ✅ Track watchers

local function cleanup_neotree_watchers(path)
  -- Stop spezifische Watchers
  if active_watchers[path] then
    pcall(function()
      active_watchers[path]:stop()
      active_watchers[path]:close()
    end)
    active_watchers[path] = nil
  end

  -- Stop alle wenn nötig
  pcall(function()
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    if watcher and watcher.stop_all then
      watcher.stop_all()
    end
  end)

  -- Force GC
  collectgarbage("collect")
end
```

---

## 🟢 Struktur-Verbesserungen

### 9. Fehlende Types

**Problem:** Viele Funktionen haben keine oder unvollständige Type-Annotations

**Lösung: Neue Types-Datei**

```lua
-- lua/config/neotree/types/reveal.lua
---@class NeoTreeRevealContext
---@field buf integer Buffer nummer
---@field file string Absolute file path
---@field dir string Parent directory
---@field position NeoTreePosition Gewünschte Position
---@field force_reveal boolean Force reveal auch wenn schon offen

---@class NeoTreeRevealResult
---@field success boolean
---@field reason string|nil Fehlergrund wenn nicht erfolgreich
---@field node table|nil Gefundene Node
```

---

### 10. Code-Duplikation

**Problem:** Gleiche Logik mehrfach:
- Buffer-Validierung 3x
- Preview-Hiding 5x
- Position-Queries 4x

**Lösung: Utils-Modul**

```lua
-- lua/config/neotree/utils.lua
local M = {}

function M.is_valid_file_buffer(buf)
  -- ... (siehe oben)
end

function M.safe_hide_preview()
  -- ... (siehe oben)
end

function M.get_current_position()
  -- ... (siehe oben)
end

function M.get_buffer_context(buf)
  if not M.is_valid_file_buffer(buf) then
    return nil
  end

  local file = vim.api.nvim_buf_get_name(buf)
  local dir = vim.fn.fnamemodify(file, ":p:h")

  return {
    buf = buf,
    file = file,
    dir = dir,
  }
end

return M
```

---

## 📋 Implementierungs-Checkliste

### Sofort (Kritisch):

- [ ] `cwd_sync.lua`: `last_file` tracking hinzufügen
- [ ] `cwd_sync.lua`: `pause_sync(ms)` API implementieren
- [ ] `open/init.lua`: `reveal_file` in alle opener
- [ ] `updir.lua`: Node-Selektion nach updir
- [ ] Buffer-Validierung überall einbauen

### Kurzfristig (Performance):

- [ ] Race-Condition Guards in `cwd_sync`
- [ ] Memory-Leak Fix in `trash.lua`
- [ ] Preview-Cleanup vereinheitlichen
- [ ] Timer-Cleanup in allen Modulen

### Mittelfristig (Struktur):

- [ ] `position_manager.lua` erstellen
- [ ] `utils.lua` für gemeinsame Funktionen
- [ ] Types für alle Module vervollständigen
- [ ] Tests für reveal-Logik

---

## 🎯 Die finale reveal_file Lösung

### Neue Datei: reveal_manager.lua

```lua
---@module 'config.neotree.reveal_manager'
local M = {}

local utils = require("config.neotree.utils")

---@type NeoTreeRevealContext|nil
local last_reveal = nil

---@param ctx NeoTreeRevealContext
---@return boolean success
function M.reveal(ctx)
  if not ctx or not ctx.file or ctx.file == "" then
    return false
  end

  local ok_cmd, cmd = pcall(require, "neo-tree.command")
  if not ok_cmd then
    return false
  end

  -- Merke für Duplikats-Check
  last_reveal = ctx

  -- Execute mit allen nötigen Parametern
  local ok = pcall(function()
    cmd.execute({
      action = "show",
      source = "filesystem",
      position = ctx.position or "left",
      dir = ctx.dir,
      reveal = true,
      reveal_file = ctx.file,
    })
  end)

  return ok
end

---@param buf integer|nil
---@param position NeoTreePosition|nil
---@return boolean
function M.reveal_buffer(buf, position)
  buf = buf or vim.api.nvim_get_current_buf()

  local ctx = utils.get_buffer_context(buf)
  if not ctx then
    return false
  end

  ctx.position = position or "left"

  return M.reveal(ctx)
end

---@param ctx NeoTreeRevealContext
---@return boolean
function M.should_reveal(ctx)
  if not last_reveal then
    return true
  end

  -- Gleiche File = skip
  if last_reveal.file == ctx.file then
    return false
  end

  return true
end

function M.clear()
  last_reveal = nil
end

return M
```

---

## 🔧 Anpassungen in bestehenden Dateien

### plugins/neotree.lua

```lua
opts = {
  -- ...
  filesystem = {
    bind_to_cwd = false,  -- ✅ ÄNDERN: Nicht an cwd binden
    follow_current_file = {
      enabled = true,
      leave_dirs_open = true,  -- ✅ NEU: Dirs offen lassen
    },
    -- ...
  },

  -- ✅ NEU: Event-Handler für reveal
  event_handlers = {
    {
      event = "neo_tree_buffer_enter",
      handler = function(args)
        local reveal_mgr = require("config.neotree.reveal_manager")
        local buf = vim.api.nvim_get_current_buf()

        -- Reveal nur wenn nötig
        vim.defer_fn(function()
          reveal_mgr.reveal_buffer(buf)
        end, 50)
      end,
    },
    -- ... existing handlers ...
  },
}
```

---

## 📊 Zusammenfassung

### Root Cause des Problems:

1. **`cwd_sync` ist zu aggressiv** und überschreibt User-Actions
2. **`reveal_file` fehlt** in den meisten Öffnungs-Szenarien
3. **Kein zentrales State-Management** für Position/Reveal
4. **Race Conditions** durch unkoordinierte Timer

### Die Lösung in 3 Schritten:

1. **`reveal_manager.lua`**: Zentrales Reveal-Handling
2. **`pause_sync()` API**: Cwd-Sync kann pausiert werden
3. **`reveal_file` überall**: Jedes Öffnen bekommt reveal_file

### Performance-Gewinn:

- ✅ Keine redundanten Refreshes
- ✅ Keine Race Conditions
- ✅ Besseres Memory-Management
- ✅ Konsistentes Verhalten

### Code-Qualität:

- ✅ Zentrale Utils statt Duplikation
- ✅ Vollständige Type-Annotations
- ✅ Error-Handling überall
- ✅ Testbare Module

---
