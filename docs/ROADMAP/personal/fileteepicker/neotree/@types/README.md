# Neo-tree Configuration Type System

Dieser Ordner enthält alle Typdefinitionen für das `config.neotree` Modul, organisiert nach funktionalen Domänen.

## Table of content

- [Neo-tree Configuration Type System](#neo-tree-configuration-type-system)
  - [Struktur](#struktur)
    - [Core Types (Kernstrukturen)](#core-types-kernstrukturen)
    - [Feature Modules (Funktionsmodule)](#feature-modules-funktionsmodule)
    - [Integration Modules](#integration-modules)
  - [Namenskonventionen](#namenskonventionen)
    - [String Literal Unions als Aliases](#string-literal-unions-als-aliases)
  - [Organisation Principles](#organisation-principles)
  - [Import](#import)
  - [Mapping: Folder → Type File](#mapping-folder-type-file)

---

## Struktur

---

### Core Types (Kernstrukturen)

- **`aliases.lua`**: Zentrale Type Aliases und String-Literal-Unions
  - Positionen, Operationen, Icon-Familien, Source-Namen
  - Wird von allen anderen Modulen verwendet

- **`node.lua`**: Neo-tree Node Struktur
  - Repräsentation von Dateien/Verzeichnissen im Baum
  - Methoden: `get_parent_id()`, `is_directory()`, etc.

- **`state.lua`**: Neo-tree State Objekt
  - Wird an Commands und Event Handler übergeben
  - Enthält Tree, Current Node, Clipboard, etc.

- **`config.lua`**: Setup und Initialisierung
  - `Cfg.NeoTree.InitOpts` für `setup()`
  - Konfiguration für CurrentHL, CwdSync, Trash

---

### Feature Modules (Funktionsmodule)

- **`actions.lua`**: Custom Command Optionen
  - Clipboard-Optionen, Path-Conversion, Node-Info

- **`trash.lua`**: Trash System
  - Konfiguration für sichere Dateilöschung

- **`safety.lua`**: Safety & Recovery
  - Backup-Entries, Recovery Points, Queued Operations

- **`open.lua`**: Window Management
  - Timing, Busy Guards, Extra Keymaps

- **`reveal.lua`**: File Reveal
  - Context für Datei-Navigation

- **`cwd_sync.lua`**: CWD Synchronisation
  - State für automatische CWD-Sync

- **`highlights.lua`**: Current File Highlighting
  - Farben und State für aktuelle Datei

- **`watcher.lua`**: File Watcher
  - Quarantine State, Error Handling

---

### Integration Modules

- **`sources.lua`**: Source Display
  - Icon-Sets, Dynamic Config

- **`wsl.lua`**: WSL Integration
  - Path-Konvertierung, File Manager Backend

- **`project_root.lua`**: Project Root Detection
  - Minimal Interface für Root-Finding

---

## Namenskonventionen

Alle Types verwenden das Prefix **`Cfg.NeoTree.*`**:

```lua
---@type Cfg.NeoTree.State
local state = { ... }

---@param position Cfg.NeoTree.Position
---@param operation Cfg.NeoTree.FileOperation
```

---

### String Literal Unions als Aliases

Alle häufig genutzten String-Literal-Unions sind als Aliases definiert:

```lua
-- Statt:
---@param mode "delete"|"move"|"overwrite"

-- Jetzt:
---@param mode Cfg.NeoTree.FileOperation
```

---

## Organisation Principles

1. **Ein File pro funktionale Domäne** (nicht pro Source-File)
2. **String-Literal-Unions extrahieren** als Type Aliases
3. **Minimale Forward Dependencies** zwischen Type Modules
4. **Structural Typing** für Neo-tree Core Objects
5. **Explizite Field Documentation** mit Usage Notes

---

## Import

Zentral über `init.lua`:

```lua
require("config.neotree.@types")
```

Oder spezifisch:

```lua
---@module 'config.neotree.@types.state'
---@module 'config.neotree.@types.actions'
```

---

## Mapping: Folder → Type File

|  Modul-Folder  |         Type-File         |   Beschreibung    |
|----------------|---------------------------|-------------------|
|   `/` (root)   |       `config.lua`        |   Setup & Init    |
|  `/actions/`   |       `actions.lua`       |  Custom Commands  |
|   `/trash/`    | `trash.lua`, `safety.lua` |  Deletion System  |
|    `/open/`    |        `open.lua`         | Window Management |
|   `/reveal/`   |       `reveal.lua`        |  File Navigation  |
|  `/cwd_sync/`  |      `cwd_sync.lua`       |     CWD Sync      |
| `/current_hl/` |     `highlights.lua`      |   Highlighting    |
|  `/watcher/`   |       `watcher.lua`       |    FS Watcher     |
|  `/sources/`   |       `sources.lua`       |  Source Display   |
|    `/wsl/`     |         `wsl.lua`         |  WSL Integration  |
|   (utility)    |    `project_root.lua`     |  Root Detection   |

---
