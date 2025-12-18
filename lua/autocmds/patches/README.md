# Automatische Patch-Anwendung für Lazy.nvim

> **Version 2.0** - Asynchron, robust, performant

Dieses System ermöglicht es, lokale Fixes für Neovim-Plugins nach jedem `Lazy update` automatisch und **nicht-blockierend** erneut anzuwenden.

---

## Table of content

  - [🚀 Features](#features)
  - [📋 Voraussetzungen](#voraussetzungen)
  - [🏗️ Architektur](#architektur)
  - [📚 Patch-Registry](#patch-registry)
    - [Felder-Erklärung](#felder-erklrung)
  - [🎯 API-Übersicht](#api-bersicht)
    - [Setup (optional)](#setup-optional)
    - [Alle Patches anwenden (async)](#alle-patches-anwenden-async)
    - [Nur bestimmte Repositories patchen](#nur-bestimmte-repositories-patchen)
    - [Nur bestimmte Patches anwenden](#nur-bestimmte-patches-anwenden)
    - [Kombination (Repo + Key)](#kombination-repo-key)
    - [Alle Patches validieren (Dry-Run)](#alle-patches-validieren-dry-run)
    - [Status abfragen](#status-abfragen)
    - [Registrierte Patches auflisten](#registrierte-patches-auflisten)
    - [Logs anzeigen](#logs-anzeigen)
    - [Status-Cache leeren](#status-cache-leeren)
  - [📊 Status-Typen](#status-typen)
  - [🔧 Troubleshooting](#troubleshooting)
    - [Patches werden nicht angewendet](#patches-werden-nicht-angewendet)
    - [Performance-Optimierung](#performance-optimierung)
    - [Verbose-Modus für Debugging](#verbose-modus-fr-debugging)
  - [🔄 Automatische Anwendung](#automatische-anwendung)
  - [📝 Beispiel-Workflow](#beispiel-workflow)
    - [1. Neuen Patch erstellen](#1-neuen-patch-erstellen)
    - [2. In Patch-Verzeichnis kopieren](#2-in-patch-verzeichnis-kopieren)
    - [3. In Registry registrieren](#3-in-registry-registrieren)
    - [4. Validieren](#4-validieren)
    - [5. Anwenden](#5-anwenden)
  - [🧪 Testing](#testing)
    - [Dry-Run vor Produktion](#dry-run-vor-produktion)
    - [Einzelnen Patch testen](#einzelnen-patch-testen)
  - [📈 Performance-Metriken](#performance-metriken)
  - [🔒 Sicherheit](#sicherheit)
  - [🎓 Best Practices](#best-practices)
  - [📚 Weiterführende Dokumentation](#weiterfhrende-dokumentation)
  - [🙏 Credits](#credits)
  - [📄 License](#license)

---

## 🚀 Features

- ⚡ **Vollständig asynchron** - kein Blocking des Neovim-Starts
- 🔄 **Automatische Anwendung** nach Lazy.nvim-Updates
- ✅ **Intelligente Duplikatserkennung** - bereits angewendete Patches werden übersprungen
- 📊 **Persistentes Status-Tracking** mit Checksummen
- 🔍 **Dry-Run-Modus** zur Validierung
- 📝 **Strukturiertes JSON-Logging** mit Rotation
- 🎯 **Selektive Anwendung** nach Repo oder Key
- ⚙️ **Priorisierung** von Patches
- 🛡️ **Timeout-Protection** und Fehlerbehandlung
- 📦 **Keine Forks nötig** - klassische Diff-Dateien

---

## 📋 Voraussetzungen

- Neovim ≥ 0.9
- Lazy.nvim als Plugin-Manager
- `patch`-Command im PATH (auf allen Plattformen verfügbar)

---

## 🏗️ Architektur

```
autocmds/patches/
├── @types.lua         # Type-Definitionen
├── init.lua           # Public API + Lazy-Integration
├── paths.lua          # Patch-Registry
├── apply.lua          # Async Patch-Anwendung
├── validate.lua       # Pre-Flight & Dry-Run
├── status.lua         # Persistentes Status-Management
├── logger.lua         # Strukturiertes Logging
└── utils.lua          # Shared Utilities
```

---

## 📚 Patch-Registry

Alle Patches werden in `paths.lua` registriert:

```lua
{
  key = "gitsigns-system-compat",      -- Eindeutige ID
  repo = "gitsigns.nvim",              -- Plugin-Name
  priority = 100,                      -- Höher = früher (optional)
  enabled = true,                      -- Aktiviert/deaktiviert
  strip = 0,                           -- -p Level (optional)
  patch = "/abs/path/to/compat.diff",  -- Patch-Datei
  target = "/abs/path/to/compat.lua",  -- Ziel-Datei
}
```

### Felder-Erklärung

| Feld       | Typ            | Pflicht | Beschreibung                                     |
|------------|----------------|---------|--------------------------------------------------|
| `key`      | `string`       | ✅      | Eindeutige ID (global unique)                    |
| `repo`     | `string\|nil`  | ❌      | Plugin-Name (auto-detect falls nil)              |
| `patch`    | `string`       | ✅      | Absoluter Pfad zur Diff-Datei                    |
| `target`   | `string`       | ✅      | Absoluter Pfad zur Ziel-Datei                    |
| `priority` | `integer\|nil` | ❌      | Reihenfolge (default: 0)                         |
| `strip`    | `integer\|nil` | ❌      | Patch -p Level (default: 0)                      |
| `enabled`  | `boolean\|nil` | ❌      | Aktiv/deaktiviert (default: true)                |

---

## 🎯 API-Übersicht

### Setup (optional)

```lua
require("autocmds.patches").setup({
  max_concurrency = 3,           -- Parallele Patch-Operationen
  timeout_ms = 30000,            -- Timeout pro Patch (30s)
  verbose = false,               -- DEBUG-Logging aktivieren
  notify = true,                 -- Benachrichtigungen anzeigen
  lazy_update_delay_ms = 500,    -- Delay nach LazyUpdate
})
```

### Alle Patches anwenden (async)

```lua
require("autocmds.patches").apply_all_async(function(results)
  -- Optional: Callback mit Array von PatchResult
  for _, result in ipairs(results) do
    print(result.key, result.status, result.message)
  end
end)
```

### Nur bestimmte Repositories patchen

```lua
require("autocmds.patches").apply_async({
  repos = { "gitsigns.nvim", "todo-comments.nvim" },
  callback = function(results)
    print("Done:", #results)
  end
})
```

### Nur bestimmte Patches anwenden

```lua
require("autocmds.patches").apply_async({
  keys = { "nvchad-lsp-signature", "gitsigns-system-compat" },
})
```

### Kombination (Repo + Key)

```lua
require("autocmds.patches").apply_async({
  repos = { "gitsigns.nvim" },
  keys = { "gitsigns-system-compat" },
})
```

### Alle Patches validieren (Dry-Run)

```lua
require("autocmds.patches").validate_all(function(results)
  for _, result in ipairs(results) do
    if not result.valid then
      print("Invalid:", result.key, result.error)
    end
  end
end)
```

### Status abfragen

```lua
-- Alle Status-Einträge
local all = require("autocmds.patches").get_status()

-- Gefiltert nach Repo
local gitsigns = require("autocmds.patches").get_status({
  repos = { "gitsigns.nvim" }
})

-- Gefiltert nach Status
local failed = require("autocmds.patches").get_status({
  status_filter = { "failed" }
})

-- Kombination
local specific = require("autocmds.patches").get_status({
  repos = { "gitsigns.nvim" },
  keys = { "gitsigns-system-compat" },
  status_filter = { "applied", "failed" }
})
```

### Registrierte Patches auflisten

```lua
local patches = require("autocmds.patches").list()
for _, entry in ipairs(patches) do
  print(entry.key, entry.repo, entry.enabled)
end
```

### Logs anzeigen

```lua
-- In einem Buffer öffnen
require("autocmds.patches").show_logs_buffer()

-- Programmgesteuert abrufen
local logs = require("autocmds.patches").get_logs({
  level = "ERROR",  -- Nur ERROR-Level
  limit = 50,       -- Letzte 50 Einträge
})
```

### Status-Cache leeren

```lua
require("autocmds.patches").clear_status()
```

---

## 📊 Status-Typen

| Status            | Bedeutung                                     |
|-------------------|-----------------------------------------------|
| `never_tried`     | Noch nie versucht                             |
| `already_applied` | Bereits angewendet (via Checksum/Dry-Run)     |
| `applied`         | Erfolgreich in diesem Run angewendet          |
| `failed`          | Fehlgeschlagen (siehe `message`)              |
| `disabled`        | Deaktiviert via `enabled=false`               |

---

## 🔧 Troubleshooting

### Patches werden nicht angewendet

**Diagnose:**

```lua
-- Logs prüfen
require("autocmds.patches").show_logs_buffer()

-- Status prüfen
local status = require("autocmds.patches").get_status()
vim.print(status)

-- Validierung
require("autocmds.patches").validate_all(function(results)
  vim.print(results)
end)
```

**Häufige Ursachen:**

1. **Patch-Datei nicht gefunden** → Pfad in `paths.lua` prüfen
2. **Target-Datei nicht gefunden** → Plugin installiert? Pfad korrekt?
3. **Bereits angewendet** → Status zeigt `already_applied`
4. **Falscher Strip-Level** → `strip` Wert anpassen (meist 0, 1, oder 2)
5. **Ungültige Diff-Syntax** → Diff-Datei mit `patch --dry-run` testen

### Performance-Optimierung

```lua
require("autocmds.patches").setup({
  max_concurrency = 5,  -- Mehr parallele Operationen
  timeout_ms = 15000,   -- Kürzerer Timeout
})
```

### Verbose-Modus für Debugging

```lua
require("autocmds.patches").setup({
  verbose = true,  -- Aktiviert DEBUG-Logging
})
```

---

## 🔄 Automatische Anwendung

Das System registriert automatisch einen Autocommand:

```vim
autocmd User LazyUpdate
```

**Workflow:**

1. User führt `:Lazy update` aus
2. Lazy.nvim updated Plugins
3. `LazyUpdate`-Event wird gefeuert
4. Nach 500ms (konfigurierbar) werden Patches asynchron angewendet
5. Benachrichtigung bei Erfolg/Fehlschlag

**Delay anpassen:**

```lua
require("autocmds.patches").setup({
  lazy_update_delay_ms = 1000,  -- 1 Sekunde Delay
})
```

---

## 📝 Beispiel-Workflow

### 1. Neuen Patch erstellen

```bash
cd ~/.local/share/nvim/lazy/gitsigns.nvim
git diff lua/gitsigns/system/compat.lua > ~/patch.diff
```

### 2. In Patch-Verzeichnis kopieren

```bash
mkdir -p ~/.config/nvim/patches/gitsigns/system/compat
cp ~/patch.diff ~/.config/nvim/patches/gitsigns/system/compat/diff.patch
```

### 3. In Registry registrieren

```lua
-- In paths.lua
{
  key = "gitsigns-my-fix",
  repo = "gitsigns.nvim",
  priority = 100,
  enabled = true,
  patch = patches .. "/gitsigns/system/compat/diff.patch",
  target = lazy .. "/gitsigns.nvim/lua/gitsigns/system/compat.lua",
}
```

### 4. Validieren

```lua
:lua require("autocmds.patches").validate_all()
```

### 5. Anwenden

```lua
:lua require("autocmds.patches").apply_all_async()
```

---

## 🧪 Testing

### Dry-Run vor Produktion

```lua
require("autocmds.patches").validate_all(function(results)
  local invalid = vim.tbl_filter(function(r)
    return not r.valid
  end, results)

  if #invalid > 0 then
    print("Invalid patches found:")
    vim.print(invalid)
  else
    print("All patches valid, ready to apply")
  end
end)
```

### Einzelnen Patch testen

```lua
require("autocmds.patches").apply_async({
  keys = { "gitsigns-my-fix" },
  callback = function(results)
    if results[1].success then
      print("Success!")
    else
      print("Failed:", results[1].message)
    end
  end
})
```

---

## 📈 Performance-Metriken

- **Startup-Overhead:** <5ms (nur Setup)
- **Patch-Anwendung:** ~50-200ms pro Patch (async)
- **Memory:** <500KB (Status + Logs)
- **Disk I/O:** Minimiert durch Batch-Writes

---

## 🔒 Sicherheit

- ✅ Alle Dateipfade werden validiert
- ✅ Timeout-Protection (default 30s)
- ✅ Sandbox-Execution für `patch`-Command
- ✅ Kein Eval von User-Input
- ✅ Type-Safe APIs mit Guards

---

## 🎓 Best Practices

1. **Patch-Dateien versionieren** (z.B. in Git)
2. **Beschreibende Keys** verwenden (`<repo>-<feature>-<issue>`)
3. **Priority** nur bei Abhängigkeiten setzen
4. **Regelmäßig validieren** mit `validate_all()`
5. **Logs monitoren** bei Problemen
6. **Checksummen** werden automatisch getrackt → keine Doppel-Anwendung

---

## 📚 Weiterführende Dokumentation

- **Type-Definitionen:** Siehe `@types.lua` für alle Type-Definitionen
- **Logging:** Siehe `logger.lua` für Log-Format und API
- **Status-Management:** Siehe `status.lua` für Persistenz-Details
- **Validation:** Siehe `validate.lua` für Pre-Flight-Checks

---

## 🙏 Credits

- Design nach **Arch&Coding-Regeln.md**
- Performance-Optimierungen aus **Checklist.md**
- Type-System nach **@types.lua** Best Practices

---

## 📄 License

Dieses Modul ist Teil der persönlichen Neovim-Konfiguration.
