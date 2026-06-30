# cwd_sync

Hält Neo-tree's Filesystem-Root automatisch mit dem aktiven Buffer synchron. Revealed die aktuelle Datei bei Buffer-/Window-/Tab-Wechseln.

## Table of content

  - [Features](#features)
  - [Quick Start](#quick-start)
  - [Configuration Options](#configuration-options)
    - [`debounce_ms` (default: `150`)](#debounce_ms-default-150)
    - [`keep_focus` (default: `true`)](#keep_focus-default-true)
    - [`also_set_nvim_cwd` (default: `false`)](#also_set_nvim_cwd-default-false)
    - [`open_if_closed` (default: `false`)](#open_if_closed-default-false)
    - [`use_project_root` (default: `true`)](#use_project_root-default-true)
    - [`project_root_fallback_to_bufdir` (default: `true`)](#project_root_fallback_to_bufdir-default-true)
  - [API](#api)
    - [`setup(config)`](#setupconfig)
    - [`pause_sync(ms)`](#pause_syncms)
  - [Interne Logik](#interne-logik)
    - [State Management](#state-management)
    - [Sync-Trigger](#sync-trigger)
    - [Duplikats-Prevention](#duplikats-prevention)
    - [Race-Condition Prevention](#race-condition-prevention)
    - [User-Navigation Detection](#user-navigation-detection)
  - [Integration mit anderen Modulen](#integration-mit-anderen-modulen)
    - [reveal_manager.lua](#reveal_managerlua)
    - [open/init.lua](#openinitlua)
    - [updir.lua](#updirlua)
  - [Buffer-Validierung](#buffer-validierung)
  - [Performance-Charakteristiken](#performance-charakteristiken)
  - [Troubleshooting](#troubleshooting)
    - [Problem: Sync triggert zu oft](#problem-sync-triggert-zu-oft)
    - [Problem: Sync funktioniert nicht](#problem-sync-funktioniert-nicht)
    - [Problem: Position wird falsch](#problem-position-wird-falsch)
    - [Problem: Focus springt zu Neo-tree](#problem-focus-springt-zu-neo-tree)
    - [Problem: Globales CWD wird geändert](#problem-globales-cwd-wird-gendert)
  - [Best Practices](#best-practices)
    - [✅ DO](#do)
    - [❌ DON'T](#dont)
  - [Advanced Usage](#advanced-usage)
    - [Custom Project Root Detection](#custom-project-root-detection)
    - [Conditional Sync](#conditional-sync)
    - [Sync mit Custom Events](#sync-mit-custom-events)
  - [Testing](#testing)
  - [Changelog](#changelog)
    - [v2.0.0 (2024-01)](#v200-2024-01)
    - [v1.0.0 (2023-12)](#v100-2023-12)
  - [Dependencies](#dependencies)

---

## Features

* **Auto-Reveal on Switch**: Revealed automatisch die aktuelle Datei beim Wechseln
* **Project-Root Detection**: Nutzt Project-Root statt CWD wenn verfügbar
* **Smart Debouncing**: Verhindert excessive Refreshes bei schnellen Wechseln
* **Manual Navigation Pause**: Respektiert User-Navigation und pausiert Auto-Sync
* **Race-Condition Safe**: Atomare Timer-Operations
* **Focus Preservation**: Optional: Behält Focus im aktiven Window
* **Cross-Platform**: Nutzt `vim.uv` oder `vim.loop` (Neovim 0.9+)

---

## Quick Start

```lua
-- In plugins/neotree.lua config:
require("config.neotree.cwd_sync").setup({
  debounce_ms = 150,                     -- Debounce-Zeit in Millisekunden
  keep_focus = true,                     -- Focus bleibt im aktiven Window
  also_set_nvim_cwd = false,             -- Setzt auch :pwd
  open_if_closed = false,                -- Öffnet Neo-tree wenn geschlossen
  use_project_root = true,               -- Nutzt Project-Root wenn verfügbar
  project_root_fallback_to_bufdir = true, -- Fallback zu Buffer-Dir
})
```

---

## Configuration Options

### `debounce_ms` (default: `150`)

Wartezeit in Millisekunden bevor Sync ausgelöst wird. Verhindert excessive Refreshes bei schnellen Buffer-Wechseln.

```lua
debounce_ms = 150  -- Standard: 150ms

-- Für große Repos/langsame Systeme:
debounce_ms = 300

-- Für schnelle Reaktion:
debounce_ms = 80
```

**Performance-Impact:**
- Niedriger = schnellere Reaktion, mehr CPU
- Höher = bessere Performance, leichte Verzögerung

---

### `keep_focus` (default: `true`)

Behält Focus im aktiven Window nach Reveal. Wenn `false`, springt Cursor zu Neo-tree.

```lua
keep_focus = true  -- ✅ Empfohlen: Nicht ablenkend

-- Alternative: Focus zu Neo-tree
keep_focus = false  -- Cursor springt zu Neo-tree nach Reveal
```

---

### `also_set_nvim_cwd` (default: `false`)

Setzt zusätzlich Neovim's globales `:pwd` auf das Reveal-Verzeichnis.

```lua
also_set_nvim_cwd = false  -- ✅ Empfohlen: Keine globalen Side-Effects

-- Wenn du `:pwd` mit Neo-tree sync willst:
also_set_nvim_cwd = true  -- ⚠️ Vorsicht: Ändert globales CWD
```

**Warnung:** Global CWD ändern kann andere Plugins beeinflussen!

---

### `open_if_closed` (default: `false`)

Öffnet Neo-tree automatisch wenn geschlossen und Sync getriggert wird.

```lua
open_if_closed = false  -- ✅ Standard: Nur sync wenn offen

-- Auto-Open bei jedem Buffer-Wechsel:
open_if_closed = true  -- ⚠️ Kann störend sein
```

---

### `use_project_root` (default: `true`)

Nutzt Project-Root (via `config.neotree.actions.project_root`) statt Buffer-Directory.

```lua
use_project_root = true  -- ✅ Zeigt Project-Structure

-- Wenn du immer Buffer-Dir willst:
use_project_root = false
```

**Projekt-Root Detection:**
- Git-Root (`.git` directory)
- Custom Markers (via `config.neotree.actions.project_root` config)
- Fallback zu Buffer-Dir wenn kein Root gefunden

---

### `project_root_fallback_to_bufdir` (default: `true`)

Fallback zu Buffer-Directory wenn kein Project-Root gefunden.

```lua
project_root_fallback_to_bufdir = true  -- ✅ Standard

-- Kein Fallback (skipped wenn kein Root):
project_root_fallback_to_bufdir = false
```

---

## API

### `setup(config)`

Initialisiert cwd_sync mit gegebener Config.

**Beispiel:**
```lua
local cwd_sync = require("config.neotree.cwd_sync")

cwd_sync.setup({
  debounce_ms = 200,
  keep_focus = true,
  use_project_root = true,
})
```

**Einmalig aufrufen**, typischerweise in `plugins/neotree.lua` config.

---

### `pause_sync(ms)`

Pausiert Auto-Sync für angegebene Millisekunden. Nützlich für manuelle Navigation.

**Parameter:**
```lua
---@param ms integer  -- Millisekunden zum Pausieren
```

**Beispiel:**
```lua
local cwd_sync = require("config.neotree.cwd_sync")

-- User öffnet Neo-tree manuell
cwd_sync.pause_sync(2000)  -- Pause 2 Sekunden

-- User navigiert mit updir
cwd_sync.pause_sync(3000)  -- Pause 3 Sekunden
```

**Use-Cases:**
- Nach manuellem Neo-tree Öffnen
- Nach `updir` Navigation
- Nach Custom-Navigation Commands
- Bei Drag & Drop Operations

---

## Interne Logik

### State Management

```lua
local S = {
  timer = nil,              -- Debounce-Timer
  pending = false,          -- (Legacy, nicht mehr genutzt)
  last_dir = nil,           -- Letztes synchronized Verzeichnis
  last_file = nil,          -- Letzte synchronized Datei
  user_navigated = false,   -- Flag: User hat manuell navigiert
  last_user_action = 0,     -- Timestamp der letzten User-Action
  pause_until = 0,          -- Timestamp bis wann pausiert
  sync_scheduled = false,   -- Race-Condition Guard
}
```

---

### Sync-Trigger

Auto-Sync wird getriggert bei:
- `BufEnter` - Buffer-Wechsel
- `WinEnter` - Window-Wechsel

**Nicht getriggert bei:**
- `TabEnter` (entfernt um Performance zu verbessern)
- Special-Buffers (Terminal, Help, etc.)
- Während `pause_until` aktiv ist

---

### Duplikats-Prevention

```lua
-- Check ob bereits synchronized
if S.last_dir == dir and S.last_file == path then
  return  -- Skip, bereits aktuell
end
```

Prüft **beide** Verzeichnis UND Datei um unnötige Refreshes zu vermeiden.

---

### Race-Condition Prevention

```lua
local function schedule_sync(cfg)
  if S.sync_scheduled then
    return  -- ✅ Verhindert doppelte Scheduling
  end
  S.sync_scheduled = true

  -- Timer-Code...

  vim.schedule(function()
    S.sync_scheduled = false  -- ✅ Reset nach Ausführung
    sync_now(cfg)
  end)
end
```

---

### User-Navigation Detection

```lua
-- Nach pause_sync() Aufruf:
S.pause_until = vim.loop.now() + ms
S.user_navigated = true

-- In schedule_sync():
if vim.loop.now() < S.pause_until then
  return  -- ✅ Respektiert Pause
end

-- Auto-Reset nach 2 Sekunden:
if S.user_navigated and time_since_action > 2000 then
  S.user_navigated = false
end
```

---

## Integration mit anderen Modulen

### reveal_manager.lua

`cwd_sync` sollte **nicht** `reveal_manager` aufrufen (Zirkelbezug). Implementiert eigene Reveal-Logik:

```lua
local ok = pcall(function()
  cmd.execute({
    action = "show",
    source = "filesystem",
    position = "left",
    dir = dir,
    reveal = true,
    reveal_file = path,  -- ✅ Wichtig!
  })
end)
```

---

### open/init.lua

Opener pausieren cwd_sync um Konflikte zu vermeiden:

```lua
local function make_neotree_opener(position)
  return function()
    -- ... reveal code ...

    local cwd_sync = require("config.neotree.cwd_sync")
    cwd_sync.pause_sync(2000)  -- ✅ Verhindert sofortigen Re-Sync
  end
end
```

---

### updir.lua

Nach `updir` wird cwd_sync pausiert:

```lua
function M.up_one_level(state)
  local cwd_sync = require("config.neotree.cwd_sync")
  cwd_sync.pause_sync(3000)  -- ✅ Längere Pause

  -- ... updir logic ...
end
```

---

## Buffer-Validierung

Nutzt `utils.is_valid_file_buffer()` für robuste Checks:

```lua
local function is_real_file_buffer(buf)
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  return utils.is_valid_file_buffer(buf)
end
```

**Validierungen:**
- ✅ Buffer ist valid und geladen
- ✅ Kein Special-Buftype
- ✅ Datei existiert und ist lesbar
- ✅ Nicht leer (`[No Name]`)

---

## Performance-Charakteristiken

| Metrik | Wert | Notizen |
|--------|------|---------|
| Debounce | 150ms default | Konfigurierbar |
| Memory | ~8 Variablen | Minimaler Footprint |
| CPU | Sehr niedrig | Nur bei Buffer-Wechsel |
| Race-Conditions | Keine | Durch Guard gelöst |

**Optimierungen:**
- Duplikats-Prevention (skip wenn gleiche Datei)
- Sync-Scheduled Guard (keine doppelten Timer)
- Lazy Timer-Creation (nur wenn nötig)

---

## Troubleshooting

### Problem: Sync triggert zu oft

**Diagnose:**
```lua
-- Füge Debug-Logging hinzu
local function sync_now(cfg)
  print("Sync triggered:", dir, path)
  -- ...
end
```

**Lösung:**
- Erhöhe `debounce_ms` (z.B. 300)
- Check ob mehrere Autocmds triggern
- Prüfe `last_dir` / `last_file` Prevention

---

### Problem: Sync funktioniert nicht

**Diagnose:**
```lua
-- Check State
print(vim.inspect(S))

-- Check Config
print(vim.inspect(cfg))

-- Check Buffer
local ctx = utils.get_buffer_context()
print(vim.inspect(ctx))
```

**Lösung:**
- Stelle sicher Buffer ist valid (siehe Buffer-Validierung)
- Check ob `pause_until` aktiv ist
- Prüfe ob Neo-tree geladen ist
- Verify `open_if_closed` setting

---

### Problem: Position wird falsch

**Diagnose:**
```lua
-- Check current position
local pos = utils.get_current_position()
print("Current Neo-tree position:", pos)
```

**Lösung:**
- `cwd_sync` nutzt immer `position = "left"`
- Für andere Positionen nutze `open/init.lua` Opener
- Nach manuellem Öffnen nutze `pause_sync()`

---

### Problem: Focus springt zu Neo-tree

**Lösung:**
```lua
-- Setze keep_focus auf true
setup({
  keep_focus = true,  -- ✅
})
```

---

### Problem: Globales CWD wird geändert

**Lösung:**
```lua
-- Setze also_set_nvim_cwd auf false
setup({
  also_set_nvim_cwd = false,  -- ✅
})
```

---

## Best Practices

### ✅ DO

```lua
-- Standard-Config für meiste Use-Cases
cwd_sync.setup({
  debounce_ms = 150,
  keep_focus = true,
  also_set_nvim_cwd = false,
  use_project_root = true,
})

-- Pause nach manueller Navigation
cwd_sync.pause_sync(2000)

-- Erhöhe debounce für große Repos
cwd_sync.setup({ debounce_ms = 300 })
```

---

### ❌ DON'T

```lua
-- NICHT: Zu niedriges Debouncing
setup({ debounce_ms = 10 })  -- ❌ Performance-Hit

-- NICHT: Mehrfach setup() aufrufen
cwd_sync.setup({...})
cwd_sync.setup({...})  -- ❌ Erstellt doppelte Autocmds

-- NICHT: Gleichzeitig mit reveal_manager
reveal_mgr.reveal_buffer()
-- cwd_sync überschreibt sofort!  -- ❌

-- NICHT: also_set_nvim_cwd ohne Grund
setup({ also_set_nvim_cwd = true })  -- ⚠️ Side-Effects
```

---

## Advanced Usage

### Custom Project Root Detection

```lua
-- In config.neotree.actions.project_root oder ähnlichem Modul
local function get_project_root(buf)
  -- Custom Logic
  local markers = { ".git", "package.json", "Cargo.toml" }
  -- ... find root ...
  return root_path
end

-- cwd_sync nutzt automatisch diese Funktion
```

---

### Conditional Sync

```lua
-- Nur für bestimmte Filetypes syncen
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.lua", "*.py", "*.js" },
  callback = function()
    -- trigger sync manually
  end,
})
```

---

### Sync mit Custom Events

```lua
-- Trigger Sync bei Custom-Event
vim.api.nvim_create_autocmd("User", {
  pattern = "MyCustomEvent",
  callback = function()
    local cwd_sync = require("config.neotree.cwd_sync")
    -- Force immediate sync
    cwd_sync.pause_sync(0)  -- Remove pause
    -- Trigger BufEnter to sync
    vim.cmd("doautocmd BufEnter")
  end,
})
```

---

## Testing

```lua
describe("cwd_sync", function()
  local cwd_sync = require("config.neotree.cwd_sync")

  before_each(function()
    cwd_sync.setup({
      debounce_ms = 10,  -- Fast für Tests
      open_if_closed = false,
    })
  end)

  it("pauses sync correctly", function()
    cwd_sync.pause_sync(1000)

    -- Should be paused
    assert.is_true(vim.loop.now() < S.pause_until)

    -- Wait
    vim.wait(1100)

    -- Should be unpaused
    assert.is_true(vim.loop.now() >= S.pause_until)
  end)

  it("prevents duplicate syncs", function()
    local count = 0

    -- Mock sync_now
    local old_sync = sync_now
    sync_now = function()
      count = count + 1
    end

    -- Trigger twice
    schedule_sync(cfg)
    schedule_sync(cfg)

    vim.wait(50)

    assert.equals(1, count)  -- Only once due to guard

    sync_now = old_sync
  end)
end)
```

---

## Dependencies

```lua
require("config.neotree.utils")         -- Buffer-Validierung
require("neo-tree.command")             -- Neo-tree API
require("config.neotree.actions.project_root")        -- Optional: Project-Root detection
```

---

