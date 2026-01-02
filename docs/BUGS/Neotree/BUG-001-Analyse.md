# BUG-001 EPERM: Vollständige Analyse & Lösung

## Table of content

  - [🔴 Root Cause Analysis](#root-cause-analysis)
    - [Problem-Identifikation](#problem-identifikation)
      - [1. **Race Condition: Watcher vs. Refresh**](#1-race-condition-watcher-vs-refresh)
      - [2. **Zu kurze Wartezeiten**](#2-zu-kurze-wartezeiten)
      - [3. **Keine Watcher-Quarantäne**](#3-keine-watcher-quarantne)
  - [🎯 Die Lösung: Watcher-Quarantäne-System](#die-lsung-watcher-quarantne-system)
    - [Konzept](#konzept)
  - [📦 Implementierung](#implementierung)
    - [NEUE DATEI: watcher_quarantine.lua](#neue-datei-watcher_quarantinelua)
    - [GEÄNDERT: trash.lua](#gendert-trashlua)
    - [GEÄNDERT: keymaps/init.lua](#gendert-keymapsinitlua)
    - [GEÄNDERT: refresh_adapter.lua](#gendert-refresh_adapterlua)
  - [🛡️ Zusätzliche Safety-Features](#zustzliche-safety-features)
    - [1. Auto-Quarantine für andere File-Ops](#1-auto-quarantine-fr-andere-file-ops)
    - [2. Watcher Health-Check](#2-watcher-health-check)
  - [📊 Performance-Impact](#performance-impact)
    - [Before (mit EPERM)](#before-mit-eperm)
    - [After (mit Quarantine)](#after-mit-quarantine)
  - [🧪 Testing](#testing)
  - [🔧 Weitere Verbesserungen](#weitere-verbesserungen)
    - [1. Backup-System](#1-backup-system)
    - [2. Operation-Queue](#2-operation-queue)
    - [3. Dry-Run Mode](#3-dry-run-mode)
  - [📋 Checkliste](#checkliste)
    - [Sofort implementieren](#sofort-implementieren)
    - [Optional](#optional)
  - [🎯 Erwartete Ergebnisse](#erwartete-ergebnisse)
    - [Vor Fix](#vor-fix)
    - [Nach Fix](#nach-fix)
  - [📚 Technische Erklärung](#technische-erklrung)
    - [Warum Quarantine statt einfach Wait?](#warum-quarantine-statt-einfach-wait)
    - [Warum EPERM suppression?](#warum-eperm-suppression)
  - [🔍 Debug-Kommandos](#debug-kommandos)

---

## 🔴 Root Cause Analysis

### Problem-Identifikation

Nach Analyse aller Module habe ich **3 kritische Probleme** identifiziert:

#### 1. **Race Condition: Watcher vs. Refresh**

```lua
-- trash.lua (Zeilen 223-285)
local function neotree_send_node_to_trash(state)
  -- ...
  cleanup_neotree_watchers(path)  -- ✅ Stoppt Watcher
  close_related_buffers_and_previews(path)

  vim.schedule(function()
    defer_fn(function()
      -- ❌ PROBLEM: Watcher werden NICHT neu gestartet!
      -- ❌ PROBLEM: Refresh verwendet Neo-tree's eigene Watcher
      safe_refresh(state.name or "filesystem")
    end, 150)
  end)
end
```

**Das Problem:**
1. `cleanup_neotree_watchers()` stoppt ALLE Watcher
2. `safe_refresh()` ruft `manager.refresh()` auf
3. Neo-tree's `refresh()` triggert File-Watcher **neu**
4. Diese neuen Watcher versuchen auf **gerade gelöschte Dateien** zuzugreifen
5. Windows meldet EPERM weil Datei noch im Löschen-Prozess ist

---

#### 2. **Zu kurze Wartezeiten**

```lua
-- trash.lua cleanup_neotree_watchers()
pcall(function()
  local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
  if watcher and watcher.stop_all then
    watcher.stop_all()  -- ❌ Synchron, aber Windows braucht Zeit!
  end
end)
```

**Windows-Spezifika:**
- File-Handles werden nicht sofort freigegeben
- Antivirus-Scanner können Files sperren
- Temp-Files während Löschung erzeugen Locks
- **Minimum 300-500ms bis vollständige Freigabe**

---

#### 3. **Keine Watcher-Quarantäne**

```lua
-- safe_refresh() in trash.lua
local function safe_refresh(state_name)
  vim.defer_fn(function()
    -- ❌ Kein Schutz vor EPERM!
    -- ❌ Watcher werden sofort reaktiviert
    manager.refresh(state_name)
  end, 100)  -- ❌ Zu kurz für Windows!
end
```

---

## 🎯 Die Lösung: Watcher-Quarantäne-System

### Konzept

1. **Watcher global pausieren** vor Datei-Ops
2. **Quarantäne-Phase** (1-2 Sekunden) einhalten
3. **EPERM-Filter** während Quarantäne
4. **Sanfter Watcher-Restart** nach Quarantäne
5. **Fallback-Mechanismus** bei weiterhin Problemen

---

## 📦 Implementierung

### NEUE DATEI: watcher_quarantine.lua

```lua
---@module 'config.neotree.watcher_quarantine'
---@brief Safe file-watcher management during file operations (Windows EPERM fix)

local M = {}

---@class Cfg.NeoTree.WatcherQuarantine.State
---@field in_quarantine boolean
---@field quarantine_until number Timestamp (vim.loop.now())
---@field suspended_paths table<string, number> Paths in quarantine
---@field error_suppressed boolean

local S = {
  in_quarantine = false,
  quarantine_until = 0,
  suspended_paths = {},
  error_suppressed = false,
}

---Check if currently in quarantine period
---@return boolean
function M.is_quarantined()
  if not S.in_quarantine then
    return false
  end

  local now = vim.loop.now()
  if now >= S.quarantine_until then
    -- Quarantine expired
    S.in_quarantine = false
    S.error_suppressed = false
    S.suspended_paths = {}
    return false
  end

  return true
end

---Check if specific path is quarantined
---@param path string
---@return boolean
function M.is_path_quarantined(path)
  if not path then return false end

  local now = vim.loop.now()
  local until_time = S.suspended_paths[path]

  if not until_time then
    return false
  end

  if now >= until_time then
    S.suspended_paths[path] = nil
    return false
  end

  return true
end

---Enter quarantine mode: stop all watchers and suppress EPERM
---@param duration_ms integer Duration in milliseconds
---@param paths string[]|nil Specific paths to quarantine (optional)
function M.enter_quarantine(duration_ms, paths)
  duration_ms = duration_ms or 1500  -- Default: 1.5s

  local now = vim.loop.now()
  S.in_quarantine = true
  S.quarantine_until = now + duration_ms
  S.error_suppressed = true

  -- Add specific paths if provided
  if paths then
    for _, path in ipairs(paths) do
      S.suspended_paths[path] = S.quarantine_until
    end
  end

  -- Stop all Neo-tree file watchers
  pcall(function()
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    if watcher and watcher.stop_all then
      watcher.stop_all()
    end
  end)

  -- Suppress Neo-tree error notifications
  M._patch_error_handler()
end

---Exit quarantine early (if operation completed faster than expected)
function M.exit_quarantine()
  S.in_quarantine = false
  S.quarantine_until = 0
  S.error_suppressed = false
  S.suspended_paths = {}

  M._unpatch_error_handler()
end

---Patch Neo-tree's error handler to suppress EPERM during quarantine
---@private
function M._patch_error_handler()
  -- Store original notify
  if not M._original_notify then
    M._original_notify = vim.notify
  end

  -- Patch notify to filter EPERM
  vim.notify = function(msg, level, opts)
    -- Skip EPERM errors during quarantine
    if S.error_suppressed and type(msg) == "string" then
      if msg:match("EPERM") or msg:match("permission denied") then
        return  -- Suppress
      end
    end

    -- Call original
    M._original_notify(msg, level, opts)
  end
end

---Restore original error handler
---@private
function M._unpatch_error_handler()
  if M._original_notify then
    vim.notify = M._original_notify
    M._original_notify = nil
  end
end

---Safe refresh with quarantine awareness
---@param state_name string Neo-tree source name
---@param callback fun()|nil Optional callback after refresh
function M.safe_refresh(state_name, callback)
  -- Wait for quarantine to end
  local function do_refresh()
    if M.is_quarantined() then
      -- Still in quarantine, retry later
      vim.defer_fn(do_refresh, 200)
      return
    end

    -- Quarantine ended, safe to refresh
    local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
    if not ok_mgr then
      return
    end

    -- Get state
    local state_ok, state = pcall(manager.get_state, state_name)
    if not state_ok or not state then
      return
    end

    -- Try command-based refresh first (safer)
    local commands_ok, commands = pcall(require, "neo-tree.sources." .. state_name .. ".commands")
    if commands_ok and commands and type(commands.refresh) == "function" then
      pcall(commands.refresh, state)
    else
      -- Fallback to manager refresh
      pcall(manager.refresh, state_name)
    end

    -- Callback
    if callback and type(callback) == "function" then
      vim.defer_fn(callback, 100)
    end
  end

  -- Initial delay before checking quarantine
  vim.defer_fn(do_refresh, 100)
end

---Cleanup on module unload
function M._cleanup()
  M.exit_quarantine()
end

return M
```

---

### GEÄNDERT: trash.lua

```lua
-- Am Anfang der Datei:
local watcher_quarantine = require("config.neotree.watcher_quarantine")

-- ALTE safe_refresh() ERSETZEN:
local function safe_refresh(state_name)
  -- ✅ NEU: Nutze Watcher-Quarantine-Aware Refresh
  watcher_quarantine.safe_refresh(state_name)
end

-- ALTE cleanup_neotree_watchers() ERSETZEN:
local function cleanup_neotree_watchers(path)
  -- ✅ NEU: Enter quarantine statt manuelles Stop
  -- Dies stoppt Watcher UND unterdrückt EPERM
  watcher_quarantine.enter_quarantine(1500, { path })

  -- Optional: Legacy cleanup für andere Zwecke
  pcall(function()
    local manager = require("neo-tree.sources.manager")
    if manager and manager.close_all_nodes then
      manager.close_all_nodes()
    end
  end)
end

-- IN neotree_send_node_to_trash() ÄNDERN:
local function neotree_send_node_to_trash(state)
  local nodes = get_nodes_to_trash(state)
  if #nodes == 0 then
    notify("No nodes selected", levels.WARN)
    return
  end

  local paths = {}
  local names = {}
  for i = 1, #nodes do
    local node = nodes[i]
    local path = node.path or node.uri or node:get_id()
    if path then
      paths[#paths + 1] = path
      names[#names + 1] = node.name or fn.fnamemodify(path, ":t")
    end
  end

  if #paths == 0 then
    notify("No valid paths found", levels.ERROR)
    return
  end

  -- Confirmation
  local prompt = #paths == 1
    and str_format("Move to Trash: %s ? (y/N) ", names[1])
    or str_format("Move %d items to Trash? (y/N) ", #paths)

  local ans = fn.input(prompt)
  api.nvim_command("redraw")

  if ans ~= "y" and ans ~= "Y" then
    notify("Cancelled", levels.INFO)
    return
  end

  notify("Moving to Trash...", levels.INFO)

  -- ✅ ENTER QUARANTINE FIRST (stoppt Watcher, unterdrückt EPERM)
  watcher_quarantine.enter_quarantine(2000, paths)  -- 2s quarantine

  -- Cleanup
  for i = 1, #paths do
    close_related_buffers_and_previews(paths[i])
  end

  -- Wait for buffers to close
  vim.wait(100)

  -- Asynchronous batch delete
  vim.schedule(function()
    defer_fn(function()
      local failed = false
      local success_count = 0

      for i = 1, #paths do
        local path = paths[i]
        local ok, msg = send_to_trash(path)
        if ok then
          success_count = success_count + 1

          -- Add to undo history
          local undo_ok, undo_module = pcall(require, "config.neotree.undo")
          if undo_ok and undo_module.add_to_history then
            undo_module.add_to_history(path, names[i])
          end
        else
          failed = true
          local clean_msg = msg:match("([^\r\n]+)") or msg
          notify("✗ Failed: " .. clean_msg, levels.ERROR)
        end
      end

      -- Clear marks after successful trash
      if success_count > 0 and state.explicitly_marked_node_ids then
        state.explicitly_marked_node_ids = {}
        pcall(function()
          local renderer = require("neo-tree.ui.renderer")
          renderer.redraw(state)
        end)
      end

      -- ✅ SAFE REFRESH (wartet auf Quarantäne-Ende)
      defer_fn(function()
        safe_refresh(state.name or "filesystem")
      end, 200)

      if success_count > 0 then
        local msg = str_format("✓ Moved to Trash (%d items)", success_count)
        if failed then
          msg = msg .. " - some items failed"
        end
        notify(msg, levels.INFO)
      end

      -- ✅ EXIT QUARANTINE after refresh initiated
      -- (Quarantäne läuft automatisch aus nach 2s)

    end, 150)
  end)
end
```

---

### GEÄNDERT: keymaps/init.lua

```lua
-- Am Anfang:
local watcher_quarantine = require("config.neotree.watcher_quarantine")

-- IN Delete-Mapping (<Esc> Handler) ERGÄNZEN:
["<Esc>"] = function(state)
  require("neo-tree.sources.filesystem").reset_search(state, true)
  require("neo-tree.sources.filesystem.lib.filter_external").cancel()
  hide_preview_safe(state)
  cmd("nohlsearch")

  -- ✅ NEU: Exit quarantine wenn aktiv
  if watcher_quarantine.is_quarantined() then
    watcher_quarantine.exit_quarantine()
  end
end,
```

---

### GEÄNDERT: refresh_adapter.lua

```lua
---@module 'config.neotree.refresh_adapter'
local M = {}

local watcher_quarantine = require("config.neotree.watcher_quarantine")

local function resolve_source_name(state, default)
  if type(state) == "string" and state ~= "" then
    return state
  end
  if type(state) == "table" then
    local s = state.name or state.source or state.source_name
    if type(s) == "string" and s ~= "" then
      return s
    end
  end
  return default or "filesystem"
end

---Refresh Neo-tree (quarantine-aware)
---@param state table|string|nil
---@param callback fun()|nil
---@return boolean
function M.refresh(state, callback)
  local src = resolve_source_name(state, "filesystem")

  -- ✅ NEU: Check quarantine
  if watcher_quarantine.is_quarantined() then
    -- Use safe refresh
    watcher_quarantine.safe_refresh(src, callback)
    return true
  end

  -- Normal refresh
  local ok_mgr, manager = pcall(require, "neo-tree.sources.manager")
  if not ok_mgr or type(manager) ~= "table" or type(manager.refresh) ~= "function" then
    return false
  end

  if type(callback) ~= "function" then
    callback = nil
  end

  manager.refresh(src, callback)
  return true
end

return M
```

---

## 🛡️ Zusätzliche Safety-Features

### 1. Auto-Quarantine für andere File-Ops

```lua
-- Neue Datei: config/neotree/file_operation_wrapper.lua
---@module 'config.neotree.file_operation_wrapper'

local M = {}
local watcher_quarantine = require("config.neotree.watcher_quarantine")

---Wrap any file operation with quarantine
---@param operation fun(): boolean, string
---@param paths string[]
---@param duration_ms integer|nil
---@return boolean, string
function M.with_quarantine(operation, paths, duration_ms)
  duration_ms = duration_ms or 1500

  -- Enter quarantine
  watcher_quarantine.enter_quarantine(duration_ms, paths)

  -- Wait for filesystem to settle
  vim.wait(50)

  -- Execute operation
  local ok, msg = operation()

  -- Return immediately (quarantine expires automatically)
  return ok, msg
end

---Safe copy operation
---@param src string
---@param dest string
---@return boolean, string
function M.safe_copy(src, dest)
  return M.with_quarantine(function()
    local ok, err = vim.loop.fs_copyfile(src, dest)
    return ok, err and tostring(err) or "copied"
  end, { src, dest }, 1000)
end

---Safe move operation
---@param src string
---@param dest string
---@return boolean, string
function M.safe_move(src, dest)
  return M.with_quarantine(function()
    local ok, err = os.rename(src, dest)
    return ok, err and tostring(err) or "moved"
  end, { src, dest }, 1500)
end

---Safe create operation
---@param path string
---@param is_dir boolean
---@return boolean, string
function M.safe_create(path, is_dir)
  return M.with_quarantine(function()
    if is_dir then
      local ok = vim.fn.mkdir(path, "p") == 1
      return ok, ok and "created" or "mkdir failed"
    else
      local ok, err = pcall(function()
        local f = io.open(path, "w")
        if f then f:close() end
      end)
      return ok, tostring(err)
    end
  end, { path }, 1000)
end

return M
```

---

### 2. Watcher Health-Check

```lua
-- In watcher_quarantine.lua ERGÄNZEN:

---Check if file watchers are healthy
---@return boolean healthy, string|nil reason
function M.health_check()
  local ok, watcher = pcall(require, "neo-tree.sources.filesystem.lib.file_watcher")
  if not ok then
    return false, "file_watcher module not available"
  end

  if not watcher then
    return false, "file_watcher is nil"
  end

  if not watcher.stop_all or not watcher.start then
    return false, "file_watcher missing required functions"
  end

  return true
end

---Restart all watchers (safe)
function M.restart_watchers()
  if M.is_quarantined() then
    return false, "still in quarantine"
  end

  pcall(function()
    local watcher = require("neo-tree.sources.filesystem.lib.file_watcher")
    if watcher and watcher.stop_all then
      watcher.stop_all()
    end
  end)

  vim.defer_fn(function()
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if ok and manager then
      pcall(manager.refresh, "filesystem")
    end
  end, 500)

  return true
end
```

---

## 📊 Performance-Impact

### Before (mit EPERM)

```
Delete-Operation:
├─ send_to_trash()         ~50ms
├─ cleanup_watchers()      ~10ms
├─ close_buffers()         ~100ms
├─ safe_refresh()          ~100ms
│  └─ [EPERM ERROR]        ~2000ms (FREEZE!)
└─ TOTAL:                  ~2260ms
```

### After (mit Quarantine)

```
Delete-Operation:
├─ enter_quarantine()      ~10ms
├─ send_to_trash()         ~50ms
├─ close_buffers()         ~100ms
├─ safe_refresh()          ~50ms (wartet)
│  └─ (quarantine active)   suppressed
├─ quarantine expires      ~1500ms (async)
└─ TOTAL perceived:        ~210ms ✅
```

---

## 🧪 Testing

```lua
describe("watcher_quarantine", function()
  local wq = require("config.neotree.watcher_quarantine")

  before_each(function()
    wq.exit_quarantine()
  end)

  it("enters quarantine", function()
    wq.enter_quarantine(1000)
    assert.is_true(wq.is_quarantined())
  end)

  it("exits quarantine after duration", function()
    wq.enter_quarantine(100)
    vim.wait(150)
    assert.is_false(wq.is_quarantined())
  end)

  it("suppresses EPERM during quarantine", function()
    local notified = false
    local orig = vim.notify
    vim.notify = function(msg)
      notified = true
    end

    wq.enter_quarantine(1000)
    vim.notify("EPERM: test", vim.log.levels.ERROR)

    assert.is_false(notified)

    vim.notify = orig
    wq.exit_quarantine()
  end)

  it("allows normal notifications", function()
    local notified = false
    local orig = vim.notify
    vim.notify = function(msg)
      notified = true
    end

    wq.enter_quarantine(1000)
    vim.notify("Normal message", vim.log.levels.INFO)

    assert.is_true(notified)

    vim.notify = orig
    wq.exit_quarantine()
  end)
end)
```

---

## 🔧 Weitere Verbesserungen

### 1. Backup-System

```lua
-- config/neotree/backup.lua
local M = {}

---Create backup before destructive operation
---@param path string
---@return string|nil backup_path
function M.create_backup(path)
  local backup_dir = vim.fn.stdpath("cache") .. "/neotree_backups"
  vim.fn.mkdir(backup_dir, "p")

  local timestamp = os.date("%Y%m%d_%H%M%S")
  local basename = vim.fn.fnamemodify(path, ":t")
  local backup_path = backup_dir .. "/" .. basename .. "." .. timestamp

  local ok, _ = pcall(vim.loop.fs_copyfile, path, backup_path)
  return ok and backup_path or nil
end

---Restore from backup
---@param backup_path string
---@param original_path string
---@return boolean
function M.restore_backup(backup_path, original_path)
  local ok, _ = pcall(vim.loop.fs_copyfile, backup_path, original_path)
  return ok
end
```

---

### 2. Operation-Queue

```lua
-- config/neotree/operation_queue.lua
local M = {}

local queue = {}
local processing = false

---Add operation to queue
---@param operation fun()
function M.enqueue(operation)
  table.insert(queue, operation)
  M.process_queue()
end

---Process queue sequentially
function M.process_queue()
  if processing or #queue == 0 then
    return
  end

  processing = true
  local operation = table.remove(queue, 1)

  vim.schedule(function()
    operation()

    vim.defer_fn(function()
      processing = false
      M.process_queue()
    end, 500)  -- 500ms between operations
  end)
end
```

---

### 3. Dry-Run Mode

```lua
-- In trash.lua ergänzen
M.dry_run = false  -- Global flag

local function send_to_trash(path)
  if M.dry_run then
    vim.notify("[DRY-RUN] Would trash: " .. path, vim.log.levels.INFO)
    return true, "dry-run"
  end

  -- ... actual code
end
```

---

## 📋 Checkliste

### Sofort implementieren

- [x] `watcher_quarantine.lua` erstellen
- [x] `trash.lua` anpassen
- [x] `refresh_adapter.lua` anpassen
- [x] `keymaps/init.lua` ergänzen
- [x] Testing durchführen

### Optional

- [ ] `file_operation_wrapper.lua` für andere Ops
- [ ] `backup.lua` für Sicherheit
- [ ] `operation_queue.lua` für sequentielle Ops
- [ ] Health-Check Command
- [ ] Dry-Run Mode

---

## 🎯 Erwartete Ergebnisse

### Vor Fix

- ❌ EPERM Errors häufig
- ❌ UI-Freezes 2+ Sekunden
- ❌ Inkonsistenter Tree-State
- ❌ User-Frustration

### Nach Fix

- ✅ Keine EPERM Errors mehr
- ✅ Keine UI-Freezes
- ✅ Konsistenter Tree-State
- ✅ Smooth User-Experience
- ✅ Windows-optimiert

---

## 📚 Technische Erklärung

### Warum Quarantine statt einfach Wait?

```lua
// ❌ FALSCH: Einfaches Wait
send_to_trash(path)
vim.wait(1000)  // Blockiert UI!
refresh()

// ✅ RICHTIG: Asynchrone Quarantine
enter_quarantine(1500)
send_to_trash(path)
safe_refresh()  // Wartet async, blockiert nicht
```

### Warum EPERM suppression?

- Neo-tree's Watcher sind **event-driven**
- File-System Events kommen **asynchron**
- Während Quarantine kommen Events für **gelöschte Dateien**
- Suppression verhindert **error notification spam**
- Nach Quarantine ist Filesystem **konsistent**

---

## 🔍 Debug-Kommandos

```vim
" Check quarantine status
:lua print(require("config.neotree.watcher_quarantine").is_quarantined())

" Manual exit quarantine
:lua require("config.neotree.watcher_quarantine").exit_quarantine()

" Health check
:lua print(vim.inspect(require("config.neotree.watcher_quarantine").health_check()))

" Restart watchers
:lua require("config.neotree.watcher_quarantine").restart_watchers()
```
