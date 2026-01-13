# Neo-tree Custom Add Command

Erweiterter `add`-Befehl für Neo-tree mit Clipboard-Integration und automatischer Typdefinitions-Unterstützung.

## Table of content

- [Neo-tree Custom Add Command](#neo-tree-custom-add-command)
  - [Funktionalität](#funktionalitt)
    - [Normale Dateierstellung](#normale-dateierstellung)
    - [Verzeichniserstellung mit init.lua](#verzeichniserstellung-mit-initlua)
  - [Spezialbehandlung für Typdefinitionen](#spezialbehandlung-fr-typdefinitionen)
    - [Erkannte Muster](#erkannte-muster)
    - [Template-Verhalten](#template-verhalten)
    - [Bedingungen für Template-Einfügung](#bedingungen-fr-template-einfgung)
  - [Template-Datei](#template-datei)
  - [Dependencies](#dependencies)
  - [Integration in Neo-tree Config](#integration-in-neo-tree-config)
    - [1. Command registrieren](#1-command-registrieren)
    - [2. Keymap aktualisieren](#2-keymap-aktualisieren)
  - [Fehlerbehebung](#fehlerbehebung)
    - [`:InsertModule` nicht gefunden](#insertmodule-nicht-gefunden)
    - [Clipboard leer](#clipboard-leer)
    - [Buffer nicht leer](#buffer-nicht-leer)

---

## Funktionalität

### Normale Dateierstellung

Wenn der eingegebene Name **nicht** mit `/` endet:

1. Datei wird angelegt
2. Datei wird im Buffer geöffnet
3. Clipboard-Inhalt wird eingefügt
4. Datei wird gespeichert

**Beispiel:**
```
Eingabe: components/Button.tsx
→ Datei wird erstellt und Clipboard-Inhalt eingefügt
```

### Verzeichniserstellung mit init.lua

Wenn der eingegebene Name **mit** `/` endet:

1. Verzeichnis wird angelegt
2. `init.lua` wird im neuen Verzeichnis erstellt
3. Clipboard-Inhalt wird eingefügt
4. Datei wird gespeichert

**Beispiel:**
```
Eingabe: lib/utils/
→ Verzeichnis lib/utils/ wird erstellt
→ lib/utils/init.lua wird erstellt und Clipboard-Inhalt eingefügt
```

## Spezialbehandlung für Typdefinitionen

Das Modul erkennt automatisch Typdefinitionsdateien und -ordner für `lua_ls`:

### Erkannte Muster

1. Leere Ordner:
   - `@types/` → erstellt `@types/init.lua` mit Template
   - `types/` → erstellt `types/init.lua` mit Template

2. Dateien:
   - `@types.lua` → verwendet Template
   - `types.lua` → verwendet Template

### Template-Verhalten

Für erkannte Typdefinitionen wird automatisch folgendes Template eingefügt:
```lua
---@meta
---@module '{MODULEPATH}'

return {}
```

**Wichtig:** Die `@module`-Annotation wird durch das vorhandene `:InsertModule`-Kommando generiert.

### Bedingungen für Template-Einfügung

- Template wird nur eingefügt, wenn der Buffer **leer** ist
- Nach dem Einfügen wird die Datei automatisch gespeichert
- Cursor-Fokus wird in der Datei sichergestellt

## Template-Datei

Das Template befindet sich unter:
```
lua/config/neotree/commands/add/types_template.lua
```

Es enthält:
```lua
---@meta
---@module '{MODULEPATH}'

return {}
```

Der Platzhalter `{MODULEPATH}` wird durch `:InsertModule` ersetzt.

## Dependencies

- **User Command:** `:InsertModule` muss verfügbar sein für die automatische Generierung der `@module`-Annotation

## Integration in Neo-tree Config

### 1. Command registrieren

In `lua/config/neotree/commands.lua`:
```lua
---@module 'config.neotree.commands'
local getTelescopeOpts = require("config.neotree.commands.get_telescope_opts")
local diff_files_mod = require("config.neotree.commands.diff_files")
local mark_mod = require("config.neotree.commands.mark")
local node_utils = require("config.neotree.utils.node")
local add_mod = require("config.neotree.commands.add")  -- NEU

local api, fn = vim.api, vim.fn
local notify = vim.notify

---@return table<string, fun(state: Cfg.NeoTree.State)>
local function attach()
  return {
    open_badd = function(state)
      -- ... existing code ...
    end,

    -- NEU: Custom add command
    custom_add = add_mod.custom_add,

    -- ... weitere commands ...
  }
end

return {
  attach = attach
}
```

### 2. Keymap aktualisieren

In `lua/config/neotree/keymaps/filesystem.lua`:
```lua
-- ALT:
-- ["a"] = { "add", nowait = true, config = { show_path = "relative" } },

-- NEU:
["a"] = { "custom_add", nowait = true },
```

Die `config = { show_path = "relative" }` Option wird direkt im Command-Modul gesetzt und muss hier nicht mehr angegeben werden.

## Fehlerbehebung

### `:InsertModule` nicht gefunden

Wenn die Warnung erscheint:
```
Warning: :InsertModule command not found, module path not inserted
```

Dann fehlt das User Command. Das Template wird trotzdem eingefügt, aber `{MODULEPATH}` wird nicht ersetzt.

**Lösung:** User Command `:InsertModule` implementieren und in der Neovim-Config verfügbar machen.

### Clipboard leer

Wenn kein Clipboard-Inhalt verfügbar ist:
```
No clipboard content available
```

Die Datei wird trotzdem erstellt, aber ohne Inhalt.

### Buffer nicht leer

Bei Typdefinitionen wird das Template nur in leere Buffer eingefügt:
```
Buffer is not empty, skipping template insertion
```

Dies verhindert versehentliches Überschreiben von bestehendem Code.

---
