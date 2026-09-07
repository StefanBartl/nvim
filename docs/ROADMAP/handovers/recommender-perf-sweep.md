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

- [ ] [buffer-ctx.nvim/lua/buffer_ctx/format/text_width.lua:29](E:/repos/buffer-ctx.nvim/lua/buffer_ctx/format/text_width.lua)
- [ ] [casedesk.nvim/lua/casedesk/registry.lua:60](E:/repos/casedesk.nvim/lua/casedesk/registry.lua)
- [ ] [documentation.nvim/lua/documentation/core/checklist.lua:233](E:/repos/documentation.nvim/lua/documentation/core/checklist.lua)
- [ ] [documentation.nvim/lua/documentation/core/features.lua:162](E:/repos/documentation.nvim/lua/documentation/core/features.lua)
- [ ] [documentation.nvim/lua/documentation/core/lang/python.lua:754](E:/repos/documentation.nvim/lua/documentation/core/lang/python.lua) (2 Treffer in der Datei)
- [ ] [emojis.nvim/lua/emojis/overlay/init.lua:137](E:/repos/emojis.nvim/lua/emojis/overlay/init.lua)
- [ ] [gopath.nvim/lua/gopath/resolvers/common/extractor/find.lua:97](E:/repos/gopath.nvim/lua/gopath/resolvers/common/extractor/find.lua)
- [ ] [insights.nvim/lua/insights/fileinfo/init.lua:37](E:/repos/insights.nvim/lua/insights/fileinfo/init.lua)
- [ ] [insights.nvim/lua/insights/imports/langs/python.lua:54](E:/repos/insights.nvim/lua/insights/imports/langs/python.lua)
- [ ] [lib.nvim/lua/lib/lua/strings/core.lua:176](E:/repos/lib.nvim/lua/lib/lua/strings/core.lua) (`to_camel_case`-artige Wort-Join-Schleife, kleines n)
- [ ] [lib.nvim/lua/lib/nvim/bindings/keymap/modifier/init.lua:110](E:/repos/lib.nvim/lua/lib/nvim/bindings/keymap/modifier/init.lua)
- [ ] [lib.nvim/lua/lib/nvim/fs/mkdirp/init.lua:79](E:/repos/lib.nvim/lua/lib/nvim/fs/mkdirp/init.lua)
- [ ] [lsp.nvim/lua/lsp/tools/deprecated_help/lsp/lua_ls/publish_diagnostics.lua:34](E:/repos/lsp.nvim/lua/lsp/tools/deprecated_help/lsp/lua_ls/publish_diagnostics.lua)
- [ ] [markdown.nvim/lua/markdown/core/table_wrap.lua:203,526,532,541](E:/repos/markdown.nvim/lua/markdown/core/table_wrap.lua) (4 Treffer in einer Datei — vermutlich der lohnendste Einzel-Fix in dieser Liste)
- [ ] [mdview.nvim/lua/mdview/adapter/log.lua:210,214](E:/repos/mdview.nvim/lua/mdview/adapter/log.lua)

Zusätzlich 3 Treffer in TESTS-Dateien (`color_my_ascii.nvim` ×2,
`hover.nvim` ×1) — Test-Fixtures, keine Produktionslast, daher bewusst
nicht in der Liste oben.

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
- [ ] Liste B abgearbeitet (delegierbar)
