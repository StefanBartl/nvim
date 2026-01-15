# config.neotree.open

Vereinheitlichtes Opener-Modul für Neo-tree mit mehreren Sub-Modulen.

---

## Inhaltsverzeichnis

- [Übersicht](#übersicht)
- [Sub-Module](#sub-module)
  - [window/](#window)
  - [system_app/](#system_app)
  - [filemanager/](#filemanager)
  - [reveal/](#reveal)
- [Verwendung](#verwendung)
  - [Window Opener](#window-opener)
  - [System App](#system-app)
  - [File Manager](#file-manager)
  - [Reveal Controller](#reveal-controller)
- [Integration](#integration)
- [Architektur](#architektur)
- [Konfiguration](#konfiguration)
- [Troubleshooting](#troubleshooting)
- [Performance](#performance)
- [Siehe auch](#siehe-auch)

---

## Übersicht

Das `config.neotree.open`-Modul bündelt verschiedene Mechanismen zum Öffnen von Dateien und Verzeichnissen:

- **Window Opener**: Öffnet Neo-tree in verschiedenen Positionen (left/right/float/current)
- **System App Opener**: Öffnet Dateien mit der Standard-Anwendung des Systems
- **File Manager Opener**: Öffnet Dateien im Dateimanager (Explorer, Finder, Nautilus, etc.)
- **Reveal Controller**: Zeigt die aktuelle Datei im Neo-tree an

---

## Sub-Module

### window/

Verwaltet Keymaps zum Öffnen von Neo-tree in verschiedenen Fenster-Positionen.

**Hauptdatei:** `window/controller.lua`

**API:**
```lua
require("config.neotree.open.window").attach_opener_mappings(opts)
```

**Keymaps:**
- `<M-l>` → Open/Toggle Left
- `<M-r>` → Open/Toggle Right
- `<M-f>` → Open/Toggle Float
- `<M-c>` → Open/Toggle Current Window
- `C` → Reveal aktuelle Datei (im Restore-Modus)

**Features:**
- ✅ Deterministische State Machine
- ✅ Busy Guard mit Auto-Release
- ✅ Spezielle Behandlung für `current`-Position
- ✅ Race-Condition-Safe
- ✅ Performance-Messungen (optional)

**Details:** Siehe [window/README.md](./window/README.md)

---

### system_app/

Öffnet Dateien/Verzeichnisse mit der Standard-Anwendung des Betriebssystems.

**Modul:** `lua/config/neotree/open/system_app/init.lua`

**API:**
```lua
local system_app = require("config.neotree.open.system_app")
system_app.open_from_neotree(state)
```

**Plattform-Support:**
- **Windows**: PowerShell `Start-Process` für Dateien, `explorer.exe` für Verzeichnisse
- **macOS**: `open`
- **Linux**: `xdg-open`

**Keymaps:**
```lua
["sm"] = "Mit System-Anwendung öffnen"
```

**Fallback-Reihenfolge:**
1. `lazy.util.open` (LazyVim-Integration)
2. `vim.ui.open` (Neovim 0.10+)
3. Plattform-spezifischer Befehl

**Anwendungsbeispiele:**
- PDFs in Standard-PDF-Viewer öffnen
- Bilder in Bildbetrachtungsprogramm öffnen
- Videos in Media Player öffnen
- Textdateien in externem Editor öffnen

---

### filemanager/

Öffnet Dateien/Verzeichnisse im System-Dateimanager mit Fokus auf die Datei (Reveal/Select).

**Module:**
- `init.lua` - Dispatcher (wählt plattform-spezifisches Modul)
- `win.lua` - Windows Explorer
- `wsl.lua` - WSL → Windows Explorer
- `unix_ubuntu.lua` - Linux/macOS (DBus, Nautilus, Finder, etc.)

**API:**
```lua
local filemanager = require("config.neotree.open.filemanager")
filemanager.open_from_neotree(state)
```

**Keymaps:**
```lua
["L"] = "Im System-Dateimanager öffnen"
```

**Plattform-Erkennung:**
- Windows → `win.lua`
- WSL → `wsl.lua`
- Linux/macOS → `unix_ubuntu.lua`

**Features pro Plattform:**

#### Windows (`win.lua`)
- Verwendet `explorer.exe /select,<path>` für Dateien
- Öffnet Verzeichnisse direkt
- Fallback zu `cmd.exe /C start`
- Robuste Fehlerbehandlung

#### WSL (`wsl.lua`)
- Auto-Konvertierung: Linux-Pfad → Windows-Pfad via `wslpath`
- Backend-Auswahl: `explorer` (Standard) oder `wslview`
- Konfigurierbar:
  ```lua
  require("config.neotree.open.filemanager.wsl").setup({
    backend = "explorer", -- oder "wslview" oder "auto"
    silent = true,
  })
  ```

#### Linux/macOS (`unix_ubuntu.lua`)
- **macOS**: `open -R` für Reveal in Finder
- **Linux**:
  1. DBus `org.freedesktop.FileManager1.ShowItems` (Standard)
  2. Manager-spezifisch: Nautilus, Nemo, Dolphin, Thunar
  3. Fallback: `gio open` oder `xdg-open`

---

### reveal/

Explizite Reveal-Logik unabhängig vom Window-Lifecycle.

**Modul:** `lua/config/neotree/open/reveal/controller.lua`

**API:**
```lua
local reveal = require("config.neotree.open.reveal.controller")
reveal.reveal_current(NeoCmd)
```

**Verwendung:**
- Im Restore-Modus: Manuelle Anzeige der aktuellen Datei
- Programmatisch: Datei im Tree fokussieren
- Integration: Wird von Window-Opener im Reveal-Modus verwendet

---

## Verwendung

### Window Opener

```lua
-- In plugins/neotree.lua config:
config = function(_, opts)
  require("config.neotree").setup({
    restore_last_position = false,  -- false = Reveal-Modus
    window_debug = true,            -- Performance-Messungen
  })
end
```

**Betriebsmodi:**

| Modus | Verhalten | Anwendungsfall |
|-------|-----------|----------------|
| Reveal (Standard) | Zeigt immer aktuelle Datei | Navigation im Projekt |
| Restore | Erhält Tree-State | Arbeiten in bestimmtem Bereich |

### System App

```lua
-- In keymaps/filesystem.lua:
["sm"] = {
  function(state)
    require("config.neotree.open.system_app").open_from_neotree(state)
  end,
  desc = "Mit System-Anwendung öffnen",
}
```

**Beispiel-Workflows:**
1. PDF-Datei im Neo-tree markieren
2. `sm` drücken
3. Datei öffnet in Standard-PDF-Viewer

### File Manager

```lua
-- In keymaps/filesystem.lua:
["L"] = {
  function(state)
    require("config.neotree.open.filemanager").open_from_neotree(state)
  end,
  desc = "Im System-Dateimanager öffnen",
}
```

**Beispiel-Workflows:**
1. Datei im Neo-tree markieren
2. `L` drücken
3. Dateimanager öffnet mit Datei selektiert

### Reveal Controller

```lua
-- Programmatischer Aufruf:
local ok, NeoCmd = pcall(require, "neo-tree.command")
if ok then
  require("config.neotree.open.reveal.controller").reveal_current(NeoCmd)
end

-- Oder via Keymap (bereits in window/ integriert):
-- <C> → Reveal aktuelle Datei
```

---

## Integration

Alle Opener sind in `lua/config/neotree/keymaps/filesystem.lua` integriert:

```lua
-- Window-Opener (globale Mappings)
<M-l> → Toggle Neo-tree (left)
<M-r> → Toggle Neo-tree (right)
<M-f> → Toggle Neo-tree (float)
<M-c> → Toggle Neo-tree (current)

-- Innerhalb Neo-tree
["sm"] → Mit System-Anwendung öffnen
["L"]  → Im Dateimanager öffnen
["C"]  → Aktuelle Datei anzeigen (Reveal)
```

**Setup-Reihenfolge:**
1. `require("config.neotree").setup({ ... })` in `plugins/neotree.lua`
2. Window-Opener wird automatisch initialisiert
3. Keymaps werden registriert
4. Submodule (system_app, filemanager) sind lazy-loaded

---

## Architektur

```
open/
├── window/
│   ├── init.lua         → Public API (attach_opener_mappings)
│   ├── controller.lua   → Core-Logik (State Machine, Busy Guard)
│   ├── float.lua        → Float-Toggle-Handler
│   ├── measuring.lua    → Performance-Timer
│   └── README.md        → Window-Dokumentation
├── system_app/
│   ├── init.lua         → System-App-Opener
│   └── README.md        → System-App-Dokumentation
├── filemanager/
│   ├── init.lua         → Plattform-Dispatcher
│   ├── win.lua          → Windows Explorer
│   ├── wsl.lua          → WSL-Spezifisch
│   ├── unix_ubuntu.lua  → Linux/macOS
│   └── README.md        → Filemanager-Dokumentation
├── reveal/
│   └── controller.lua   → Explizite Reveal-Logik
└── README.md            → Diese Datei
```

**Abhängigkeiten:**
```
window/ → state/windows.lua, state/tree.lua, reveal/
system_app/ → config.neotree.utils.node
filemanager/ → config.neotree.utils.node, lib.is_wsl
reveal/ → (standalone)
```

---

## Konfiguration

### Globale Konfiguration

```lua
require("config.neotree").setup({
  -- Window-Opener
  restore_last_position = false,  -- true = Restore-Modus
  window_debug = true,            -- Performance-Messungen
  debug = true,                   -- Detaillierte Logs

  -- Andere Subsysteme
  trash = { ... },
  current_hl = { ... },
  cwd_sync = { ... },
})
```

### Busy Guard-Tuning

In `window/controller.lua`:

```lua
-- Standard: 50ms Timeout, 3 Retries
local BUSY_GUARD_TIMEOUT_MS = 50
local BUSY_GUARD_MAX_RETRIES = 3

-- Für langsame Systeme:
local BUSY_GUARD_TIMEOUT_MS = 100
local BUSY_GUARD_MAX_RETRIES = 5
```

### WSL-Filemanager-Konfiguration

```lua
require("config.neotree.open.filemanager.wsl").setup({
  backend = "explorer",  -- "explorer" | "wslview" | "auto"
  silent = true,         -- Benachrichtigungen unterdrücken
})
```

---

## Troubleshooting

### Window-Opener

| Problem | Lösung |
|---------|--------|
| Alle Mappings öffnen nur "left" | State-Update-Fix in controller.lua |
| Busy Guard bleibt gesperrt | Auto-Release nach 50ms + Force-Clear |
| Current-Position hängt | Längere Delays (50ms/100ms) implementiert |
| Race Conditions | State wird synchron aktualisiert |

Siehe [window/README.md](./window/README.md) für Details.

### System-App-Opener

| Problem | Lösung |
|---------|--------|
| Keine Reaktion | Prüfe, ob Standard-App registriert ist |
| Windows: Datei öffnet nicht | Fallback zu `cmd.exe /C start` |
| macOS: Permission denied | Prüfe Sicherheitseinstellungen |
| Linux: `xdg-open` fehlt | Installiere `xdg-utils` |

### Filemanager-Opener

| Problem | Lösung |
|---------|--------|
| Windows: Explorer öffnet nicht | Fallback zu `cmd.exe /C start` |
| WSL: Pfad-Konvertierung fehlgeschlagen | Prüfe `wslpath`-Installation |
| Linux: DBus-Fehler | Fallback zu manager-spezifisch |
| macOS: Finder zeigt falschen Ordner | Bug in macOS < 11, nutze neuere Version |

### Debug-Aktivierung

```lua
-- Globales Debug
require("config.neotree").setup({
  debug = true,
})

-- Nur Window-Debug
require("config.neotree").setup({
  window_debug = true,
})

-- Logs anzeigen:
:messages
:lua vim.print(require("config.neotree.state.windows").get_state())
```

---

## Performance

### Window-Opener Timings

| Aktion | Durchschnitt | First Open | Cached |
|--------|-------------|------------|--------|
| Open Left | ~20ms | ~150ms | ~15ms |
| Open Right | ~20ms | ~150ms | ~15ms |
| Open Float | ~25ms | ~180ms | ~20ms |
| Open Current | ~30ms | ~200ms | ~25ms |
| Close | ~10ms | - | - |
| Switch | ~60ms | - | - |

*Gemessen auf durchschnittlichem System, Projektgröße ~500 Dateien*

### Performance-Messungen aktivieren

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

**Beispiel-Ausgabe:**
```
Neo-tree Timing Statistics
----------------------------------------
Overall                          count=42 avg=23.5ms min=15.2ms max=156.3ms

First open (session)            count=4 avg=152.1ms
Reopen (session)                count=38 avg=18.7ms
First open (cwd)                count=8 avg=145.3ms
Reopen (cwd)                    count=34 avg=19.2ms

First open by project size:
  small                         count=2 avg=98.5ms
  medium                        count=4 avg=162.3ms
  large                         count=2 avg=201.7ms
```

---

## Siehe auch

- [window/README.md](./window/README.md) - Window-Opener-Dokumentation
- [filemanager/README.md](./filemanager/README.md) - Filemanager-Dokumentation
- [system_app/README.md](./system_app/README.md) - System-App-Dokumentation
- [../README.md](../README.md) - Übergeordnete Neo-tree-Konfiguration
- [../state/windows.lua](../state/windows.lua) - Window-State-Modul
- [../state/tree.lua](../state/tree.lua) - Tree-State-Modul

---

**Letzte Aktualisierung:** Januar 2026
**Version:** 2.0 (mit Busy Guard v2 und Current-Position-Fixes)
