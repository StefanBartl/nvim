# Neo-tree Trash System

Ein umfassendes, plattformübergreifendes Löschsystem für Neo-tree mit erweiterten Sicherheitsfunktionen.

## Table of content

- [Neo-tree Trash System](#neo-tree-trash-system)
  - [Features](#features)
    - [✅ Kern-Funktionalität](#kern-funktionalitt)
    - [🛡️ Sicherheitsschichten](#sicherheitsschichten)
  - [Installation](#installation)
    - [1. Module einbinden](#1-module-einbinden)
    - [2. Keymaps](#2-keymaps)
  - [Verwendung](#verwendung)
    - [Einzelne Datei löschen](#einzelne-datei-lschen)
    - [Mehrere Dateien löschen (Batch)](#mehrere-dateien-lschen-batch)
    - [Wenn Buffers offen sind](#wenn-buffers-offen-sind)
    - [Rückgängig machen](#rckgngig-machen)
  - [User Commands](#user-commands)
    - [`:NeoTreeTrashStats`](#neotreetrashstats)
    - [`:NeoTreeTrashDebug`](#neotreetrashdebug)
    - [`:NeoTreeTrashDryRun`](#neotreetrashdryrun)
  - [Konfiguration](#konfiguration)
    - [Alle Optionen](#alle-optionen)
    - [Empfohlene Einstellungen](#empfohlene-einstellungen)
  - [Architektur](#architektur)
    - [Module-Struktur](#module-struktur)
    - [Ablauf](#ablauf)
  - [Troubleshooting](#troubleshooting)
    - [Problem: "Operation denied: paths are open in buffers"](#problem-operation-denied-paths-are-open-in-buffers)
    - [Problem: Preview wird nicht geschlossen](#problem-preview-wird-nicht-geschlossen)
    - [Problem: Buffers werden nicht geschlossen](#problem-buffers-werden-nicht-geschlossen)
  - [Bekannte Limitationen](#bekannte-limitationen)
  - [Best Practices](#best-practices)
  - [Entwicklung](#entwicklung)
    - [Tests](#tests)
    - [Debug](#debug)
  - [Changelog](#changelog)
    - [v2.0.0 (Current)](#v200-current)
    - [v1.0.0](#v100)
  - [Support](#support)

---

## Features

### ✅ Kern-Funktionalität
- **Cross-Platform Support**: Windows RecycleBin, Linux/macOS Trash
- **Smart Batch Operations**: Mehrere Dateien auf einmal löschen
- **Intelligente Buffer-Erkennung**: Findet und schließt offene Buffers/Previews
- **Undo/Restore**: Gelöschte Dateien wiederherstellen
- **Automatic Backups**: Backups vor dem Löschen

### 🛡️ Sicherheitsschichten
1. **Buffer/Preview Detection** - Verhindert Löschen offener Dateien
2. **Path Validation** - Schützt System-Verzeichnisse
3. **Batch Confirmation** - Intelligente Bestätigung mit Optionen
4. **Automatic Backups** - Automatische Sicherungskopien
5. **Watcher Quarantine** - Verhindert EPERM-Fehler
6. **Recovery Points** - Wiederherstellung bei Fehlern

## Installation

### 1. Module einbinden

In `config/neotree/init.lua`:

```lua
-- Trash system
local trash = require("config.neotree.trash")
trash.setup({
  debug = false,              -- Detailliertes Feedback
  auto_close_buffers = false, -- Automatisch schließen ohne Frage
  create_backups = true,      -- Backups erstellen
  use_safety_system = true,   -- Alle Sicherheitsfunktionen
})

-- User Commands registrieren
require("config.neotree.trash.commands").setup()
```

### 2. Keymaps

In `config/neotree/keymaps/filesystem.lua`:

```lua
local trash = require("config.neotree.trash")
local undo = require("config.neotree.undo")

["d"] = {
  function(state)
    trash.neotree_send_node_to_trash(state)
  end,
  desc = "Delete to Trash",
},

["U"] = {
  function(state)
    undo.neotree_undo_trash(state)
  end,
  desc = "Undo last trash",
},

["<leader>th"] = {
  function(_)
    undo.show_history()
  end,
  desc = "Show trash history",
},
```

## Verwendung

### Einzelne Datei löschen

1. Cursor auf Datei/Ordner bewegen
2. `d` drücken
3. Bestätigen mit `y`

### Mehrere Dateien löschen (Batch)

1. Dateien markieren:
   - `m` - Node markieren
   - `<C-m>` - Alle Marks löschen
2. `d` drücken
3. Modus wählen:
   - `[a]` - Alle auf einmal löschen
   - `[i]` - Einzeln bestätigen
   - `[c]` - Abbrechen

### Wenn Buffers offen sind

Das System erkennt automatisch offene Buffers/Previews:

```
📄 File 'init.lua' is open in 2 buffers:
   [3] init.lua
   [5] init.lua
🔍 Preview: active

Close and continue? (y/N)
```

**Optionen:**
- `y` - Schließen und löschen
- `N` - Abbrechen

### Rückgängig machen

```vim
:NeoTreeUndo
" oder
U  " in Neo-tree
```

## User Commands

### `:NeoTreeTrashStats`
Zeigt Statistiken:
```
=== Neo-tree Trash Statistics ===

Safety System: ✓
Debug Mode: ✗
Auto-Close Buffers: NO
Backups: 12
Recovery Points: 3
Queue: IDLE
Dry-Run: ✗
```

### `:NeoTreeTrashDebug`
Schaltet Debug-Modus um:
```
Debug mode: ENABLED
```

Im Debug-Modus:
```
⚠ File 'test.lua' has open references
🔄 Closing references...
✓ Closed buffer 3: test.lua
✓ Closed preview
✓ Deleted: test.lua
```

### `:NeoTreeTrashDryRun`
Test-Modus (keine echten Änderungen):
```
[DRY-RUN] Would trash 3 items
```

## Konfiguration

### Alle Optionen

```lua
trash.setup({
  -- Sicherheitssystem
  use_safety_system = true,  -- Master-Schalter für alle Features

  -- Backups
  create_backups = true,      -- Automatische Backups

  -- Buffer-Handling
  auto_close_buffers = false, -- true = schließt ohne Frage

  -- Debug & Testing
  debug = false,              -- Detailliertes Feedback
  use_dry_run = true,         -- Dry-Run erlauben

  -- Legacy (deprecated)
  confirm_dangerous = true,   -- Wird durch batch confirmation ersetzt
})
```

### Empfohlene Einstellungen

**Für Entwickler (vorsichtig):**
```lua
trash.setup({
  debug = true,
  auto_close_buffers = false, -- Immer fragen
  create_backups = true,
})
```

**Für Power-User (schnell):**
```lua
trash.setup({
  debug = false,
  auto_close_buffers = true,  -- Automatisch schließen
  create_backups = true,
})
```

## Architektur

### Module-Struktur

```
trash/
├── init.lua                    - Orchestrator (150 Zeilen)
├── commands.lua                - User Commands
├── README.md                   - Diese Datei
├── platform/
│   └── init.lua               - Cross-platform trash
├── validation/
│   └── buffer_checker.lua     - Buffer/Preview detection
├── confirmation/
│   └── init.lua               - User confirmation
└── operations/
    └── init.lua               - Execute operations
```

### Ablauf

```
1. User drückt 'd'
   ↓
2. Get nodes (marked or current)
   ↓
3. Check & close buffers/previews ← NEU: VOR Validation
   ↓
4. Validation (path safety)
   ↓
5. Batch confirmation
   ↓
6. Create backups
   ↓
7. Execute trash
   ↓
8. Refresh Neo-tree
```

## Troubleshooting

### Problem: "Operation denied: paths are open in buffers"

**Alte Version**: Fehler, auch wenn Preview geschlossen
**Neue Version**: Buffer-Check NACH Preview-Schließung

**Lösung**: Update auf neueste Version

### Problem: Preview wird nicht geschlossen

**Debug aktivieren:**
```vim
:NeoTreeTrashDebug
```

Dann erneut versuchen. Output zeigt Details:
```
⚠ File 'test.lua' has open references
🔍 Preview: Preview Window (Win 1002)
🔄 Closing references...
✓ Closed preview via hide()
✓ Closed float window 1002
```

### Problem: Buffers werden nicht geschlossen

**Manuelles Schließen:**
```vim
:bufdo bd!  " Alle Buffers schließen
```

Oder in Config:
```lua
auto_close_buffers = true
```

## Bekannte Limitationen

1. **Windows**: Sehr große Ordner können langsam sein
2. **macOS**: Erfordert `osascript` oder `trash` Command
3. **Linux**: Funktioniert am besten mit `gio` oder `trash-cli`

## Best Practices

1. **Immer Backups aktiviert lassen**
   ```lua
   create_backups = true
   ```

2. **Debug-Modus bei Problemen**
   ```vim
   :NeoTreeTrashDebug
   ```

3. **Dry-Run für Tests**
   ```vim
   :NeoTreeTrashDryRun
   ```

4. **Regelmäßig Trash History prüfen**
   ```vim
   :lua require("config.neotree.undo").show_history()
   ```

## Entwicklung

### Tests

```lua
-- Dry-run aktivieren
:NeoTreeTrashDryRun

-- Datei markieren und löschen
d
a  -- Delete all

-- Output: [DRY-RUN] Would trash 1 items
```

### Debug

```lua
-- Debug aktivieren
:NeoTreeTrashDebug

-- Ausführliche Logs im Notify
```

## Changelog

### v2.0.0 (Current)
- ✅ Modularisierung (840 → 6 × ~150 Zeilen)
- ✅ Buffer-Check VOR Validation (Fix)
- ✅ Preview-Window robust schließen
- ✅ User Commands hinzugefügt
- ✅ Deutsche README

### v1.0.0
- Initial release

## Support

Bei Problemen:
1. Debug-Modus aktivieren
2. Output kopieren
3. Issue erstellen mit Log

---
