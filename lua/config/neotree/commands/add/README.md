# Neo-tree Custom Add Command

Erweiterter `add`-Befehl für Neo-tree mit Clipboard-Integration und automatischer Typdefinitions-Unterstützung.

## Table of content

- [Neo-tree Custom Add Command](#neo-tree-custom-add-command)
  - [Funktionalität](#funktionalitt)
    - [Normale Dateierstellung](#normale-dateierstellung)
    - [Verzeichniserstellung mit init.lua](#verzeichniserstellung-mit-initlua)
  - [Clipboard-Optionen](#clipboard-optionen)
    - [insert_clipb (default: false)](#insert_clipb-default-false)
    - [ask_insert_clipb (default: false)](#ask_insert_clipb-default-false)
    - [Kein Clipboard (default)](#kein-clipboard-default)
  - [Spezialbehandlung für Typdefinitionen (Lua)](#spezialbehandlung-fr-typdefinitionen-lua)
    - [Erkannte Muster](#erkannte-muster)
    - [Template-Verhalten](#template-verhalten)
    - [Bedingungen für Template-Einfügung](#bedingungen-fr-template-einfgung)
  - [Template-Datei](#template-datei)
  - [Dependencies](#dependencies)
  - [Erweiterbarkeit für andere Sprachen](#erweiterbarkeit-fr-andere-sprachen)
    - [Aktuelle Struktur](#aktuelle-struktur)
    - [Erweiterung für TypeScript/JavaScript](#erweiterung-fr-typescriptjavascript)
    - [Erweiterung für Python](#erweiterung-fr-python)
  - [Verwendung](#verwendung)
  - [Fehlerbehebung](#fehlerbehebung)
    - [Library-Module nicht gefunden](#library-module-nicht-gefunden)
    - [Clipboard leer](#clipboard-leer)
    - [Buffer nicht leer](#buffer-nicht-leer)

---

## Funktionalität

### Normale Dateierstellung

Wenn der eingegebene Name **nicht** mit `/` endet:

1. Datei wird angelegt
2. Datei wird im Buffer geöffnet
3. Optional: Clipboard-Inhalt wird eingefügt (abhängig von Optionen)
4. Optional: Datei wird gespeichert (wenn Clipboard eingefügt wurde)

**Beispiel:**
```
Eingabe: components/Button.tsx
→ Datei wird erstellt
→ Je nach Keymap: Clipboard-Inhalt wird eingefügt oder nachgefragt
```

### Verzeichniserstellung mit init.lua

Wenn der eingegebene Name **mit** `/` endet:

1. Verzeichnis wird angelegt
2. `init.lua` wird im neuen Verzeichnis erstellt (Lua-spezifisch)
3. Optional: Clipboard-Inhalt wird eingefügt
4. Optional: Datei wird gespeichert

**Beispiel:**
```
Eingabe: lib/utils/
→ Verzeichnis lib/utils/ wird erstellt
→ lib/utils/init.lua wird erstellt
→ Je nach Keymap: Clipboard-Inhalt wird eingefügt
```

## Clipboard-Optionen

Das Modul unterstützt verschiedene Clipboard-Verhaltensweisen über Optionen:

### insert_clipb (default: false)

Fügt automatisch den Clipboard-Inhalt ein, ohne zu fragen.
```lua
["A"] = {
  "custom_add",
  nowait = true,
  config = { insert_clipb = true }
}
```

### ask_insert_clipb (default: false)

Fragt den Benutzer, ob Clipboard-Inhalt eingefügt werden soll.
```lua
["<M-a>"] = {
  "custom_add",
  nowait = true,
  config = { ask_insert_clipb = true }
}
```

### Kein Clipboard (default)

Ohne Optionen wird kein Clipboard-Inhalt eingefügt.
```lua
["a"] = {
  "custom_add",
  nowait = true
}
```

## Spezialbehandlung für Typdefinitionen (Lua)

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
---@module 'actual.module.path'

return {}
```

**Wichtig:** Die `@module`-Annotation wird durch das Library-Modul `lib.lua_ls.insert.module_w_path` generiert und enthält den tatsächlichen Modulpfad der Datei.

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

Der Platzhalter `{MODULEPATH}` wird durch das Library-Modul ersetzt.

## Dependencies

Dieses Modul benötigt folgende Library-Module:

- `lib.lua_ls.insert.module_w_path` - Fügt `@module` Annotation mit korrektem Pfad ein
- `lib.lua_ls.get_module_path` - Berechnet den Modulpfad relativ zum `lua/` Verzeichnis
- `lib.buffer.insert_lines_at_cursor` - Fügt Zeilen am Cursor ein

## Erweiterbarkeit für andere Sprachen

Das Modul ist so strukturiert, dass es leicht für andere Programmiersprachen erweitert werden kann:

### Aktuelle Struktur
```lua
-- Check file extension
local ext = get_extension(full_path)

if ext == "lua" then
  -- Lua-specific handling
  if is_types_target(full_path) then
    handle_lua_types_file(full_path, state, options)
  else
    handle_regular_file(full_path, options)
  end
else
  -- Non-Lua files - handle regularly
  -- (Can be extended for other languages here)
  handle_regular_file(full_path, options)
end
```

### Erweiterung für TypeScript/JavaScript

Man könnte beispielsweise hinzufügen:
```lua
elseif ext == "ts" or ext == "tsx" then
  -- TypeScript-specific handling
  if is_types_target_ts(full_path) then
    handle_ts_types_file(full_path, state, options)
  else
    handle_regular_file(full_path, options)
  end
```

### Erweiterung für Python
```lua
elseif ext == "py" then
  -- Python-specific handling
  if is_types_target_py(full_path) then
    handle_py_types_file(full_path, state, options)
  else
    handle_regular_file(full_path, options)
  end
```

## Verwendung

Nach der Integration kann man in Neo-tree wie folgt vorgehen:

**Datei ohne Clipboard erstellen:**
```
Taste: a
Eingabe: components/MyComponent.tsx
→ Datei wird erstellt, kein Clipboard
```

**Datei mit Clipboard erstellen:**
```
Taste: A (Shift+a)
Eingabe: components/MyComponent.tsx
→ Datei wird erstellt, Clipboard automatisch eingefügt
```

**Datei mit Clipboard-Abfrage:**
```
Taste: Alt+a
Eingabe: components/MyComponent.tsx
→ Dialog: "Insert clipboard content?"
→ Je nach Antwort: Clipboard eingefügt oder nicht
```

**Verzeichnis mit init.lua:**
```
Taste: A
Eingabe: lib/helpers/
→ lib/helpers/ wird erstellt
→ lib/helpers/init.lua wird erstellt mit Clipboard-Inhalt
```

**Types-Datei:**
```
Taste: a
Eingabe: @types.lua
→ Datei wird mit Template erstellt
→ @module Annotation wird automatisch mit korrektem Pfad eingefügt
```

## Fehlerbehebung

### Library-Module nicht gefunden

Wenn die Warnung erscheint:
```
Failed to load module annotation library
```

Dann fehlen die Library-Module. Stelle sicher, dass folgende Module verfügbar sind:
- `lib.lua_ls.insert.module_w_path`
- `lib.lua_ls.get_module_path`
- `lib.buffer.insert_lines_at_cursor`

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
