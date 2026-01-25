# usrcmds.migrate

Modulares Framework für automatisierte Code-Migrationen in Neovim Lua-Projekten.

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Features](#features)
  - [notify Migration](#notify-migration)
  - [opt Migration](#opt-migration)
- [Konfiguration](#konfiguration)
  - [Setup API](#setup-api)
  - [Write-Strategie](#write-strategie)
- [Verwendung](#verwendung)
  - [notify Modul](#notify-modul)
  - [opt Modul](#opt-modul)
- [Architektur](#architektur)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Entwickler-Guide](#entwickler-guide)

---

## Überblick

`usrcmds.migrate` bietet wiederverwendbare Infrastruktur für Code-Transformationen mit:

- **Telescope-basierte UI** für interaktive Auswahl
- **Multi-Mode Support**: Zeile, Range, Buffer, CWD
- **Batch-Processing** mit Multi-Select
- **Auto-Write** mit sync/async Strategien
- **Modul-System** für erweiterbare Migrations-Typen

### Verfügbare Migrationen

| Modul | Beschreibung | Status |
|-------|-------------|--------|
| `notify` | `vim.notify` → `lib.notify` mit Alias-Support | ✅ Stable |
| `opt` | Deprecated Option-API → `nvim_get/set_option_value` | ✅ Stable |

---

## Installation

```lua
-- lazy.nvim
{
  dir = "~/.config/nvim/lua/usrcmds/migrate",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    -- Deine lib.notify Implementation
  },
  config = function()
    require("usrcmds.migrate").setup({
      notify = true,
      opt = true,
    })
  end,
}
```

---

## Quick Start

```lua
-- In init.lua oder plugin config
require("usrcmds.migrate").setup({
  notify = true,  -- Aktiviert :MigrateNotify
  opt = true,     -- Aktiviert :MigrateOpt
})

-- Oder alle Module aktivieren (Default)
require("usrcmds.migrate").enable_all()

-- Oder einzeln
require("usrcmds.migrate.notify").enable()
require("usrcmds.migrate.opt").enable()
```

**Erste Migration:**

```vim
:e lua/myplugin/core.lua
:MigrateNotify %
" Telescope öffnet sich → <Tab> für Multi-Select → <CR> zum Anwenden
```

---

## Features

### notify Migration

Migriert **alle** `vim.notify` Varianten zu `lib.notify`:

#### Unterstützte Patterns

**1. Direkte vim.notify Aufrufe:**
```lua
-- Vorher:
vim.notify("Operation successful", vim.log.levels.INFO)

-- Nachher:
notify.info("Operation successful")
```

**2. Aliased Aufrufe:**
```lua
-- Vorher:
local notify, levels = vim.notify, vim.log.levels
notify.error("Error occurred")

-- Nachher:
local notify = require("lib.notify").create("[module.path]")
notify.error("Error occurred")
```

**3. Existierende notify() Aufrufe:**
```lua
-- Vorher:
local notify = require("lib.notify").create("")
notify.warn("Task done")

-- Nachher:
notify.warn("Task done")
```

**4. Multiline-Calls:**
```lua
-- Vorher:
vim.notify(
  string.format("Processed %d items", count),
  vim.log.levels.INFO
)

-- Nachher:
notify.info(string.format("Processed %d items", count))
```

#### Module-Path Detection

**Automatisch (empfohlen):**
```vim
:MigrateNotify %
```
Erkennt automatisch Modul-Pfad aus Dateistruktur:
```lua
-- Datei: lua/telescope/extensions/myext/picker.lua
-- Generiert:
local notify = require("lib.notify").create("[telescope.extensions.myext.picker]")
```

**Manuell (explizit):**
```vim
:MigrateNotify % custom.module.name
```
Verwendet übergebenen Modul-Namen:
```lua
local notify = require("lib.notify").create("[custom.module.name]")
```

**Ohne Modul-Name:**
```vim
:MigrateNotify % ""
```
Generiert leeren String:
```lua
local notify = require("lib.notify").create("")
```

#### Alias Cleanup

Alte Aliases werden automatisch entfernt:

```lua
-- Vorher:
local notify, levels = vim.notify, vim.log.levels
local n = vim.notify

function M.test()
  notify("test", levels.INFO)
  n("debug", vim.log.levels.DEBUG)
end

-- Nachher:
local notify = require("lib.notify").create("[mymodule]")

function M.test()
  notify.info("test")
  notify.debug("debug")
end
```

### opt Migration

Migriert deprecated Option-APIs zu aktueller Syntax:

```lua
-- Vorher:
local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
vim.api.nvim_win_set_option(winid, "number", true)

-- Nachher:
local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
vim.api.nvim_set_option_value("number", true, { win = winid })
```

**Unterstützte APIs:**
- `nvim_buf_get_option()` → `nvim_get_option_value(..., { buf = ... })`
- `nvim_buf_set_option()` → `nvim_set_option_value(..., { buf = ... })`
- `nvim_win_get_option()` → `nvim_get_option_value(..., { win = ... })`
- `nvim_win_set_option()` → `nvim_set_option_value(..., { win = ... })`

---

## Konfiguration

### Setup API

```lua
---@class MigrateConfig
---@field opt boolean|nil Enable option API migration
---@field notify boolean|nil Enable notify migration

require("usrcmds.migrate").setup({
  opt = true,     -- :MigrateOpt Command
  notify = true,  -- :MigrateNotify Command
})
```

**Methoden:**

- `setup(config)` - Setup mit Konfiguration
- `enable_all()` - Aktiviert alle verfügbaren Module
- `disable_all()` - Deaktiviert alle Module (entfernt Commands)

### Write-Strategie

In `lua/usrcmds/migrate/notify/init.lua` kann die Write-Strategie konfiguriert werden:

```lua
-- File scope (Zeile ~11)
local WRITE_STRATEGY = "async"  -- "sync" | "async"
```

**Unterschiede:**

| Strategie | Beschreibung | Use Case |
|-----------|--------------|----------|
| `sync` | Blockierendes `vim.fn.writefile()` | Wenige Files (<5), Debugging |
| `async` | Non-blocking `vim.loop.fs_write()` | Viele Files, CWD-Scans |

**Performance:**

```lua
-- 10 Files, je 5 Matches
sync:  ~150ms total (blocking)
async: ~50ms write (non-blocking)

-- 50 Files CWD-Scan
sync:  ~800ms (UI freeze)
async: ~200ms (UI responsive)
```

**Hinweis:** Siehe [Troubleshooting](#bekanntes-problem-ui-freeze-während-migration) für aktuelle Limitierungen.

---

## Verwendung

### notify Modul

#### Syntax

```vim
:MigrateNotify [mode] [module_name]

" Modi:
"   (leer)  - Aktuelle Zeile
"   %       - Ganzer Buffer (mit Picker)
"   cwd     - Alle *.lua Files in CWD (mit Picker)
"
" module_name:
"   (leer)  - Auto-detect aus Dateipfad
"   "text"  - Expliziter Modul-Name
"   ""      - Leerer String (legacy)
```

#### Beispiele

**Einzelne Zeile:**
```vim
" Cursor auf Zeile mit vim.notify()
:MigrateNotify
" → Sofortige Migration, kein Picker
```

**Buffer mit Auto-Detect:**
```vim
:e lua/telescope/extensions/myext/init.lua
:MigrateNotify %
" → Picker öffnet
" → Modul-Path: telescope.extensions.myext.init
```

**Buffer mit Custom Name:**
```vim
:MigrateNotify % my.custom.module
" → Verwendet explizit: my.custom.module
```

**CWD-Scan:**
```vim
:cd lua/myplugin
:MigrateNotify cwd
" → Scannt rekursiv alle *.lua Files
" → Picker mit allen Matches
" → Auto-detect für jedes File separat
```

**CWD mit einheitlichem Namen:**
```vim
:MigrateNotify cwd myplugin.core
" → ALLE Files bekommen: myplugin.core
" → Achtung: Nicht empfohlen für große Projekte
```

**Visual Selection:**
```vim
" Visual Mode: Markiere Zeilen 10-20
:'<,'>MigrateNotify
" → Migriert nur markierten Bereich
```

#### Picker Keybindings

| Key | Aktion |
|-----|--------|
| `<CR>` | Anwenden ausgewählte(r) Match(es) |
| `<Tab>` | Multi-Select Toggle |
| `<S-A>` | **Batch-Apply**: Alle Matches sofort anwenden |
| `<C-c>` | Abbrechen |

### opt Modul

#### Syntax

```vim
:MigrateOpt [mode]

" Modi wie bei notify, aber ohne module_name
```

#### Beispiele

```vim
" Einzelne Zeile
:MigrateOpt

" Buffer
:MigrateOpt %

" CWD (mit ripgrep)
:MigrateOpt cwd
```

---

## Architektur

### Module-Struktur

```
lua/usrcmds/migrate/
├── init.lua                    # Unified setup entry point
├── @types/
│   └── init.lua               # Shared type definitions
├── common/                     # Shared infrastructure
│   ├── @types.lua             # Common types
│   ├── command.lua            # Command registration
│   ├── picker.lua             # Telescope UI
│   └── buffer.lua             # Buffer operations
├── notify/                     # notify migration module
│   ├── init.lua               # Entry point + orchestration
│   ├── @types.lua             # Module types
│   ├── parser/                # Pattern detection
│   │   ├── init.lua           # Orchestrator
│   │   ├── aliases.lua        # Alias detection
│   │   ├── patterns.lua       # Pattern matching
│   │   ├── extractor.lua      # Call extraction
│   │   └── migrator.lua       # Transformation logic
│   ├── refactor/              # Application layer
│   │   ├── init.lua           # Re-exports
│   │   ├── import.lua         # Import injection
│   │   ├── cleanup.lua        # Alias removal
│   │   ├── apply.lua          # Match application
│   │   └── write.lua          # File I/O (sync/async)
│   └── docs/                  # Module documentation
└── opt/                        # opt migration module
    ├── init.lua
    └── doc/
```

### Datenfluss

```
User Command (:MigrateNotify % mymodule)
    ↓
[init.lua]
    ├─ Parse args (mode=%, module_name=mymodule)
    └─ Route to scan function
        ↓
[parser/]
    ├─ aliases.detect() - Find existing aliases
    ├─ patterns.is_*() - Match patterns
    ├─ extractor.extract_*() - Extract calls
    └─ migrator.migrate_*() - Generate replacements
        ↓
[picker.lua]
    └─ Show Telescope UI
        ↓
User selects matches
        ↓
[refactor/]
    ├─ import.inject() - Add/update import
    ├─ apply.apply_match() - Replace lines (DESCENDING order)
    ├─ cleanup.remove_aliases() - Remove old aliases
    └─ write.batch_write() - Write to disk (sync/async)
        ↓
Done
```

### Kritische Details

**1. Index-Konvertierung**
```lua
-- Parser gibt 1-based (Vim-Style) zurück
match.line = 5        -- Zeile 5
match.end_line = 7    -- bis Zeile 7 (inclusive)

-- nvim_buf_set_lines erwartet 0-based, exclusive end
local start_idx = match.line - 1    -- 4 (0-based)
local end_idx = match.end_line      -- 7 (0-based exclusive)

-- Ersetzt Buffer-Indices [4,5,6] = Vim-Zeilen [5,6,7]
```

**2. Descending Order Application**
```lua
-- WICHTIG: Von unten nach oben arbeiten
table.sort(matches, function(a, b)
  return a.extra.end_line > b.extra.end_line
end)

-- Vermeidet Offset-Korruption:
-- Zeile 10 replace → Zeile 5 bleibt gültig
-- Zeile 5 replace  → Zeile 10 wäre falsch!
```

**3. Import Offset Compensation**
```lua
-- NACH Import-Injection alle Matches adjustieren
if import_added then
  for _, match in ipairs(matches) do
    match.lnum = match.lnum + 2  -- Import + Leerzeile
    match.extra.end_line = match.extra.end_line + 2
  end
end
```

**4. Self-Migration Prevention**
```lua
-- Exclusion Pattern
local function should_exclude(filepath)
  return filepath:match("/usrcmds/migrate/") ~= nil
end
```

---

## Best Practices

### 1. Module-Naming Convention

```vim
" Plugin-Komponenten
:MigrateNotify % myplugin.ui
:MigrateNotify % myplugin.core

" Telescope Extensions
:MigrateNotify % telescope.extensions.myext

" Config Modules
:MigrateNotify % config.lsp.servers
```

### 2. Workflow für Projekte

```bash
# 1. Backup
git commit -am "backup before migration"

# 2. Test mit einem File
nvim lua/myplugin/core.lua
:MigrateNotify %
# Preview prüfen → <CR> anwenden

# 3. Verifizieren
:e lua/myplugin/core.lua
# Visuell prüfen

# 4. Ganzes Projekt
:cd lua/myplugin
:MigrateNotify cwd
# <S-A> für Batch-Apply

# 5. Final Check
:grep "vim\.notify\|vim\.log\.levels" lua/myplugin/**/*.lua
# Sollte leer sein

# 6. Tests
:! make test

# 7. Commit
git commit -am "chore: migrate to lib.notify"
```

### 3. CWD-Scans mit Vorsicht

**Problem:** Bei `cwd` wird derselbe Modul-Name für ALLE Files verwendet:

```vim
:MigrateNotify cwd myplugin
" → Alle Files bekommen: local notify = require("lib.notify").create("[myplugin]")
```

**Lösung:** Auto-detect bevorzugen (ohne Modul-Name):

```vim
:MigrateNotify cwd
" → Jedes File bekommt eigenen Path
" lua/plugin/core.lua     → [plugin.core]
" lua/plugin/ui/window.lua → [plugin.ui.window]
```

### 4. Iterative Migration

```vim
" Schritt 1: Core-Module
:e lua/myplugin/core.lua
:MigrateNotify %
:w

" Schritt 2: UI-Module
:e lua/myplugin/ui.lua
:MigrateNotify %
:w

" Schritt 3: Rest via CWD
:cd lua/myplugin
:MigrateNotify cwd
```

---

## Troubleshooting

### Problem: "No matches found"

**Ursachen:**
- File ist nicht `filetype=lua`
- Bereits migriert
- Ungewöhnliche Formatierung

**Lösung:**
```vim
:set filetype?  " Prüfe Filetype
:grep vim.notify %  " Manuelle Suche
```

### Problem: Aliases nicht erkannt

**Ursache:** Alias nicht in ersten 50 Zeilen

**Lösung:** Aliases an Dateianfang verschieben:
```lua
-- Am Dateianfang (vor Funktionen)
local notify, levels = vim.notify, vim.log.levels
```

### Problem: Falscher Modul-Name

**Ursache:** Tippfehler oder Auto-Detect fehlgeschlagen

**Lösung:**
```vim
u  " Undo
:MigrateNotify % correct.module.name  " Retry
```

### Problem: Doppelte Imports

**Ursache:** Import existierte bereits

**Lösung:**
```lua
-- Manuell altes Import löschen
-- local notify = require("lib.notify")  ← löschen

-- Dann erneut migrieren
:MigrateNotify %
```

### Bekanntes Problem: UI Freeze während Migration

**Symptom:** Cursor flackert, UI reagiert verzögert (~2-3 Sekunden)

**Ursache:** Buffer-Operationen laufen synchron im UI-Thread (siehe [Problem-Beschreibung](#1-problem-beschreibung))

**Workaround:** Wird in zukünftiger Version mit Chunked Processing behoben.

**Temporär:**
```lua
-- In notify/init.lua, Zeile ~11
local WRITE_STRATEGY = "sync"  -- Weniger Async-Overhead
```

### Problem: Pattern in Strings wird migriert

**Beispiel:**
```lua
local example = 'vim.notify("test", vim.log.levels.INFO)'
```

**Ursache:** Regex erkennt nicht, ob Code in String steht

**Lösung:** Manuell rückgängig machen:
```vim
u  " Undo migration
" Dann manuelle Anpassung
```

---

## Entwickler-Guide

### Neues Migrations-Modul erstellen

**1. Struktur anlegen:**
```
lua/usrcmds/migrate/mymodule/
├── init.lua         # Entry point
├── @types.lua       # Module types
├── parser.lua       # Pattern detection
└── refactor.lua     # Transformation
```

**2. Interface implementieren:**
```lua
-- mymodule/init.lua
local M = {}

function M.enable()
  require("usrcmds.migrate.common.command").register({
    name = "MigrateMyModule",
    scan_range = function(bufnr, line1, line2) end,
    scan_buffer = function(bufnr) end,
    scan_cwd = function() end,
    apply_matches = function(matches) end,
    show_picker = function(matches) end,
  })
end

return M
```

**3. In init.lua registrieren:**
```lua
-- migrate/init.lua
function M.setup(config)
  if config.mymodule then
    require("usrcmds.migrate.mymodule").enable()
  end
end
```

### Pattern-Matching Best Practices

Siehe `docs/PatternMatchingGuide.md` für:
- Regex vs Treesitter Trade-offs
- Lua Pattern Examples
- Multiline Detection
- Testing Strategies

### Testing

```lua
-- parser unit test
local parser = require("usrcmds.migrate.mymodule.parser")

local test_line = 'old_pattern("test", arg)'
local migrated = parser.migrate_line(test_line)

assert(migrated == 'new_pattern("test", arg)')
```

---

## Weitere Resourcen

- `docs/Technical-DeepDive.md` - Implementierungs-Details
- `docs/PatternMatchingGuide.md` - Pattern-Design
- `docs/USAGE-EXAMPLES.md` - Erweiterte Beispiele
- `notify/doc/migrate-notify.txt` - Vollständige notify Doku
- `opt/doc/migrate-opt.txt` - Vollständige opt Doku

---

