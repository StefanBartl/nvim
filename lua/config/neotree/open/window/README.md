# Neo-tree Window Controller

Deterministisches Window-Lifecycle-Management für Neo-tree mit State-Wiederherstellung.

## Inhaltsverzeichnis

- [Features](#features)
- [Betriebsmodi](#betriebsmodi)
  - [Reveal-Modus (Standard)](#reveal-modus-standard)
  - [Restore-Modus](#restore-modus)
- [Design-Prinzipien](#design-prinzipien)
  - [Single Source of Truth](#single-source-of-truth)
  - [Deterministische State Machine](#deterministische-state-machine)
  - [Keine Toggle-Logik](#keine-toggle-logik)
  - [Busy Guard](#busy-guard)
- [API](#api)
  - [Controller](#controller)
  - [State-Module](#state-module)
- [Mappings](#mappings)
- [Integration](#integration)
- [Troubleshooting](#troubleshooting)
- [Health Checks](#health-checks)
- [Architektur](#architektur)
- [Erweiterte Features](#erweiterte-features)

---

## Features

- ✅ Einheitliches Verhalten für alle Positionen (left/right/float/current)
- ✅ Zwei Betriebsmodi: Reveal oder Restore
- ✅ Deterministische Open/Close/Switch-Logik
- ✅ Keine Race Conditions mit float/current
- ✅ Spam-sichere Mappings mit Busy-Guard
- ✅ State-Persistenz über Sessions hinweg
- ✅ Automatische Lock-Freigabe bei Timeouts
- ✅ Spezielle Behandlung für `current`-Position

## Betriebsmodi

### Reveal-Modus (Standard)

Öffnet Neo-tree und zeigt die aktuelle Datei im Baum an.

```lua
require("config.neotree").setup({
  restore_last_position = false,
})
```

**Verhalten:**
- Öffnen → Aktuelle Datei anzeigen
- Schließen → Nichts speichern
- Erneut öffnen → Aktuelle Datei wieder anzeigen

**Anwendungsfall:** Man möchte immer sehen, wo die aktuelle Datei im Baum ist.

### Restore-Modus

Öffnet Neo-tree an der letzten Cursor-Position mit erhaltenen aufgeklappten Nodes.

```lua
require("config.neotree").setup({
  restore_last_position = true,
})
```

**Verhalten:**
- Öffnen → Letzten Tree-State wiederherstellen (Cursor + aufgeklappte Nodes)
- Schließen → Tree-State erfassen
- Erneut öffnen → Gespeicherten State wiederherstellen

**Anwendungsfall:** Arbeiten in einem bestimmten Bereich des Baums, Kontext soll nicht verloren gehen.

**Explizites Reveal-Mapping:**
```
C → Aktuelle Datei im Baum anzeigen (manuelles Reveal)
```

## Design-Prinzipien

### Single Source of Truth

Der gesamte Window-State wird in `state/windows.lua` verwaltet:

```lua
local state = {
  open = false,
  position = nil,
}
```

Kein State wird aus Neo-tree-Internals abgeleitet.

### Deterministische State Machine

```
closed
 └─→ open(target) → open(target)

open(target)
 ├─→ same target → close → closed
 └─→ other target → close → open(new) → open(new)
```

### Keine Toggle-Logik

Alle Übergänge sind explizit:
- `open()` öffnet
- `close()` schließt
- `switch()` schließt dann öffnet

Float ist die **einzige** Ausnahme (erfordert `toggle = true` by Design).

### Busy Guard

Verhindert Mapping-Spam während Übergängen:

```lua
-- Timeout-basierte Auto-Release
if busy_state.locked and busy_state.lock_time then
  local elapsed = now - busy_state.lock_time
  if elapsed > BUSY_GUARD_TIMEOUT_MS then
    -- Automatische Freigabe
    busy_state.locked = false
  end
end

-- Safety Valve: Force-Clear nach zu vielen Retries
if busy_state.retry_count > BUSY_GUARD_MAX_RETRIES then
  busy_state.locked = false
  return true
end
```

**Features:**
- ⏱️ Automatische Freigabe nach 50ms
- 🔄 Retry-Counter mit Safety Valve
- 🛡️ Schutz vor permanentem Lock
- 🐛 Debug-Ausgaben für Troubleshooting

## API

### Controller

```lua
local controller = require("config.neotree.open.window.controller")

-- Opener für Position erstellen
local opener = controller.make_opener("left")

-- Ausführen
opener()

-- State abfragen
local state = controller.get_state()
-- { open = true, position = "left" }

-- Busy Guard manuell zurücksetzen (Recovery)
controller.clear_busy_guard()
```

### State-Module

#### Window State

```lua
local state = require("config.neotree.state.windows")

state.is_open()        -- boolean
state.get_position()   -- "left"|"right"|"float"|"current"|nil
state.set_open("left", "reveal")
state.set_closed("explicit_close")
```

#### Tree State

```lua
local tree_state = require("config.neotree.state.tree")

-- Von neo-tree State-Objekt erfassen
tree_state.capture_state(neo_state)

-- Zu neo-tree Tree-Objekt wiederherstellen
tree_state.restore_state(tree)

-- Manuelle Verwaltung
tree_state.set_node("node_id")
tree_state.set_expanded({ ["id1"] = true })
tree_state.reset()
```

## Mappings

### Standard-Keymaps

```lua
<M-l> → Toggle left
<M-r> → Toggle right
<M-f> → Toggle float
<M-c> → Toggle current

C → Aktuelle Datei anzeigen (nur im Restore-Modus relevant)
```

### Custom Mappings

```lua
require("config.neotree.open.window").attach_opener_mappings({
  debug = false,
})

-- Oder manuell:
local controller = require("config.neotree.open.window.controller")
vim.keymap.set("n", "<leader>nl", controller.make_opener("left"))
```

## Integration

### plugins/neotree.lua

```lua
config = function(_, opts)
  require("config.neotree").setup({
    restore_last_position = true,
    window_debug = true,  -- Performance-Messungen
    debug = false,        -- Debug-Ausgaben
  })
end
```

### Performance-Messungen

Timing-Wrapper aktivieren:

```lua
require("config.neotree").setup({
  window_debug = true,
})
```

**User Commands:**
```vim
:NeoTreeTimings           " Session-Statistiken
:NeoTreeTimingsPersistent " All-Time-Statistiken
:NeoTreeTimingsClear      " Daten zurücksetzen
```

## Troubleshooting

### Float schließt sich sofort

**Ursache:** Race Condition in Neo-tree's Float-Implementierung

**Lösung:** Bekanntes Neo-tree-Problem. Float verwendet intern `toggle=true`, Timing kann unvorhersehbar sein. Warte auf Neo-tree-Fix oder verwende left/right-Positionen.

### Current-Window schließt nicht mit `:bc`

**Ursache:** `current` verwendet existierenden Buffer, `bd` schließt ihn nicht

**Lösung:** Mapping erneut verwenden zum Schließen, oder Force-Close:
```vim
:bd! %
```

### M-r funktioniert nicht

**Ursache:** WezTerm leitet Alt-r nicht weiter

**Debug:**
```vim
:lua print(vim.fn.getcharstr())
" Drücke M-r und sieh ob etwas erscheint
```

**Lösung:** WezTerm-Config prüfen, alternatives Mapping verwenden:
```lua
vim.keymap.set("n", "<leader>nr", controller.make_opener("right"))
```

### State wird nicht wiederhergestellt

**Konfiguration prüfen:**
```vim
:lua vim.print(require("config.neotree").options.restore_last_position)
```

**State-Capture verifizieren:**
```vim
:lua vim.print(require("config.neotree.state.tree").get_node())
:lua vim.print(require("config.neotree.state.tree").get_expanded())
```

### "Invalid 'window': Expected Lua number"

**Ursache:** Neo-tree versucht auf ungültiges Window-Handle zuzugreifen

**Lösung:**
- Stelle sicher, dass `debug = true` aktiviert ist
- Prüfe Logs auf Race Conditions
- Bei Switches zu/von `current` werden jetzt längere Delays verwendet (100ms statt 40ms)
- Falls weiterhin Probleme: Busy Guard manuell zurücksetzen:
  ```vim
  :lua require("config.neotree.open.window.controller").clear_busy_guard()
  ```

### Busy Guard bleibt gesperrt

**Ursache:** Sollte nicht mehr vorkommen durch Auto-Release

**Lösung:**
```vim
:lua require("config.neotree.open.window.controller").clear_busy_guard()
```

**Prevention:**
- Timeout-basierte Auto-Release nach 50ms
- Safety Valve nach 3 Retries
- Falls weiterhin Probleme: `BUSY_GUARD_TIMEOUT_MS` in `controller.lua` erhöhen

## Health Checks

```vim
:NeoTreeCheckHealth
```

Prüft:
- Modul-Loading
- State-Initialisierung
- Konfigurations-Validität
- Aktuelle State-Werte
- Busy Guard-Status

## Architektur

```
window/
├── init.lua         → Public API (attach_opener_mappings)
├── controller.lua   → Core-Logik (make_opener, State Machine)
├── float.lua        → Float-spezifischer Toggle-Handler
├── measuring.lua    → Performance-Timing-Wrapper
└── README.md        → Diese Datei

state/
├── windows.lua      → Window-Lifecycle-State
└── tree.lua         → Tree-Position/Expansion-State

reveal/
└── controller.lua   → Explizite Reveal-Logik
```

## Erweiterte Features

### Event Listeners

```lua
local state = require("config.neotree.state.windows")

state.on_transition(function(from, to, action)
  print(string.format("%s -> %s (%s)", from.position, to.position, action))
end)
```

### Debug-Modus

```lua
local state = require("config.neotree.state.windows")
state.enable_debug(true)

-- Transitionen inspizieren
local snapshots = state.get_snapshots()
```

### State zurücksetzen

```lua
local state = require("config.neotree.state.windows")
local tree_state = require("config.neotree.state.tree")

state.reset()
tree_state.reset()
```

### Busy Guard-Konfiguration

In `controller.lua` anpassen:

```lua
-- Timeout-Konfiguration
local BUSY_GUARD_TIMEOUT_MS = 50  -- Millisekunden bis Auto-Release
local BUSY_GUARD_MAX_RETRIES = 3  -- Max Retries vor Force-Clear
```

**Anpassung für langsame Systeme:**
```lua
local BUSY_GUARD_TIMEOUT_MS = 100  -- Verdoppelt für langsame Systeme
```

## Spezielle Behandlung: Current-Position

Die `current`-Position erfordert besondere Aufmerksamkeit:

1. **Buffer-Wiederverwendung:** Neo-tree öffnet im aktuellen Buffer
2. **Längere Delays:** 50ms statt 10ms für Buffer-Setup
3. **Switch-Delays:** 100ms für Switches zu/von `current`
4. **Explizites Cleanup:** Buffer wird nach Close gelöscht

**Warum?**
- Buffer-Deletion braucht Zeit für Cleanup
- Neo-tree's State wird ungültig nach Buffer-Löschung
- Neue Buffer-Erstellung braucht Zeit für Setup

## Performance-Charakteristiken

| Position | Open (First) | Open (Cached) | Close | Switch |
|----------|--------------|---------------|-------|--------|
| left     | ~150ms       | ~20ms         | ~10ms | ~60ms  |
| right    | ~150ms       | ~20ms         | ~10ms | ~60ms  |
| float    | ~180ms       | ~25ms         | ~15ms | ~70ms  |
| current  | ~200ms       | ~30ms         | ~50ms | ~150ms |

*Messungen auf durchschnittlichem System, Projektgröße ~500 Dateien*

## Siehe auch

- [controller.lua](./controller.lua) - Core-Implementierung
- [state/windows.lua](../../state/windows.lua) - Window-State
- [state/tree.lua](../../state/tree.lua) - Tree-State
- [measuring.lua](./measuring.lua) - Performance-Timing
- [../README.md](../README.md) - Übergeordnetes Open-Modul

---

