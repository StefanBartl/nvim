# `:Recommender perf` — Sweep über alle Plugin-Repos

Handover vom 2026-09-07. Ausgangspunkt war dieser Punkt aus dem Chat:

```
- [ ] `:Recommender perf` durch alle Module laufen lassen und Ergebnisse
      sichten. (Ausführen + Sichten = du; die daraus resultierenden Fixes =
      delegierbar, siehe Liste B.)
```

`:Recommender perf` ist eine interaktive Floating-Window-Funktion (siehe
[recommender.nvim/docs/commands.md](E:/repos/recommender.nvim/docs/commands.md))
und lässt sich nicht direkt aus einer Coding-Session heraus "durchklicken".
Stattdessen wurde der Analyzer headless über alle 32 Plugin-Repos laufen
gelassen — mit exakt derselben Funktion, die auch der Live-Command benutzt
(`recommender.analyzers.perf.analyze()`), also 1:1 dieselben Ergebnisse wie
`:Recommender perf 1 cwd` in jedem Repo einzeln.

## Methode

Headless-Skript (`nvim --headless -u NONE -c "luafile ..."`), das:

1. `rtp` um `lib.nvim` und `recommender.nvim` erweitert und
   `recommender.analyzers.perf` direkt requiret (kein `setup()`, keine
   Floating-UI nötig — die Analyse-Funktion ist reines Lua ohne
   Buffer-Abhängigkeit, wenn man ihr `lines` explizit gibt).
2. Pro Plugin-Repo (unter `E:\repos\<name>` bzw. `C:\repos\<name>`) alle
   `*.lua`-Dateien rekursiv einsammelt — Verzeichnisse wie `.git`,
   `.claude/worktrees`, `node_modules`, `dist`, `doc` etc. werden
   übersprungen (dieselbe Ignore-Liste wie `cwd_ignore` in den Recommender-
   Defaults, plus `.claude`/`worktrees`, da einige Repos offene
   Claude-Worktrees mit eigener `lua/`-Kopie haben).
3. Jede Datei mit `perf.analyze(1, {}, {}, lines)` scannt — Threshold `1`,
   also jede einzelne Instanz, wie in der Doku als Beispiel gezeigt.

Ergebnis: [`docs/ROADMAP/handovers/recommender-perf-report.txt`](./recommender-perf-report.txt)
(Rohdaten, 1474 Zeilen) — pro Plugin eine Sektion mit Datei : Pattern : Count.

## Ergebnis in Zahlen

| Pattern | Datei-Treffer (Zeilen im Report) | Einschätzung |
|---|---|---|
| `ipairs(...)` | 1156 | **Nicht umsetzen.** Kommt in praktisch jeder Datei jedes Repos vor — das ist der normale, idiomatische Lua-Stil in der gesamten Plugin-Flotte, kein Ausreißer. Der Perf-Analyzer selbst benennt den Benefit (~2x ggü. `for i=1,#t`), aber ein flächendeckendes Umschreiben von tausenden `ipairs`-Loops würde Lesbarkeit gegen einen Mikro-Gewinn tauschen, der in den allermeisten Fundstellen (UI-Rendering, einmalige Setup-Loops, kleine Listen) von I/O oder Redraw ohnehin überdeckt wird. |
| `table.insert(...)` in Loop | 133 | Größtenteils niedrige Priorität. Vier echte Hotspots mit auffällig hoher Dichte (siehe unten) — dort lohnt ein Blick, der Rest ist Streuung über kleine Loops. |
| `string.format(...)` in Loop | 103 | Gleiche Einschätzung wie `table.insert` — ein Hotspot fällt zusammen mit einem der `table.insert`-Hotspots (siehe unten). |
| `x = x .. y` (Concat-Akkumulator) | 18 | **Das ist die eigentlich interessante Kategorie** — O(n²) statt O(n), mechanischer und risikoarmer Fix (`table.concat` statt Self-Concat). Vollständige Liste unten als "Liste B". |

Alle 32 Repos aus der Plugin-Liste wurden gefunden und gescannt, keine
Lücken. Kein Repo kam "clean" zurück — erwartbar bei der `ipairs`-Dichte.

## Liste B — delegierbare Fixes (Concat-Akkumulator, 18 Fundstellen)

Jede Zeile ist ein `x = x .. y`-Muster *innerhalb einer Schleife* — der
Analyzer filtert bereits die bekannten False-Positive-Formen (Table-Feld
mit gleichem Namen, `local` innerhalb der Schleife neu deklariert). Fix ist
überall gleich: Teile in eine Tabelle sammeln (`t[#t+1] = part`) und einmal
`table.concat(t)` am Ende — mechanisch, risikoarm, keine Verhaltensänderung.

Reale Dringlichkeit schwankt mit der Iterationszahl `n` im jeweiligen
Kontext (z.B. `lib.lua.strings.core` verarbeitet kurze Wortlisten → O(n²)
tut in der Praxis kaum weh; `markdown.nvim`s Table-Wrap oder `mdview`s
Log-Adapter laufen potenziell über viel mehr Zeilen).

- [x] [buffer-ctx.nvim/lua/buffer_ctx/format/text_width.lua:29](E:/repos/buffer-ctx.nvim/lua/buffer_ctx/format/text_width.lua) — **gefixt** (`98a9f70`)
- [x] [casedesk.nvim/lua/casedesk/registry.lua:60](E:/repos/casedesk.nvim/lua/casedesk/registry.lua) — **False Positive, übersprungen** (siehe unten)
- [x] [documentation.nvim/lua/documentation/core/checklist.lua:233](E:/repos/documentation.nvim/lua/documentation/core/checklist.lua) — **gefixt** (`85b1902`)
- [x] [documentation.nvim/lua/documentation/core/features.lua:162](E:/repos/documentation.nvim/lua/documentation/core/features.lua) — **gefixt** (`85b1902`)
- [x] [documentation.nvim/lua/documentation/core/lang/python.lua:345,382](E:/repos/documentation.nvim/lua/documentation/core/lang/python.lua) — **gefixt** (`85b1902`; echte Zeilen waren 345/382, nicht 754 — die ursprüngliche Zeilenangabe im Sweep war ein grep-Artefakt ohne Backreference-Prüfung)
- [x] [emojis.nvim/lua/emojis/overlay/init.lua:137](E:/repos/emojis.nvim/lua/emojis/overlay/init.lua) — **gefixt** (`83d876b`)
- [x] [gopath.nvim/lua/gopath/resolvers/common/extractor/find.lua:97](E:/repos/gopath.nvim/lua/gopath/resolvers/common/extractor/find.lua) — **False Positive, übersprungen** (siehe unten)
- [x] [insights.nvim/lua/insights/fileinfo/init.lua:37](E:/repos/insights.nvim/lua/insights/fileinfo/init.lua) — **gefixt** (`41215fc`)
- [x] [insights.nvim/lua/insights/imports/langs/python.lua:54](E:/repos/insights.nvim/lua/insights/imports/langs/python.lua) — **gefixt** (`41215fc`)
- [x] [lib.nvim/lua/lib/lua/strings/core.lua:176](E:/repos/lib.nvim/lua/lib/lua/strings/core.lua) — **gefixt** (`9338109`)
- [x] [lib.nvim/lua/lib/nvim/bindings/keymap/modifier/init.lua:110](E:/repos/lib.nvim/lua/lib/nvim/bindings/keymap/modifier/init.lua) — **kein Nutzen, übersprungen** (siehe unten)
- [x] [lib.nvim/lua/lib/nvim/fs/mkdirp/init.lua:79](E:/repos/lib.nvim/lua/lib/nvim/fs/mkdirp/init.lua) — **kein Nutzen, übersprungen** (siehe unten)
- [x] [lsp.nvim/lua/lsp/tools/deprecated_help/lsp/lua_ls/publish_diagnostics.lua:34](E:/repos/lsp.nvim/lua/lsp/tools/deprecated_help/lsp/lua_ls/publish_diagnostics.lua) — **False Positive, übersprungen** (siehe unten)
- [x] [markdown.nvim/lua/markdown/core/table_wrap.lua:203,526,532,541](E:/repos/markdown.nvim/lua/markdown/core/table_wrap.lua) — **gefixt** (`9b9494d`)
- [x] [mdview.nvim/lua/mdview/adapter/log.lua:210,214](E:/repos/mdview.nvim/lua/mdview/adapter/log.lua) — **kein Nutzen, übersprungen** (siehe unten)

Zusätzlich 3 Treffer in TESTS-Dateien (`color_my_ascii.nvim` ×2,
`hover.nvim` ×1) — Test-Fixtures, keine Produktionslast, daher bewusst
nicht in der Liste oben.

### Ergebnis: 9 gefixt, 6 bewusst übersprungen

Beim Durcharbeiten stellte sich heraus, dass ein Drittel der Liste keinen
echten Fix verdient — der Analyzer hat hier entweder einen Fehlalarm oder
das Fixen brächte keinen Performance-Gewinn:

**Analyzer-Fehlalarm (3× — der Analyzer selbst hat hier eine Lücke):**

- `casedesk.nvim/registry.lua:60` und `gopath.nvim/find.lua:97`: Beides ist
  ein Tabellenfeld in einem **mehrzeiligen** Tabellen-Konstruktor
  (`{ short = short,\n  dir = dir .. "/" .. short,\n  ... }`), kein
  Self-Reassignment. Der Analyzer verankert die Prüfung korrekt für
  einzeilige Literale (genau dieser Fall ist im Test-Suite abgedeckt:
  `entries[#entries+1] = { short = short, dir = dir .. "/" .. short }`),
  aber sobald jedes Feld auf seiner eigenen Zeile steht, sieht die
  Zeilen-für-Zeilen-Prüfung nur noch `dir = dir .. "/" .. short,` und
  hält das für eine Variablen-Neuzuweisung.
- `lsp.nvim/publish_diagnostics.lua:34`: `d.message = d.message ..
  opts.diagnostic_hint` steht in `for _, d in ipairs(result.diagnostics)
  do`, aber `d` ist bei jeder Iteration ein *anderes* Diagnostic-Objekt —
  das ist ein einmaliger Append pro Element, keine Akkumulation über
  Iterationen hinweg. Die `declared_in_loop`-Prüfung im Analyzer erkennt
  nur `local`-Deklarationen, nicht for-in-Iterator-Variablen.

  → Beide Lücken sind eine Idee für ein Analyzer-Update in
  recommender.nvim selbst, aber out of scope für diesen Sweep.

**Kein echter Performance-Gewinn (3×):**

- `lib.nvim/keymap/modifier/init.lua:110` (`seq`) und
  `lib.nvim/fs/mkdirp/init.lua:79` / `mdview.nvim/adapter/log.lua:210,214`
  (`current`/`cur`): der akkumulierte String wird in **jeder Iteration**
  live gebraucht (`vim.fn.maparg(seq, ...)` bzw. `fs_mkdir(cur, ...)` /
  `fs_stat(cur)`) — nicht erst am Ende. Eine Umstellung auf
  `table.concat` müsste in jeder Iteration erneut aufgerufen werden, um
  denselben String zu bekommen, und wäre dadurch nicht schneller als das
  Original. `seq` ist zusätzlich durch `MAX_SEQ = 8` hart begrenzt.

Die 9 tatsächlichen Fixes ersetzen jeweils `x = x .. y` durch eine
`parts`-Tabelle + einmaliges `table.concat` am Ende — Verhalten
unverändert, per Testsuite (oder manueller Stichprobe, wo keine
dedizierte Testabdeckung existiert) verifiziert. Alle 9 Commits sind
bereits auf `main` in ihrem jeweiligen Repo.

## Sekundäre Hotspots (`table.insert`/`string.format`, nur bei auffälliger Dichte)

Kein Handlungsbedarf per se, aber diese vier Dateien fallen durch
ungewöhnlich viele Treffer in derselben Datei auf und sind ein guter
Startpunkt, falls die Concat-Liste oben durch ist und noch Kapazität da
ist:

- [color_my_ascii.nvim/lua/color_my_ascii/commands/schemes.lua](E:/repos/color_my_ascii.nvim/lua/color_my_ascii/commands/schemes.lua) — 11× `table.insert` in Loop
- [debugging.nvim/lua/debugging/views/capture/init.lua](E:/repos/debugging.nvim/lua/debugging/views/capture/init.lua) — 14× `table.insert` in Loop
- [lsp.nvim/lua/lsp/lspdoctor/health.lua](E:/repos/lsp.nvim/lua/lsp/lspdoctor/health.lua) — 13× `table.insert` in Loop
- [lsp.nvim/lua/lsp/lspdoctor/inspect.lua](E:/repos/lsp.nvim/lua/lsp/lspdoctor/inspect.lua) — 21× `table.insert` **und** 12× `string.format` in Loop (dichtester Einzeltreffer der ganzen Flotte)

## Empfehlung

- **Liste B (Concat-Akkumulator) delegieren** — 15 echte Fundstellen, jede
  ein Zwei-Zeilen-Fix, gut geeignet für eine einzelne Session/Agent-Runde
  über alle Repos hinweg (pro Repo ein Commit, wie gewohnt sofort auf
  `main`).
- **`ipairs` und die restlichen `table.insert`/`string.format`-Streuung
  nicht anfassen** — kein echter Fund, sondern erwartbares Rauschen bei
  dieser Scan-Breite.
- Die vier Hotspot-Dateien oben sind optional, falls noch Lust auf mehr ist.

## Status

- [x] Sweep durchgeführt (2026-09-07), Rohdaten unter
      [`recommender-perf-report.txt`](./recommender-perf-report.txt)
- [x] Ergebnisse gesichtet, Liste B kuratiert
- [x] Liste B abgearbeitet (2026-09-07): 9 Fixes committet + gepusht auf
      main (buffer-ctx.nvim, documentation.nvim, emojis.nvim,
      insights.nvim, lib.nvim, markdown.nvim), 6 Fundstellen bewusst
      übersprungen (3 Analyzer-Fehlalarme, 3 ohne echten Gewinn) — Details
      im Abschnitt "Ergebnis: 9 gefixt, 6 bewusst übersprungen" oben.
