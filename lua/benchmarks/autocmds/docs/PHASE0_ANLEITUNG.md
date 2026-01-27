# Phase 0: Foundation - Schritt-für-Schritt Anleitung

## Table of content

- [Phase 0: Foundation - Schritt-für-Schritt Anleitung](#phase-0-foundation-schritt-fr-schritt-anleitung)
  - [Übersicht](#bersicht)
  - [Setup (einmalig)](#setup-einmalig)
    - [1. Benchmarking-System aktivieren](#1-benchmarking-system-aktivieren)
    - [2. Neovim neu starten](#2-neovim-neu-starten)
  - [Schritt 1: Baseline Benchmark (VORHER)](#schritt-1-baseline-benchmark-vorher)
    - [Ausführung](#ausfhrung)
      - [Option A: User Command (empfohlen)](#option-a-user-command-empfohlen)
      - [Option B: Lua direkt](#option-b-lua-direkt)
      - [Option C: Programmierbar](#option-c-programmierbar)
    - [Was passiert?](#was-passiert)
    - [Erwartete Ergebnisse](#erwartete-ergebnisse)
    - [Wichtig: Pfad speichern!](#wichtig-pfad-speichern)
  - [Schritt 2: Phase 0 Tests](#schritt-2-phase-0-tests)
    - [Ausführung](#ausfhrung-1)
    - [Was wird getestet?](#was-wird-getestet)
    - [Erwartete Ergebnisse](#erwartete-ergebnisse-1)
  - [Schritt 3: Ergebnisse dokumentieren](#schritt-3-ergebnisse-dokumentieren)
    - [Baseline-Daten extrahieren](#baseline-daten-extrahieren)
    - [Phase 0 Stats speichern](#phase-0-stats-speichern)
  - [Schritt 4: Commit erstellen](#schritt-4-commit-erstellen)
  - [Troubleshooting](#troubleshooting)
    - [Problem: "Should be normal buffer" Fehler](#problem-should-be-normal-buffer-fehler)
    - [Problem: LSP-Warnungen](#problem-lsp-warnungen)
    - [Problem: Cache hit rate <80%](#problem-cache-hit-rate-80)
    - [Problem: Benchmark dauert >5 Minuten](#problem-benchmark-dauert-5-minuten)
  - [Nächste Schritte](#nchste-schritte)
  - [Checkliste](#checkliste)
  - [Referenzen](#referenzen)

---

## Übersicht

**Dauer:** 30-60 Minuten
**Voraussetzungen:** Keine
**Ziel:** Context factories implementieren und Baseline-Metriken erfassen

---

## Setup (einmalig)

### 1. Benchmarking-System aktivieren

Füge zu deiner `init.lua` hinzu:

```lua
-- Am Ende der Datei
require("benchmarks").setup({
  auto_commands = true,      -- Erstellt :BenchAll, :BenchPhase0, etc.
  default_output = "both",   -- notify + file
  default_format = "markdown",
})
```

### 2. Neovim neu starten

```vim
:qa
nvim
```

---

## Schritt 1: Baseline Benchmark (VORHER)

### Ausführung

Wähle **eine** der folgenden Methoden:

#### Option A: User Command (empfohlen)
```vim
:BenchAutocmdsBaseline
```

#### Option B: Lua direkt
```lua
:lua require("benchmarks.main").autocmds_baseline()
```

#### Option C: Programmierbar
```lua
local results = require("benchmarks.main").autocmds_baseline({
  output = "file",     -- nur Datei, keine notify
  format = "csv",      -- CSV statt Markdown
  verbose = false,     -- keine Konsolen-Prints
})

-- Ergebnisse weiterverarbeiten
print(vim.inspect(results.summary))
```

### Was passiert?

1. **6 Events werden gemessen:**
   - CursorMoved (1000 Iterationen)
   - BufEnter (500 Iterationen)
   - BufWinEnter (500 Iterationen)
   - BufWritePre (200 Iterationen)
   - FileType (200 Iterationen)
   - ColorScheme (100 Iterationen)

2. **Dauer:** ~2-3 Minuten

3. **Outputs:**
   - 📄 Datei: `~/.local/share/nvim/bench_reports/baseline_YYYYMMDD_HHMMSS.md`
   - 🔔 Notify: Zusammenfassung mit Icon
   - 📊 Return-Wert: `Benchmarks.Result` table

### Erwartete Ergebnisse

```
🚀 Running benchmark: Autocmds Baseline
[1/6] Benchmarking CursorMoved (CRITICAL)...
  ✓ Avg: 0.XXXms | Min: 0.XXXms | Max: 0.XXXms
[2/6] Benchmarking BufEnter (HIGH)...
  ✓ Avg: 0.XXXms | Min: 0.XXXms | Max: 0.XXXms
...
📄 Report saved: ~/.local/share/nvim/bench_reports/baseline_20250127_143000.md
✅ Autocmds Baseline
```

### Wichtig: Pfad speichern!

```lua
-- Speichere den Pfad für später
local baseline_path = "~/.local/share/nvim/bench_reports/baseline_20250127_143000.md"
```

---

## Schritt 2: Phase 0 Tests

### Ausführung

```vim
:BenchPhase0
```

Oder:

```lua
:lua require("benchmarks.main").phase0_tests()
```

### Was wird getestet?

1. **Buffer Context Factory**
   - Context creation
   - Cache hit (tick-basiert)
   - Lazy line loading
   - Cache invalidation bei Änderungen
   - Helper methods (`:is_normal()`, `:has_filetype()`)

2. **Window Context Factory**
   - Context creation
   - Visible range calculation
   - Cache working

3. **Cache Infrastructure**
   - Set and get
   - TTL expiration
   - Tick-based invalidation
   - Statistics tracking

4. **Performance Overhead**
   - Direct API vs Context Factory
   - 10.000 Calls gemessen
   - Cache hit rate

### Erwartete Ergebnisse

```
✅ All tests passed!

Buffer Context Cache Stats:
  Hits:          9999
  Misses:        1
  Invalidations: 2
  Total:         10000
  Hit Rate:      99.99%

Context Overhead: -99.0% (FASTER than direct API!)
```

**Interpretation:**
- **Hit Rate >95%**: ✅ Sehr gut
- **Hit Rate 80-95%**: ⚠️ Okay, aber optimierbar
- **Hit Rate <80%**: ❌ Problem, Cache-Logik prüfen

- **Overhead <5%**: ✅ Akzeptabel
- **Overhead <0%** (negativ): 🎉 **Cache macht Code schneller!**

---

## Schritt 3: Ergebnisse dokumentieren

### Baseline-Daten extrahieren

Öffne den Report:

```vim
:e ~/.local/share/nvim/bench_reports/baseline_20250127_143000.md
```

Kopiere die Tabelle:

```markdown
| Event          | Iterations | Avg (ms) | Min (ms) | Max (ms) |
|----------------|------------|----------|----------|----------|
| CursorMoved    | 1000       | 0.672    | 0.598    | 1.234    |
| BufEnter       | 500        | 0.801    | 0.712    | 1.456    |
| ...            | ...        | ...      | ...      | ...      |
```

### Phase 0 Stats speichern

```lua
local stats = require("autocmds.benchmarks.context.buffer").get_stats()
print(vim.inspect(stats))
```

Kopiere das Output:

```lua
{
  hits = 9999,
  misses = 1,
  hit_rate = 99.99,
  total_requests = 10000
}
```

---

## Schritt 4: Commit erstellen

```bash
git add lua/autocmds/benchmarks/
git add benchmarks/
git commit -m "Phase 0: Context factories & baseline benchmarks

Foundation:
- Buffer context with tick-based caching (99.99% hit rate)
- Window context for UI handlers
- Generic cache with TTL/tick invalidation
- Unified benchmark interface (main.lua)

Baseline Results:
- CursorMoved: 0.672ms avg
- BufEnter: 0.801ms avg
- BufWinEnter: 0.543ms avg

Performance:
- Context overhead: -99% (FASTER due to caching!)
- All tests passing (4/4)
"
```

---

## Troubleshooting

### Problem: "Should be normal buffer" Fehler

**Ursache:** Buffer wurde als `scratch` erstellt.

**Fix:** Bereits gefixt in aktualisierter `buffer.lua`. Stelle sicher:

```lua
function ctx:is_normal()
  return self.buftype == "" and self.modifiable
end
```

### Problem: LSP-Warnungen

**Ursache:** Methods als closure statt Funktionen definiert.

**Fix:** Bereits gefixt. Methods sind jetzt:

```lua
function ctx:is_normal()  -- statt: ctx.is_normal = function(self)
```

### Problem: Cache hit rate <80%

**Ursache:** Tick ändert sich zu oft (z.B. durch LSP).

**Debug:**

```lua
-- In buffer.lua, nach `M.get()`:
print(string.format("Buffer %d: tick=%d, cached_tick=%s",
  bufnr, tick, cache[bufnr] and cache[bufnr].tick or "nil"))
```

### Problem: Benchmark dauert >5 Minuten

**Ursache:** Andere Plugins verlangsamen Events.

**Workaround:**

```lua
-- Nur schnelle Events messen
local suite = require("benchmarks.autocmds.baseline_suite")
suite.bench_cursor_moved()  -- einzeln
```

---

## Nächste Schritte

**Nach erfolgreichem Phase 0:**

1. ✅ Baseline-Daten gespeichert
2. ✅ Context factories getestet
3. ✅ Cache funktioniert (>95% hit rate)

**Bereit für Phase 1:**

- Hot Path Dispatcher für `CursorMoved`
- Handler für Git line diff, cword occurrences
- A/B-Benchmark (alt vs neu)

**Kommando:**

```vim
:lua require("benchmarks").phase1_ready()
```

---

## Checkliste

- [ ] Baseline benchmark ausgeführt (`:BenchAutocmdsBaseline`)
- [ ] Report-Pfad gespeichert
- [ ] Phase 0 tests bestanden (`:BenchPhase0`)
- [ ] Cache hit rate >95%
- [ ] Context overhead <5% (oder negativ)
- [ ] Baseline-Tabelle in Docs kopiert
- [ ] Git commit erstellt
- [ ] Bereit für Phase 1

---

## Referenzen

- Context API: `lua/autocmds/benchmarks/context/README.md` (TODO)
- Benchmark API: `benchmarks/README.md` (TODO)
- Phase 1 Preview: `benchmarks/autocmds/docs/PHASE1_ANLEITUNG.md` (folgt)
