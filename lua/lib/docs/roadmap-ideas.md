# roadmap-ideas for library

## Table of content

  - [Sinnvolle zusätzliche Lib-Bereiche](#sinnvolle-zustzliche-lib-bereiche)
    - [lib/fs (Dateisystem-/Pfad-Werkzeuge)](#libfs-dateisystem-pfad-werkzeuge)
    - [lib/time (Timer, debounce/throttle, Messungen)](#libtime-timer-debouncethrottle-messungen)
    - [lib/log (leichtgewichtige Logs)](#liblog-leichtgewichtige-logs)
    - [lib/cache (LRU/Memoize)](#libcache-lrumemoize)
    - [lib/async (Jobs, Spawn, Shell)](#libasync-jobs-spawn-shell)
    - [lib/iter (Iteratoren/Generatoren)](#libiter-iteratorengeneratoren)
    - [lib/diag (Diagnostics-Utils rund um LSP/Quickfix)](#libdiag-diagnostics-utils-rund-um-lspquickfix)
    - [lib/ui (Fenster/Buffer/Cursor)](#libui-fensterbuffercursor)
    - [lib/text/markdown (Markdown-spezifisch)](#libtextmarkdown-markdown-spezifisch)
    - [lib/strings/width (Anzeige-Breite)](#libstringswidth-anzeige-breite)
    - [lib/json/yaml (robuste Parser/Serializer)](#libjsonyaml-robuste-parserserializer)
    - [lib/validate (Schemas, Guards – ergänzt utils.normalize)](#libvalidate-schemas-guards-ergnzt-utilsnormalize)
    - [lib/math (kleine Hilfen)](#libmath-kleine-hilfen)
  - [Beispiel-Snippets](#beispiel-snippets)
    - [fs.join/exists](#fsjoinexists)
    - [time.debounce in Autocmds](#timedebounce-in-autocmds)
    - [cache.memoize für teure Pfad-Scans](#cachememoize-fr-teure-pfad-scans)
    - [ui.with_preserved_view](#uiwith_preserved_view)
    - [text.md.link_under_cursor](#textmdlink_under_cursor)

---

## Sinnvolle zusätzliche Lib-Bereiche

### lib/fs (Dateisystem-/Pfad-Werkzeuge)

| Name         | Module      | Signature                                         | Zweck                                    |    |                              |
| ------------ | ----------- | ------------------------------------------------- | ---------------------------------------- | -- | ---------------------------- |
| exists       | lib.fs.core | exists(path: string): boolean                     | Existenztest (Datei/Verz.)               |    |                              |
| kind         | lib.fs.core | kind(path: string): "file"                        | "directory"                              | "" | Typbestimmung via uv.fs_stat |
| join         | lib.fs.core | join(parts: string[]): string                     | Pfade sicher zusammenführen              |    |                              |
| relpath      | lib.fs.core | relpath(path: string, base: string): string       | Relativen Pfad berechnen                 |    |                              |
| scandir      | lib.fs.core | scandir(dir: string, opts?): string[]             | Schnelles rekursives Listing mit Pruning |    |                              |
| tempfile     | lib.fs.core | tempfile(prefix?: string): string                 | Temporäre Datei erzeugen                 |    |                              |
| atomic_write | lib.fs.core | atomic_write(path: string, data: string): boolean | Sicheres Schreiben über Tmp+rename       |    |                              |

### lib/time (Timer, debounce/throttle, Messungen)

|# Name     | Module        | Signature                                         | Zweck                        |
| -------- | ------------- | ------------------------------------------------- | ---------------------------- |
| now_ms   | lib.time.core | now_ms(): integer                                 | Monotone Zeit in ms          |
| debounce | lib.time.core | debounce(fn: fun(...), wait_ms: integer): fun     | Aufrufe bündelt              |
| throttle | lib.time.core | throttle(fn: fun(...), interval_ms: integer): fun | Max. 1× pro Intervall        |
| measure  | lib.time.core | measure(fn: fun()): integer                       | Ausführungszeit in ms        |
| sleep    | lib.time.core | sleep(ms: integer, cb?: fun())                    | Nicht-blockierender uv-Timer |

### lib/log (leichtgewichtige Logs)

| Name       | Module       | Signature                             | Zweck                       |
| ---------- | ------------ | ------------------------------------- | --------------------------- |
| logger     | lib.log.core | logger(name: string, level?: integer) | Logger-Objekt erstellen     |
| set_level  | lib.log.core | set_level(level: integer)             | Level setzen (TRACE..ERROR) |
| fmt        | lib.log.core | fmt(fmt: string, ...): string         | Format-Helfer (sicher)      |
| pipe_to_qf | lib.log.qf   | pipe_to_qf(logger, open?: boolean)    | Logs in Quickfix spiegeln   |

### lib/cache (LRU/Memoize)

| Name      | Module         | Signature                                   | Zweck                    |
| --------- | -------------- | ------------------------------------------- | ------------------------ |
| lru_new   | lib.cache.lru  | lru_new(capacity: integer) → LRU            | O(1)-LRU-Cache           |
| memoize   | lib.cache.memo | memoize(fn: fun(...):T, cap?: integer): fun | Ergebnis-Caching mit LRU |
| ttl_cache | lib.cache.ttl  | ttl_cache(ms: integer): Cache               | Cache mit Ablaufzeit     |

### lib/async (Jobs, Spawn, Shell)

| Name     | Module         | Signature                                    | Zweck                                      |
| -------- | -------------- | -------------------------------------------- | ------------------------------------------ |
| spawn    | lib.async.proc | spawn(cmd: string[], opts?): Result          | uv.spawn Wrapper (stdout/stderr gesammelt) |
| shell    | lib.async.proc | shell(cmdline: string, opts?): Result        | Shell-String → argv → spawn                |
| readall  | lib.async.fs   | readall(path: string): Result                | Asynchron Datei lesen                      |
| writeall | lib.async.fs   | writeall(path: string, data: string): Result | Asynchron Datei schreiben                  |

### lib/iter (Iteratoren/Generatoren)

| Name      | Module        | Signature                                             | Zweck                          |
| --------- | ------------- | ----------------------------------------------------- | ------------------------------ |
| range     | lib.iter.core | range(a: integer, b?: integer, step?: integer) → iter | Zahlenbereich                  |
| lines     | lib.iter.core | lines(s: string) → iter                               | Zeileniterator ohne Allokation |
| zip       | lib.iter.core | zip(a: any[], b: any[]) → iter                        | Paarweises Iterieren           |
| enumerate | lib.iter.core | enumerate(list: any[]) → iter                         | (i, v) Iterator                |

### lib/diag (Diagnostics-Utils rund um LSP/Quickfix)

| Name   | Module        | Signature                         | Zweck                                      |
| ------ | ------------- | --------------------------------- | ------------------------------------------ |
| to_qf  | lib.diag.qf   | to_qf(opts?): nil                 | Workspace-Diagnostik → Quickfix            |
| to_loc | lib.diag.qf   | to_loc(win?: integer, opts?): nil | Buffer-Diagnostik → Loclist                |
| format | lib.diag.fmt  | format(diag): string              | Einzeilige Darstellung (file:lnum:col:msg) |
| filter | lib.diag.core | filter(diags, opts): diags        | Nach Schwere/Namensraum filtern            |

### lib/ui (Fenster/Buffer/Cursor)

| Name                | Module      | Signature                         | Zweck                                |
| ------------------- | ----------- | --------------------------------- | ------------------------------------ |
| save_view           | lib.ui.view | save_view(buf?: integer): token   | Cursor/Viewport sichern              |
| restore_view        | lib.ui.view | restore_view(token): boolean      | Wiederherstellen (validitätsgeprüft) |
| with_preserved_view | lib.ui.view | with_preserved_view(buf, fn): any | Safe Edit mit stabilem View          |
| open_scratch        | lib.ui.buf  | open_scratch(opts?): integer      | Temporären, gelisteten Buffer öffnen |

### lib/text/markdown (Markdown-spezifisch)

| Name              | Module      | Signature                                                       | Zweck                                |                                |
| ----------------- | ----------- | --------------------------------------------------------------- | ------------------------------------ | ------------------------------ |
| toc_scan          | lib.text.md | toc_scan(lines: string[]): {level:int, text:string, lnum:int}[] | TOC aus Überschriften                |                                |
| anchor            | lib.text.md | anchor(text: string): string                                    | Slug-Anchor passend zu deinen Regeln |                                |
| link_under_cursor | lib.text.md | link_under_cursor(buf, row, col): {kind,text,target}            | nil                                  | Link-Erkennung ([], (), ![]()) |

### lib/strings/width (Anzeige-Breite)

| Name          | Module            | Signature                                        | Zweck                                        |                   |                           |
| ------------- | ----------------- | ------------------------------------------------ | -------------------------------------------- | ----------------- | ------------------------- |
| display_width | lib.strings.width | display_width(s: string): integer                | Breite (ostasiatische Breite, Kombinatoren)* |                   |                           |
| truncate      | lib.strings.width | truncate(s: string, w: integer): string          | Hart auf Anzeige-Breite kürzen               |                   |                           |
| pad_display   | lib.strings.width | pad_display(s: string, w: integer, side?: "left" | "right"                                      | "center"): string | Breiten-korrektes Padding |

### lib/json/yaml (robuste Parser/Serializer)

| Name        | Module        | Signature                                     | Zweck                                           |
| ----------- | ------------- | --------------------------------------------- | ----------------------------------------------- |
| encode      | lib.json.core | encode(tbl: table): string                    | Sichere JSON-Serialisierung (Fehler → nil, err) |
| decode      | lib.json.core | decode(s: string): table|nil, string|nil      | Schutz gegen nicht-string/ungültig              |
| yaml_decode | lib.yaml.core | yaml_decode(s: string): table|nil, string|nil | Optional via pcall(require, "lyaml")            |

### lib/validate (Schemas, Guards – ergänzt utils.normalize)

| Name         | Module            | Signature                    | Zweck                                      |
| ------------ | ----------------- | ---------------------------- | ------------------------------------------ |
| guard        | lib.validate.core | guard(tbl, schema): ok, err? | Pflichtfelder, Typen, Wertebereiche prüfen |
| nonempty_str | lib.validate.core | nonempty_str(v): boolean     | Häufige Prädikate                          |
| one_of       | lib.validate.core | one_of(v, list): boolean     | Enum-Prüfung                               |

### lib/math (kleine Hilfen)

| Name  | Module        | Signature                          | Zweck      |
| ----- | ------------- | ---------------------------------- | ---------- |
| clamp | lib.math.core | clamp(n, min, max): number         | Klammern   |
| round | lib.math.core | round(n, digits?: integer): number | Runden     |
| sum   | lib.math.core | sum(nums: number[]): number        | Summe      |
| mean  | lib.math.core | mean(nums: number[]): number       | Mittelwert |

## Beispiel-Snippets

### fs.join/exists

```lua
local FS = require("lib.fs.core")
local path = FS.join({ vim.fn.stdpath("config"), "lua", "plugins" })
if FS.exists(path) then
  -- use it
end
```

### time.debounce in Autocmds

```lua
local T = require("lib.time.core")
local debounced = T.debounce(function() vim.diagnostic.setqflist({ open = false }) end, 200)
vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged" }, { callback = debounced })
```

### cache.memoize für teure Pfad-Scans

```lua
local memoize = require("lib.cache.memo").memoize
local FS = require("lib.fs.core")
local find_types = memoize(function(root) return FS.scandir(root, { match = { "types", "@types" } }) end, 64)
```

### ui.with_preserved_view

```lua
local View = require("lib.ui.view")
View.with_preserved_view(0, function()
  -- heavy edits without jumping the cursor/scroll
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(vim.fn.expand("%:p"), "/"))
end)
```

### text.md.link_under_cursor

```lua
local MD = require("lib.text.md")
local p = MD.link_under_cursor(0, unpack(vim.api.nvim_win_get_cursor(0)))
if p and p.kind == "url" then vim.ui.open(p.target) end
```

# #Hinweise zur Umsetzung

* Halte Module klein und ein-aufgaben-orientiert (core/…, optional weitere Untermodule).
* EmmyLua-Typen zentral in types/ pflegen; überall referenzieren, keine Duplikate.
* Für uv/Neovim-Funktionen stets pcall/Feature-Checks, damit Module auch in Nicht-UI-Kontexten testbar bleiben.
* Für performancekritische Hotpaths Tabellen vorallozieren (`local out = { [n] = false }`) wie bisher.

---
