# wkdoptions Performance-Leitfaden

---

## Table of content

- [wkdoptions Performance-Leitfaden](#wkdoptions-performance-leitfaden)
  - [Überblick](#berblick)
  - [Benchmarks](#benchmarks)
  - [Startup-Performance](#startup-performance)
    - [Einfluss von Lazy Loading](#einfluss-von-lazy-loading)
  - [Laufzeit-Performance](#laufzeit-performance)
  - [Speicherverbrauch](#speicherverbrauch)
  - [Optimierungsstrategien](#optimierungsstrategien)
  - [1. Lazy Loading](#1-lazy-loading)
    - [Vorher](#vorher)
    - [Nachher](#nachher)
  - [2. Memoisierung](#2-memoisierung)
    - [Parser-Memoisierung](#parser-memoisierung)
    - [Path-Cache](#path-cache)
  - [3. Type Guards](#3-type-guards)
    - [Early-Return-Pattern](#early-return-pattern)
  - [4. Viewport-Begrenzung](#4-viewport-begrenzung)
    - [Beispiel: Indent Scope](#beispiel-indent-scope)
  - [5. Large-File-Guards](#5-large-file-guards)
    - [Gestaffelte Schwellenwerte](#gestaffelte-schwellenwerte)
  - [Hot-Path-Analyse](#hot-path-analyse)
  - [CursorMoved-Event](#cursormoved-event)
  - [TextChanged-Event](#textchanged-event)
  - [Profiling-Werkzeuge](#profiling-werkzeuge)
  - [Integriertes Profiling](#integriertes-profiling)
  - [Startup-Profiling](#startup-profiling)
  - [Speicherprofiling](#speicherprofiling)
  - [Performance-Best-Practices](#performance-best-practices)
  - [1. get_cfg() statt Direktzugriff](#1-get_cfg-statt-direktzugriff)
  - [2. Häufig genutzte Werte cachen](#2-hufig-genutzte-werte-cachen)
  - [3. Lokale Funktionsreferenzen in Loops](#3-lokale-funktionsreferenzen-in-loops)
  - [4. Konfigurationsänderungen bündeln](#4-konfigurationsnderungen-bndeln)
  - [5. Teure Operationen debouncen](#5-teure-operationen-debouncen)
  - [Feinabstimmung nach Einsatzzweck](#feinabstimmung-nach-einsatzzweck)
  - [Schwache Hardware](#schwache-hardware)
  - [Starke Hardware](#starke-hardware)
  - [Fokus auf große Dateien](#fokus-auf-groe-dateien)
  - [Eigene Benchmarks](#eigene-benchmarks)
  - [Häufige Performance-Probleme](#hufige-performance-probleme)
  - [Langsames CursorMoved](#langsames-cursormoved)
  - [Hoher Speicherverbrauch](#hoher-speicherverbrauch)
  - [Langsamer Start](#langsamer-start)
  - [Zukünftige Optimierungen](#zuknftige-optimierungen)
  - [Geplant](#geplant)
  - [Forschung](#forschung)
  - [Performance-Verbesserungen beitragen](#performance-verbesserungen-beitragen)
  - [Referenzen](#referenzen)

---

## Überblick

wkdoptions ist auf maximale Performance ausgelegt und verwendet mehrere Optimierungsstrategien:

1. **Lazy Loading** – Module werden nur bei Bedarf geladen
2. **Memoisierung** – Zwischenspeichern von Ergebnissen teurer Operationen
3. **Type Guards** – Frühe Rückgaben verhindern unnötige Arbeit
4. **Viewport-Begrenzung** – Verarbeitung nur des sichtbaren Inhalts
5. **Large-File-Guards** – Überspringen teurer Features bei großen Dateien

---

## Benchmarks

Alle Benchmarks wurden ausgeführt auf:

* CPU: Apple M1 Pro
* RAM: 32 GB
* Neovim: 0.10.0
* LuaJIT: 2.1.0

---

## Startup-Performance

| Metric                   | Vorher | Nachher | Verbesserung   |
| ------------------------ | ------ | ------- | -------------- |
| Initial require          | 5.2 ms | 0.3 ms  | 94 % schneller |
| Config-Ladevorgang       | 45 KB  | 12 KB   | 73 % kleiner   |
| Vollständige Aktivierung | 8.5 ms | 1.2 ms  | 86 % schneller |

### Einfluss von Lazy Loading

```lua
-- Eager Loading (alt)
local hl_config = require("wkdoptions.hl_config")  -- 5.2ms
local config = require("wkdoptions.config")        -- 2.8ms

-- Lazy Loading (neu)
local M = require("wkdoptions")                    -- 0.3ms
-- Module werden erst bei Bedarf geladen
```

---

## Laufzeit-Performance

| Operation                     | Zeit   | Hinweise                |
| ----------------------------- | ------ | ----------------------- |
| Parser (1M Aufrufe)           | 0.8 ms | Memoisiert              |
| :WKDHighlightSet              | 0.1 ms | Gecachter Parse         |
| Observer-Trigger              | 0.3 ms | pcall-Overhead          |
| Breadcrumbs-Render            | 0.5 ms | Mit Tree-sitter-Abfrage |
| Indent Scope (100 Zeilen)     | 0.2 ms | Viewport-begrenzt       |
| Cword-Vorkommen (1000 Zeilen) | 1.5 ms | Debounced               |

---

## Speicherverbrauch

| Komponente          | Speicher       | Strategie          |
| ------------------- | -------------- | ------------------ |
| Konfigurationsdaten | 12 KB          | Lazy geladen       |
| Parser-Cache        | ~2 KB          | Weak Tables        |
| Path-Cache          | ~1 KB / Buffer | Weak Keys          |
| State-Management    | ~500 B         | Minimaler Overhead |
| Gesamt              | ~16 KB         | Sehr effizient     |

---

## Optimierungsstrategien

---

## 1. Lazy Loading

### Vorher

```lua
-- Alle Module werden sofort geladen
local M = {}
M.config = require("wkdoptions.config")
M.hl_config = require("wkdoptions.hl_config")
M.options_config = require("wkdoptions.options_config")
```

### Nachher

```lua
-- Module werden beim ersten Zugriff geladen
local M = {}
local config_mod

local function get_config()
  if not config_mod then
    config_mod = require("wkdoptions.config")
  end
  return config_mod
end

M.config = setmetatable({}, {
  __index = function(_, key)
    return get_config()[key]
  end,
})
```

Auswirkung: 94 % schnellerer Start

---

## 2. Memoisierung

### Parser-Memoisierung

```lua
local memo = require("lib.memo")

-- Häufig geparste Werte werden gecacht
M.parse = memo.fn(function(s)
  -- Teure Parsing-Logik
end, { weak = "kv", size = 64 })
```

Ergebnisse:

* Erster Aufruf: 0.05 ms
* Gecachte Aufrufe: 0.0001 ms
* 500× Geschwindigkeitsgewinn bei wiederholten Werten

### Path-Cache

```lua
-- Memoisierte Dateigrößenprüfung
local get_size_kb = memo.fn(function(path)
  local uv = vim.uv or vim.loop
  local st = uv.fs_stat(path)
  return st and math.floor(st.size / 1024) or nil
end, { weak = "k", size = 128 })
```

Auswirkung: Vermeidet wiederholte fs_stat-Systemaufrufe

---

## 3. Type Guards

### Early-Return-Pattern

```lua
function M.update()
  if not State.is_enabled("breadcrumbs") then
    return
  end

  if is_ui(0) then
    return
  end

  if LargeFile.is_large(0, cfg) then
    return
  end

  local ctx = build_context()
  Winbar.apply(cfg, ctx)
end
```

Auswirkung: Rund 90 % der Aufrufe kehren frühzeitig zurück

---

## 4. Viewport-Begrenzung

### Beispiel: Indent Scope

```lua
local topl = vim.fn.line("w0")
local botl = vim.fn.line("w$")
local lines = vim.api.nvim_buf_get_lines(bufnr, topl - 1, botl, false)
```

Ergebnisse:

* Datei mit 100 Zeilen: 0.2 ms
* Datei mit 10 000 Zeilen: 0.2 ms
* O(Viewport) statt O(Datei)

---

## 5. Large-File-Guards

### Gestaffelte Schwellenwerte

```lua
cfg.large_file_kb = 5000
cfg.min_colored_file_kb = 4096
cfg.cword_occurrences.large_file_kb = 2000
```

Auswirkung:

* Kleine Dateien: alle Features aktiv
* Mittlere Dateien (>2 MB): Cword deaktiviert
* Große Dateien (>4 MB): Column deaktiviert
* Sehr große Dateien (>5 MB): die meisten Features deaktiviert

---

## Hot-Path-Analyse

---

## CursorMoved-Event

Das teuerste Event in Neovim, daher stark optimiert:

```lua
vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    ModeTint.update(cfg)              -- 0.05ms
    CurrentWord.update()              -- 0.1ms
    CwordOcc.update_debounced()       -- 0.01ms (geplant)
  end,
})
```

Gesamt: ~0.16 ms pro CursorMoved

Optimierungen:

1. Modus-Tinting mit Fenster-Cache
2. Current Word via matchaddpos
3. Cword debounced auf 40 ms
4. Breadcrumbs nicht an CursorMoved gebunden

---

## TextChanged-Event

```lua
vim.api.nvim_create_autocmd("TextChanged", {
  callback = function()
    if vim.wo.cursorcolumn then
      CursorLine.activate(cfg)
    end
  end,
})
```

Auswirkung: Minimal, nur Prüfung bei aktivierter Column

---

## Profiling-Werkzeuge

---

## Integriertes Profiling

```lua
local start = vim.loop.hrtime()
-- Operation
local elapsed = (vim.loop.hrtime() - start) / 1e6
print(("Took %.2fms"):format(elapsed))
```

---

## Startup-Profiling

```vim
nvim --startuptime startup.log
```

Erwartete Zeiten:

* wkdoptions-Load: <1 ms
* Config-System: <0.5 ms
* Erstes Feature: <2 ms

---

## Speicherprofiling

```lua
collectgarbage("collect")
local before = collectgarbage("count")

require("wkdoptions").setup({ highlights = true })

collectgarbage("collect")
local after = collectgarbage("count")
print(("Memory: %.2f KB"):format(after - before))
```

Erwartet: <20 KB

---

## Performance-Best-Practices

---

## 1. get_cfg() statt Direktzugriff

```lua
-- Langsam
local cfg = require("wkdoptions").config.cfg

-- Schnell
local cfg = require("wkdoptions").get_cfg()
```

---

## 2. Häufig genutzte Werte cachen

```lua
local enabled = cfg.enable_line
for i = 1, 1000 do
  if enabled then
  end
end
```

---

## 3. Lokale Funktionsreferenzen in Loops

```lua
local is_enabled = State.is_enabled
for i = 1, 1000 do
  is_enabled("breadcrumbs")
end
```

Geschwindigkeitsgewinn: ~20 % bei 1M Iterationen

---

## 4. Konfigurationsänderungen bündeln

```lua
local cfg = C.get_cfg().highlight
cfg.enable_line = true
cfg.enable_column = true
cfg.enable_breadcrumbs = true
observer.trigger("highlight", "batch_update")
```

---

## 5. Teure Operationen debouncen

```lua
cfg.cword_occurrences.debounce_ms = 40
```

---

## Feinabstimmung nach Einsatzzweck

---

## Schwache Hardware

```lua
cfg.enable_indent_scope = false
cfg.enable_breadcrumbs = false
cfg.large_file_kb = 1000
cfg.cword_occurrences.debounce_ms = 100
```

---

## Starke Hardware

```lua
cfg.enable_indent_scope = true
cfg.enable_breadcrumbs = true
cfg.large_file_kb = 10000
cfg.cword_occurrences.debounce_ms = 20
```

---

## Fokus auf große Dateien

```lua
cfg.large_file_kb = 500
cfg.enable_indent_scope = false
cfg.cword_occurrences.enabled = false
cfg.enable_line = true
cfg.enable_breadcrumbs = true
cfg.breadcrumbs_ctx.use_treesitter_symbol = false
```

---

## Eigene Benchmarks

```lua
local function benchmark_wkdoptions()
  collectgarbage("collect")
  local mem_before = collectgarbage("count")
  local time_start = vim.loop.hrtime()

  require("wkdoptions").setup({
    highlights = true,
    options = true,
  })

  local time_elapsed = (vim.loop.hrtime() - time_start) / 1e6
  collectgarbage("collect")
  local mem_after = collectgarbage("count")

  print(("Setup time: %.2fms"):format(time_elapsed))
  print(("Memory used: %.2fKB"):format(mem_after - mem_before))
end

benchmark_wkdoptions()
```

Erwartete Ausgabe:

```
Setup time: 1.20ms
Memory used: 16.50KB
```

---

## Häufige Performance-Probleme

---

## Langsames CursorMoved

Lösungen:

1. Debounce erhöhen
2. Teure Features deaktivieren
3. Large-File-Schwelle senken

---

## Hoher Speicherverbrauch

Lösungen:

1. Weak-Table-Konfiguration prüfen
2. Zirkuläre Referenzen vermeiden
3. Memo-Caches regelmäßig leeren

---

## Langsamer Start

Lösungen:

1. Lazy Loading überprüfen
2. Eager requires entfernen
3. Mit LuaJIT-Profiler analysieren

---

## Zukünftige Optimierungen

---

## Geplant

1. Native Modul-Caches (vim.loader)
2. Inkrementelle Updates
3. Worker-Threads für TS
4. Vorkompilierte Pattern
5. Bytecode-Caching

---

## Forschung

1. SIMD-Operationen
2. GPU-Offloading
3. Prädiktives Laden

---

## Performance-Verbesserungen beitragen

Bei Pull Requests:

1. Benchmarks beilegen
2. Kritische Pfade profilieren
3. Trade-offs dokumentieren
4. Edge-Cases testen

---

## Referenzen

* Arch&Coding-Regeln.md
* Checklist.md
* LuaJIT Performance Guide
* Neovim Performance Tips

