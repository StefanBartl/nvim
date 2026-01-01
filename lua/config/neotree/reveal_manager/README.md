# reveal_manager

Zentrales Reveal-Management für Neo-tree. Stellt sicher, dass die aktuelle Datei im Neo-tree immer korrekt gefunden und selektiert wird.

## Table of content

  - [Features](#features)
  - [API](#api)
    - [`reveal(ctx)`](#revealctx)
    - [`reveal_buffer(buf, position)`](#reveal_bufferbuf-position)
    - [`clear()`](#clear)
  - [Interne Logik](#interne-logik)
    - [Duplikats-Prevention](#duplikats-prevention)
    - [Buffer-Validierung](#buffer-validierung)
  - [Integration mit anderen Modulen](#integration-mit-anderen-modulen)
    - [cwd_sync.lua](#cwd_synclua)
    - [open/init.lua](#openinitlua)
    - [updir.lua](#updirlua)
  - [Error-Handling](#error-handling)
  - [Performance-Charakteristiken](#performance-charakteristiken)
  - [Best Practices](#best-practices)
    - [✅ DO](#do)
    - [❌ DON'T](#dont)
  - [Troubleshooting](#troubleshooting)
    - [Problem: Reveal funktioniert nicht](#problem-reveal-funktioniert-nicht)
    - [Problem: Reveal wird doppelt ausgeführt](#problem-reveal-wird-doppelt-ausgefhrt)
    - [Problem: Position wird ignoriert](#problem-position-wird-ignoriert)
  - [Dependencies](#dependencies)
  - [Testing](#testing)
  - [Changelog](#changelog)
    - [v1.0.0 (2024-01)](#v100-2024-01)
  - [See Also](#see-also)

---

## Features

* **Intelligente Duplikats-Prevention**: Verhindert redundante Reveal-Operationen
* **Buffer-Context-Awareness**: Validiert Buffer bevor Reveal durchgeführt wird
* **Position-Management**: Unterstützt alle Neo-tree Positionen (left/right/float/current)
* **Zeitbasiertes Caching**: Vermeidet doppelte Reveals innerhalb 500ms

## API

### `reveal(ctx)`

Revealed eine Datei in Neo-tree basierend auf einem Context-Objekt.

**Parameter:**
```lua
---@param ctx Cfg.NeoTree.RevealContext
---@field buf integer         -- Buffer-Nummer
---@field file string         -- Absolute Dateipfad
---@field dir string          -- Parent-Verzeichnis
---@field position string?    -- "left"|"right"|"float"|"current"
```

**Returns:** `boolean` - `true` wenn erfolgreich

**Beispiel:**
```lua
local reveal_mgr = require("config.neotree.reveal_manager")

local ctx = {
  buf = vim.api.nvim_get_current_buf(),
  file = "/path/to/file.lua",
  dir = "/path/to",
  position = "left"
}

if reveal_mgr.reveal(ctx) then
  print("File revealed successfully")
end
```

---

### `reveal_buffer(buf, position)`

Convenience-Funktion zum Revealen eines Buffers.

**Parameter:**
```lua
---@param buf integer?         -- Buffer-Nummer (nil = current buffer)
---@param position string?     -- Neo-tree Position
```

**Returns:** `boolean` - `true` wenn erfolgreich

**Beispiel:**
```lua
local reveal_mgr = require("config.neotree.reveal_manager")

-- Reveal current buffer
reveal_mgr.reveal_buffer()

-- Reveal specific buffer in float position
reveal_mgr.reveal_buffer(42, "float")
```

**Auto-Features:**
- Validiert automatisch ob Buffer eine echte Datei ist
- Extrahiert Verzeichnis aus Dateipfad
- Skipped automatisch wenn File in letzten 500ms bereits revealed wurde

---

### `clear()`

Löscht den internen Reveal-Cache. Nützlich beim Testen oder bei manuellen Resets.

**Beispiel:**
```lua
local reveal_mgr = require("config.neotree.reveal_manager")

reveal_mgr.clear()
-- Nächstes reveal() wird garantiert ausgeführt
```

---

## Interne Logik

### Duplikats-Prevention

```lua
-- Interner State
local last_reveal = {
  file = "/path/to/last_file.lua",
  time = 1234567890  -- vim.loop.now() timestamp
}

-- Check vor jedem Reveal
if last_reveal.file == ctx.file then
  local elapsed = vim.loop.now() - last_reveal.time
  if elapsed < 500 then
    return false  -- Skip duplicate
  end
end
```

### Buffer-Validierung

Nutzt `utils.get_buffer_context()` für robuste Validierung:

```lua
local ctx = utils.get_buffer_context(buf)
if not ctx then
  return false  -- Buffer ist nicht valid/geladen/readable
end
```

Prüft automatisch:
- ✅ Buffer ist valid (`nvim_buf_is_valid`)
- ✅ Buffer ist geladen (`nvim_buf_is_loaded`)
- ✅ Kein Special-Buftype (Terminal, Help, etc.)
- ✅ File existiert und ist lesbar (`filereadable`)

---

## Integration mit anderen Modulen

### cwd_sync.lua

`cwd_sync` nutzt die gleiche Reveal-Logik, sollte aber **nicht** `reveal_manager` direkt aufrufen (um Zirkelbezüge zu vermeiden). Stattdessen implementiert es seine eigene Reveal-Logik mit ähnlicher Duplikats-Prevention.

### open/init.lua

Opener-Funktionen sollten `reveal_manager` verwenden:

```lua
local function make_neotree_opener(position)
  return function()
    local reveal_mgr = require("config.neotree.reveal_manager")
    reveal_mgr.reveal_buffer(nil, position)

    -- Pause cwd_sync um Konflikt zu vermeiden
    local sync = require("config.neotree.cwd_sync")
    sync.pause_sync(2000)
  end
end
```

### updir.lua

Nach `updir` Operation sollte die alte Position selektiert werden (nicht revealed):

```lua
-- Nach updir: Selektiere alte Dir (NICHT reveal!)
vim.defer_fn(function()
  tree:set_selection(old_dir_node_id)
end, 100)
```

---

## Error-Handling

Alle Operationen sind mit `pcall` gesichert:

```lua
local ok = pcall(function()
  cmd.execute({
    action = "show",
    source = "filesystem",
    reveal = true,
    reveal_file = ctx.file,
  })
end)

return ok  -- false bei Fehler, keine Exception
```

---

## Performance-Charakteristiken

| Operation | Komplexität | Notizen |
|-----------|-------------|---------|
| `reveal()` | O(1) | Command-Execution, Tree-Traversierung ist Neo-tree intern |
| `reveal_buffer()` | O(1) | + Buffer-Validierung (schnell) |
| `clear()` | O(1) | Einfache Variablen-Zuweisung |

**Memory:** Minimaler Footprint (~2 Variablen im Module-State)

**Debouncing:** 500ms Cooldown zwischen identischen Files

---

## Best Practices

### ✅ DO

```lua
-- Use reveal_buffer für convenience
reveal_mgr.reveal_buffer()

-- Kombiniere mit cwd_sync pause
reveal_mgr.reveal_buffer(buf, "left")
sync.pause_sync(2000)

-- Clear cache bei Tests
before_each(function()
  reveal_mgr.clear()
end)
```

### ❌ DON'T

```lua
-- NICHT: reveal() ohne Buffer-Validierung
reveal_mgr.reveal({
  file = "/invalid/path",  -- ❌ Nicht validiert!
})

-- NICHT: reveal in tight loop
for i = 1, 100 do
  reveal_mgr.reveal_buffer()  -- ❌ Duplikate!
end

-- NICHT: Gleichzeitig mit cwd_sync ohne Pause
reveal_mgr.reveal_buffer()
-- cwd_sync überschreibt sofort! ❌
```

---

## Troubleshooting

### Problem: Reveal funktioniert nicht

**Diagnose:**
```lua
-- Check ob Buffer valid ist
local ctx = utils.get_buffer_context()
if not ctx then
  print("Buffer not valid for reveal")
  return
end

-- Check ob Neo-tree verfügbar
local ok, cmd = pcall(require, "neo-tree.command")
if not ok then
  print("Neo-tree.command not available")
end
```

**Lösung:**
- Stelle sicher Buffer ist eine echte Datei (kein Terminal, Help, etc.)
- Prüfe ob Neo-tree geladen ist
- Check ob Datei existiert: `vim.fn.filereadable(path)`

---

### Problem: Reveal wird doppelt ausgeführt

**Diagnose:**
```lua
-- Füge Debug-Logging hinzu
function M.reveal(ctx)
  print("Reveal called:", ctx.file)
  -- ...
end
```

**Lösung:**
- Nutze `clear()` wenn du garantiert neues Reveal willst
- Erhöhe Cooldown-Zeit in Code (aktuell 500ms)
- Prüfe ob mehrere Module gleichzeitig revealen

---

### Problem: Position wird ignoriert

**Diagnose:**
```lua
-- Check aktuell offene Position
local pos = utils.get_current_position()
print("Current position:", pos)
```

**Lösung:**
- Stelle sicher Neo-tree ist geschlossen bevor du mit anderer Position öffnest
- Nutze `action = "show"` (nicht "focus") in execute
- Check ob `cwd_sync` die Position überschreibt (→ `pause_sync()`)

---

## Dependencies

```lua
require("config.neotree.utils")         -- Buffer-Validierung, Context
require("neo-tree.command")             -- Neo-tree API
```

**Optional:**
```lua
require("config.neotree.cwd_sync")      -- Für pause_sync() Integration
```

---

## Testing

```lua
describe("reveal_manager", function()
  local reveal_mgr = require("config.neotree.reveal_manager")

  before_each(function()
    reveal_mgr.clear()
  end)

  it("reveals valid buffer", function()
    -- Create test buffer with file
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, "/tmp/test.lua")

    local ok = reveal_mgr.reveal_buffer(buf, "left")
    assert.is_true(ok)
  end)

  it("skips duplicate reveals", function()
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, "/tmp/test.lua")

    reveal_mgr.reveal_buffer(buf)
    local ok = reveal_mgr.reveal_buffer(buf)

    assert.is_false(ok)  -- Duplicate skipped
  end)

  it("reveals after clear", function()
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, "/tmp/test.lua")

    reveal_mgr.reveal_buffer(buf)
    reveal_mgr.clear()
    local ok = reveal_mgr.reveal_buffer(buf)

    assert.is_true(ok)  -- Allowed after clear
  end)
end)
```

---

## Changelog

### v1.0.0 (2024-01)
- Initial release
- Core reveal functionality
- Duplikats-Prevention (500ms)
- Buffer-Context integration
- Position management

---

## See Also

- [Neo-tree Documentation](https://github.com/nvim-neo-tree/neo-tree.nvim)

---
