# usrcmds.migrate

Modulares Framework für Code-Migrationen in Neovim Lua-Projekten.

## Table of content

- [usrcmds.migrate](#usrcmdsmigrate)
  - [Quick Start](#quick-start)
  - [Features](#features)
    - [notify Migration](#notify-migration)
    - [opt Migration](#opt-migration)
  - [Unified Setup API](#unified-setup-api)
  - [notify Module - Neue Features](#notify-module-neue-features)
    - [1. Alias-Detection](#1-alias-detection)
    - [2. Modul-Namen Support](#2-modul-namen-support)
    - [3. Alias Cleanup](#3-alias-cleanup)
  - [Architektur](#architektur)
    - [Module-Struktur](#module-struktur)
    - [Workflow](#workflow)
  - [Best Practices](#best-practices)
    - [1. Modul-Namen Konvention](#1-modul-namen-konvention)
    - [2. CWD Migration mit Vorsicht](#2-cwd-migration-mit-vorsicht)
    - [3. Überprüfung nach Migration](#3-berprfung-nach-migration)
  - [Debugging](#debugging)
    - [Enable Debug Output](#enable-debug-output)
    - [Test Alias Detection](#test-alias-detection)
    - [Check Import](#check-import)
  - [Migration Checklist](#migration-checklist)
  - [Troubleshooting](#troubleshooting)
    - [Problem: Aliases nicht erkannt](#problem-aliases-nicht-erkannt)
    - [Problem: Falscher Modul-Name](#problem-falscher-modul-name)
    - [Problem: Doppelte Imports](#problem-doppelte-imports)
    - [Problem: "No matches found"](#problem-no-matches-found)
  - [Weitere Resourcen](#weitere-resourcen)

---

## Quick Start

```lua
-- In deiner init.lua
require("usrcmds.migrate").setup({
  opt = true,     -- Enable :MigrateOpt
  notify = true,  -- Enable :MigrateNotify
})

-- Oder alle aktivieren (Default)
require("usrcmds.migrate").enable_all()

-- Oder einzeln
require("usrcmds.migrate.opt").enable()
require("usrcmds.migrate.notify").enable()
```

## Features

### notify Migration

Migriert **alle** `vim.notify` Varianten zu `lib.notify`:

**Direkte Aufrufe:**
```lua
-- Vorher:
vim.notify("Operation successful", vim.log.levels.INFO)

-- Nachher:
notify.info("Operation successful")
```

**Aliased Aufrufe (NEU):**
```lua
-- Vorher:
local notify, levels = vim.notify, vim.log.levels
notify("Error occurred", levels.ERROR)

-- Nachher:
local notify = require("lib.notify").create("")
notify.error("Error occurred")
```

**Mit Modul-Namen (NEU):**
```vim
:MigrateNotify % neotree.mark

" Generiert:
local notify = require("lib.notify").create("[neotree.mark]")
```

**Syntax:**
```vim
:MigrateNotify [mode] [module_name]

" Beispiele:
:MigrateNotify              " Aktuelle Zeile
:MigrateNotify %            " Buffer (mit Picker)
:MigrateNotify cwd          " CWD (mit Picker)
:MigrateNotify % mymodule   " Buffer + .create("[mymodule]")
:MigrateNotify cwd plugin.ui " CWD + .create("[plugin.ui]")
```

### opt Migration

Migriert deprecated Option APIs:

```lua
-- Vorher:
local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
vim.api.nvim_win_set_option(winid, "number", true)

-- Nachher:
local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
vim.api.nvim_set_option_value("number", true, { win = winid })
```

**Syntax:**
```vim
:MigrateOpt [mode]

" Beispiele:
:MigrateOpt       " Aktuelle Zeile
:MigrateOpt %     " Buffer (mit Picker)
:MigrateOpt cwd   " CWD (mit ripgrep)
```

## Unified Setup API

```lua
---@class MigrateConfig
---@field opt boolean|nil Enable option API migration
---@field notify boolean|nil Enable notify migration

require("usrcmds.migrate").setup({
  opt = true,
  notify = true,
})
```

**Methoden:**

- `setup(config)` - Setup mit Konfiguration
- `enable_all()` - Aktiviert alle Module
- `disable_all()` - Deaktiviert alle Module (entfernt Commands)

## notify Module - Neue Features

### 1. Alias-Detection

Das notify Modul erkennt jetzt automatisch Aliases am Anfang der Datei:

**Pattern 1:** Kombinierte Aliase
```lua
local notify, levels = vim.notify, vim.log.levels
notify("test", levels.INFO)
-- → notify.info("test")
```

**Pattern 2:** Einzelne Aliase
```lua
local n = vim.notify
n("test", vim.log.levels.WARN)
-- → notify.warn("test")
```

**Pattern 3:** Gemischte Verwendung
```lua
local notify = vim.notify
notify("test", vim.log.levels.ERROR)
-- → notify.error("test")
```

### 2. Modul-Namen Support

**Ohne Modul-Namen:**
```vim
:MigrateNotify %
```
Generiert:
```lua
local notify = require("lib.notify").create("")
```

**Mit Modul-Namen:**
```vim
:MigrateNotify % neotree.mark
```
Generiert:
```lua
local notify = require("lib.notify").create("[neotree.mark]")
```

**CWD mit Modul-Namen:**
```vim
:MigrateNotify cwd my.plugin.core
```
Generiert in allen Files:
```lua
local notify = require("lib.notify").create("[my.plugin.core]")
```

### 3. Alias Cleanup

Nach der Migration werden alte Aliases automatisch entfernt:

**Vorher:**
```lua
local notify, levels = vim.notify, vim.log.levels

local M = {}

function M.test()
  notify("test", levels.INFO)
end
```

**Nachher:**
```lua
local notify = require("lib.notify").create("")

local M = {}

function M.test()
  notify.info("test")
end
```

## Architektur

### Module-Struktur

```
lua/usrcmds/migrate/
├── init.lua              # Unified setup (NEU)
├── common/
│   ├── @types.lua
│   ├── command.lua       # Command handler
│   ├── picker.lua        # Telescope UI
│   └── buffer.lua        # Buffer operations
├── notify/
│   ├── @types.lua
│   ├── init.lua          # Entry point
│   ├── parser.lua        # Pattern detection (mit Alias-Support)
│   ├── refactor.lua      # Apply logic (mit Cleanup)
│   └── doc/
│       └── migrate-notify.txt
└── opt/
    ├── @types.lua
    ├── init.lua
    └── doc/
        └── migrate-opt.txt
```

### Workflow

```
User Command (:MigrateNotify % mymodule)
    ↓
init.lua: Parse args (mode=%, module_name=mymodule)
    ↓
parser.lua:
  - Detect aliases
  - Scan for vim.notify + aliased calls
  - Generate replacements
    ↓
picker.lua: Show Telescope UI
    ↓
User selects matches
    ↓
refactor.lua:
  - Inject import with module name
  - Apply replacements (descending order)
  - Remove old aliases
    ↓
Done
```

## Best Practices

### 1. Modul-Namen Konvention

Verwende beschreibende Modul-Namen:

```vim
" Plugin-Komponenten
:MigrateNotify % myplugin.ui
:MigrateNotify % myplugin.core
:MigrateNotify % myplugin.commands

" Nested Modules
:MigrateNotify % telescope.extensions.myext
:MigrateNotify % neovim.config.lsp
```

### 2. CWD Migration mit Vorsicht

Bei `cwd` wird **derselbe** Modul-Name für **alle** Files verwendet:

```vim
:MigrateNotify cwd myplugin

" Alle Files bekommen:
" local notify = require("lib.notify").create("[myplugin]")
```

Falls unterschiedliche Modul-Namen nötig sind → Buffer-Mode (`%`) für jedes File einzeln.

### 3. Überprüfung nach Migration

Nach Migration prüfen:

- [ ] Import korrekt eingefügt
- [ ] Alte Aliases entfernt
- [ ] Alle Calls migriert
- [ ] Keine doppelten Imports

```vim
" Quick check
:grep "vim\.notify\|vim\.log\.levels" %
```

## Debugging

### Enable Debug Output

```lua
local notify = require("lib.notify").create("[migrate.debug]")
notify.debug("Match found at line " .. line)
```

### Test Alias Detection

```vim
:lua local parser = require("usrcmds.migrate.notify.parser")
:lua local matches = parser.scan_buffer(0)
:lua print(vim.inspect(matches))
```

### Check Import

```vim
:lua local refactor = require("usrcmds.migrate.notify.refactor")
:lua print(refactor.check_import(0))
```

## Migration Checklist

Vor Migration:
- [ ] Backup erstellen (`git commit` oder `:w`)
- [ ] Buffer-Mode testen bevor CWD
- [ ] Modul-Namen überlegen

Nach Migration:
- [ ] `:checkhealth` laufen lassen
- [ ] Tests ausführen
- [ ] Manuelle Stichprobe
- [ ] Commit mit Message: "chore: migrate to lib.notify"

## Troubleshooting

### Problem: Aliases nicht erkannt

**Ursache:** Alias nicht am Anfang der Datei (erste 50 Zeilen)

**Lösung:** Aliases an den Anfang verschieben oder manuell migrieren

### Problem: Falscher Modul-Name

**Ursache:** Tippfehler bei `:MigrateNotify % mymodule`

**Lösung:**
1. Undo (`u`)
2. Erneut mit korrektem Namen: `:MigrateNotify % correct.name`

### Problem: Doppelte Imports

**Ursache:** Import existierte bereits

**Lösung:** Altes Import manuell löschen und erneut migrieren

### Problem: "No matches found"

**Mögliche Ursachen:**
- Bereits migriert
- File ist nicht `filetype=lua`
- Ungewöhnliche Formatierung

**Lösung:** Manuelle Prüfung mit `:grep vim.notify %`

## Weitere Resourcen

- `docs/technical.md` - Implementierungs-Details
- `docs/patterns.md` - Pattern-Matching Guide
- `notify/doc/migrate-notify.txt` - Vollständige Doku
- `opt/doc/migrate-opt.txt` - opt Module Doku

---
