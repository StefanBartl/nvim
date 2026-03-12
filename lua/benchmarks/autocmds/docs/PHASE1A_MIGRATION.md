# Phase 1A: FileType Dispatcher Migration Guide

## Table of content

- [Phase 1A: FileType Dispatcher Migration Guide](#phase-1a-filetype-dispatcher-migration-guide)
  - [Zusammenfassung](#zusammenfassung)
  - [Architektur: Vorher vs Nachher](#architektur-vorher-vs-nachher)
    - [VORHER (17 separate Autocmds)](#vorher-17-separate-autocmds)
    - [NACHHER (1 Dispatcher)](#nachher-1-dispatcher)
  - [Migration Steps](#migration-steps)
    - [Schritt 1: Alte Autocmds identifizieren](#schritt-1-alte-autocmds-identifizieren)
    - [Schritt 2: Handler extrahieren](#schritt-2-handler-extrahieren)
    - [Schritt 3: Handler-Modul anpassen (falls nötig)](#schritt-3-handler-modul-anpassen-falls-ntig)
    - [Schritt 4: Alte Autocmds entfernen](#schritt-4-alte-autocmds-entfernen)
  - [Handler-Konfiguration](#handler-konfiguration)
    - [Basis-Handler](#basis-handler)
    - [Mit Priorität](#mit-prioritt)
    - [Einmalig pro Buffer](#einmalig-pro-buffer)
    - [Pattern-Matching](#pattern-matching)
  - [Testing](#testing)
    - [Schritt 1: Unit Tests](#schritt-1-unit-tests)
    - [Schritt 2: Manuelle Verifikation](#schritt-2-manuelle-verifikation)
    - [Schritt 3: A/B Benchmark](#schritt-3-ab-benchmark)
  - [Troubleshooting](#troubleshooting)
    - [Problem: Handler wird nicht ausgeführt](#problem-handler-wird-nicht-ausgefhrt)
    - [Problem: Modul nicht gefunden](#problem-modul-nicht-gefunden)
    - [Problem: Performance schlechter als vorher](#problem-performance-schlechter-als-vorher)
  - [Rollback Plan](#rollback-plan)
  - [Performance-Erwartungen](#performance-erwartungen)
  - [Nächste Schritte nach Phase 1A](#nchste-schritte-nach-phase-1a)
  - [Referenzen](#referenzen)

---

## Zusammenfassung

**Ziel:** 17 separate FileType-Autocmds → 1 zentraler Dispatcher
**Baseline:** 16.922ms avg
**Target:** <5ms avg (70% Reduktion)
**Status:** Implementation complete, ready for testing

---

## Architektur: Vorher vs Nachher

### VORHER (17 separate Autocmds)

```lua
-- autocmds/general/init.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    require("custom.markdown.setup.keymaps").apply(ev.buf)
  end,
})

-- lsp/languages/lua.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function(_)
    -- LSP setup
  end,
})

-- ... 15 weitere FileType Autocmds
```

**Problem:**
- Jedes Autocmd wird separat ausgeführt
- Keine Koordination zwischen Handlern
- Module werden sofort geladen (kein Lazy Loading)
- Schwer zu debuggen

### NACHHER (1 Dispatcher)

```lua
-- autocmds/events/utils/filetype.lua
local handlers = {
  markdown = {
    { load = function() return require("custom.markdown.setup.keymaps") end, priority = 10 },
    { load = function() return require("custom.markdown.setup.usercmds") end, priority = 20 },
  },
  lua = {
    { load = function() return require("lsp.languages.scriipting.lua") end, priority = 10, once = true },
  },
}

-- Nur 1 Autocmd:
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = M.dispatch,
})
```

**Vorteile:**
- ✅ Lazy Loading (Module nur bei Bedarf)
- ✅ Priorisierung (niedrig = früher)
- ✅ `once = true` für einmalige Handler
- ✅ Pattern-Matching (z.B. `"noice*"`)
- ✅ Zentrale Buffer-Context-Nutzung
- ✅ Einfaches Debugging

---

## Migration Steps

### Schritt 1: Alte Autocmds identifizieren

Suche nach:
```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "...",
  callback = function(...)
```

### Schritt 2: Handler extrahieren

**Alt:**
```lua
-- autocmds/general/init.lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    require("custom.markdown.setup.keymaps").apply(ev.buf)
    require("custom.markdown.setup.usercmds").apply(ev)
  end,
})
```

**Neu:**
```lua
-- In autocmds/events/utils/filetype.lua → handlers table:
markdown = {
  {
    load = function() return require("custom.markdown.setup.keymaps") end,
    priority = 10,
  },
  {
    load = function() return require("custom.markdown.setup.usercmds") end,
    priority = 20,
  },
},
```

### Schritt 3: Handler-Modul anpassen (falls nötig)

Der Dispatcher ruft automatisch:
1. `module.apply(ctx, bufnr)` - bevorzugt
2. `module.setup(ctx, bufnr)` - fallback
3. `module(ctx, bufnr)` - wenn Funktion

**Beispiel Handler-Modul:**
```lua
-- custom/markdown/setup/keymaps.lua
local M = {}

function M.apply(ctx, bufnr)
  -- ctx ist BufferContext mit .filetype, .buftype, etc.
  if ctx.buftype ~= "" then return end

  vim.keymap.set("n", "<leader>mp", "...", { buffer = bufnr })
end

return M
```

### Schritt 4: Alte Autocmds entfernen

**WICHTIG:** Erst nach erfolgreichem Test!

```lua
-- autocmds/general/init.lua
-- REMOVE:
-- vim.api.nvim_create_autocmd("FileType", { ... })
```

---

## Handler-Konfiguration

### Basis-Handler

```lua
{
  load = function() return require("module.path") end,
}
```

### Mit Priorität

```lua
{
  load = function() return require("module.path") end,
  priority = 10,  -- Niedrig = früher (default: 100)
}
```

### Einmalig pro Buffer

```lua
{
  load = function() return require("lsp.languages.scriipting.lua") end,
  priority = 10,
  once = true,  -- Nur beim ersten FileType-Event
}
```

### Pattern-Matching

```lua
["noice*"] = {  -- Matcht "noice", "noice-lsp", etc.
  {
    load = function() return require("mappings.noice") end,
  },
},
```

---

## Testing

### Schritt 1: Unit Tests

```lua
:lua require("benchmarks.autocmds.phase1a_tests").run_all()
```

**Erwartete Ausgabe:**
```
✅ All Phase 1A tests passed!
Improvement: 70.5%
Target (<5ms): ✅ MET
```

### Schritt 2: Manuelle Verifikation

```lua
-- Registry anzeigen
:lua require("autocmds.events.utils.filetype").print_registry()

-- Einzelnen Filetype testen
:set filetype=markdown
:messages  -- Keine Fehler?
```

### Schritt 3: A/B Benchmark

```vim
:BenchPhase1A
```

Oder:
```lua
:lua require("benchmarks.main").phase1a_tests()
```

---

## Troubleshooting

### Problem: Handler wird nicht ausgeführt

**Debug:**
```lua
-- In filetype.lua, run_handler() hinzufügen:
print(string.format("[FileType] Running handler for %s", ctx.filetype))
```

**Check:**
```lua
:lua require("autocmds.events.utils.filetype").print_registry()
```

### Problem: Modul nicht gefunden

**Fehler:**
```
[FileType] Failed to load handler: module 'custom.markdown.setup.keymaps' not found
```

**Fix:**
Pfad in `handlers` table korrigieren.

### Problem: Performance schlechter als vorher

**Mögliche Ursachen:**
1. Handler lädt zu viele Submodule
2. `once = true` fehlt bei LSP-Handlern
3. Priorität falsch gesetzt

**Benchmark einzelner Handler:**
```lua
local start = vim.loop.hrtime()
local module = require("custom.markdown.setup.keymaps")
module.apply(ctx, bufnr)
print((vim.loop.hrtime() - start) / 1e6 .. "ms")
```

---

## Rollback Plan

Falls Probleme auftreten:

1. **Dispatcher deaktivieren:**
   ```lua
   -- In init.lua, auskommentieren:
   -- require("autocmds.events.utils.filetype").setup()
   ```

2. **Alte Autocmds reaktivieren:**
   ```lua
   -- Alte Files in autocmds/ uncommenten
   ```

3. **Neovim neu starten**

---

## Performance-Erwartungen

| Metrik | Baseline (Alt) | Target (Neu) | Tatsächlich |
|--------|----------------|--------------|-------------|
| Avg Latenz | 16.922ms | <5ms | [FILL] |
| Handler geladen | 17× sofort | Lazy | [FILL] |
| Startup Zeit | +XYZms | -ABC ms | [FILL] |

---

## Nächste Schritte nach Phase 1A

Nach erfolgreichem Deployment:

- [ ] Phase 1B: BufEnter Dispatcher
- [ ] Phase 1C: CursorMoved Hot Path
- [ ] Finale Benchmarks vs Baseline
- [ ] Dokumentation finalisieren

---

## Referenzen

- FileType Dispatcher: `lua/autocmds/events/utils/filetype.lua`
- Benchmark Suite: `lua/benchmarks/autocmds/phase1a_tests.lua`
- Baseline Report: `[dein Report-Pfad]`
