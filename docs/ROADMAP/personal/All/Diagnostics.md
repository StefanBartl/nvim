# Diagnostics -- LSP-Befund über alle Plugins

## Table of content

  - [TASK an Claude delegieren (Claude soll diesen Punkt nicht bearbeiten!)](#task-an-claude-delegieren-claude-soll-diesen-punkt-nicht-bearbeiten)
  - [Letze Task, nachdem alles fertig ist](#letze-task-nachdem-alles-fertig-ist)
  - [Intro](#intro)
  - [0. Stand, Arbeitsmodus, nächster Schritt](#0-stand-arbeitsmodus-nchster-schritt)
    - [Umfang: welche Repos dazugehören](#umfang-welche-repos-dazugehren)
    - [Gerade in Arbeit](#gerade-in-arbeit)
    - [Vorschlag nächster Schritt](#vorschlag-nchster-schritt)
    - [Erledigt](#erledigt)
    - [Stand: der Gesamtlauf vom 2026-09-02](#stand-der-gesamtlauf-vom-2026-09-02)
    - [Offen](#offen)
    - [Arbeitsmodus](#arbeitsmodus)
  - [1. Methode](#1-methode)
  - [2. Gesamtbild pro Repo](#2-gesamtbild-pro-repo)
  - [3. Verteilung nach Regel](#3-verteilung-nach-regel)
  - [4. Die Ursachen-Cluster](#4-die-ursachen-cluster)
    - [A. Fehlender `assert`-Typ in den Tests -- ERLEDIGT 2026-08-31](#a-fehlender-assert-typ-in-den-tests-erledigt-2026-08-31)
    - [B. `need-check-nil` in Tests -- ERLEDIGT 2026-08-31](#b-need-check-nil-in-tests-erledigt-2026-08-31)
    - [C. `missing-fields` -- ERLEDIGT 2026-08-29](#c-missing-fields-erledigt-2026-08-29)
    - [D. `userdata` statt `TSNode` in documentation.nvim -- ERLEDIGT 2026-08-31](#d-userdata-statt-tsnode-in-documentationnvim-erledigt-2026-08-31)
    - [E. `pcall(vim.cmd, ...)` -- 46 offen, lib.nvim und lsp.nvim erledigt](#e-pcallvimcmd-46-offen-libnvim-und-lspnvim-erledigt)
    - [F. `inject-field` (119) -- fast vollständig lib.nvim -- ERLEDIGT 2026-08-31](#f-inject-field-119-fast-vollstndig-libnvim-erledigt-2026-08-31)
  - [5. Die kleinen, echten Befunde](#5-die-kleinen-echten-befunde)
    - [`deprecated` (23) -- veraltete Neovim-APIs](#deprecated-23-veraltete-neovim-apis)
    - [`missing-parameter` (6) -- Aufruf mit zu wenig Argumenten](#missing-parameter-6-aufruf-mit-zu-wenig-argumenten)
    - [`luadoc-miss-symbol` (7) -- kaputte Annotation, Klammer fehlt](#luadoc-miss-symbol-7-kaputte-annotation-klammer-fehlt)
    - [`duplicate-set-field` (8 in `lua/`)](#duplicate-set-field-8-in-lua)
    - [`duplicate-doc-alias` (5) -- derselbe Typname zweimal definiert](#duplicate-doc-alias-5-derselbe-typname-zweimal-definiert)
    - [`unbalanced-assignments` (1)](#unbalanced-assignments-1)
    - [`invisible` (1)](#invisible-1)
    - [`different-requires` (41) -- ausschließlich nvim-Config](#different-requires-41-ausschlielich-nvim-config)
    - [Weitere Annotationsfehler (144)](#weitere-annotationsfehler-144)
  - [6. stylua](#6-stylua)
  - [7. Nebenbefunde](#7-nebenbefunde)
  - [8. Was daraus folgt](#8-was-daraus-folgt)
  - [9. Anhang: der delegierbare Teil des Roadmap-Punkts](#9-anhang-der-delegierbare-teil-des-roadmap-punkts)

---

## TASK an Claude delegieren (Claude soll diesen Punkt nicht bearbeiten!)

In C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/Diagnostics.md: lese dir die ersten punkte durch, arbeitsmodi, nächster empfohlener schritt usw.

comitte und push/pull immer auf main wenn fertig, damit ich es gleich verwenden kann. wenn fertig,  die erledigt task nach C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/Diagnostics_FINISHED.md und den nächsten empfohlenen schritt analysieren - dab ei brauchst du aber nicht begrpnden, welche task du nicht machen würdest.

---

## Letze Task, nachdem alles fertig ist

- [ ] **Vorarbeit liegt vor:** der Abschnitt [„Wiederkehrende Muster -- die
  Ableitung fuer RULES“](./Diagnostics_FINISHED.md#wiederkehrende-muster-die-ableitung-fuer-rules)
  sammelt seit 2026-09-02, was sich ueber die Durchgaenge wiederholt hat --
  nach Haeufigkeit, mit der Signatur zum Wiedererkennen und dem bewaehrten
  Griff. Er wird bei jedem Durchgang fortgeschrieben und ist die Grundlage
  fuer diesen Punkt.
- [ ] Aus C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/Diagnostics_FINISHED.md ableitungen treffen, wie künftiger Repos zb die /TEST/ files geschrieben werden, auf was wier aufpassen  üssen in normalen source code usw... sodass wir dies von anfang an einbauen können. Den Report erstmal nach C:/Users/bartl/AppData/Local/nvim/docs/ROADMAP/personal/All/ schreiben. Außerdem alles was sinnvoll ist in die RULES files in WKDBooks/Development/wkdbook-Lua/Checklists schreiben, dort gibt es als beispiel eine filöe für neue projekte, dort kann man ereinschreiben, wie die /TEST/ aufgebaut sein soll buzw was hier wichtig ist um dieagnsotics zu berücksichtigen usw...

---

## Intro

Ergebnis des Roadmap-Punkts *"`<leader>wq`: alle damit auffindbaren Issues live
durchgehen"* (aus `FINISH/MERGED.md`, Liste A / Live-Testing).

Stand: 2026-08-29. Umfang: die 31 `*.nvim`-Repos der Liste in Abschnitt 0
plus diese nvim-Config -- 32 Workspaces, ~2900 Lua-Dateien. (Die Repos liegen
inzwischen unter `E:/repos`, nicht mehr unter `C:/repos`.)

**Kurzfassung:** 3600 Diagnosen in 742 Dateien -- **alle Severity `Warning`,
kein einziger `Error`**. Etwa die Hälfte davon (1770) liegt in `TESTS/`, nicht
im ausgelieferten Code. Der große Rest zerfällt in sechs Ursachen-Cluster, von
denen vier musterhaft und nicht einzeln zu beheben sind.

Dieses Dokument ist zugleich **Befund und Übergabe**: Abschnitt 0 sagt, was
erledigt ist, was gerade läuft, was offen ist und in welcher Reihenfolge
gearbeitet wird. Wer hier neu einsteigt, liest Abschnitt 0 und kann weiter
machen -- eine separate Handover-Datei gibt es bewusst nicht.

---

## 0. Stand, Arbeitsmodus, nächster Schritt

**Stand: 2026-09-02.** Alles unten Genannte ist in den jeweiligen Repos
committet und auf `main` gepusht.

---

### Umfang: welche Repos dazugehören

**Die Arbeit an diesem Punkt gilt genau diesen 31 Plugins plus dieser
nvim-Config — 32 Workspaces, sonst nichts.** Die Liste ist die Vorgabe, nicht
das, was der Scan findet:

| | | | |
|---|---|---|---|
| `buffer-ctx.nvim` | `cascade.nvim` | `cmdlog.nvim` | `color_my_ascii.nvim` |
| `dap.nvim` | `debugging.nvim` | `diff.nvim` | `documentation.nvim` |
| `emojis.nvim` | `fileops.nvim` | `filetree.nvim` | `github_stats.nvim` |
| `gopath.nvim` | `images.nvim` | `insights.nvim` | `language.nvim` |
| `lib.nvim` | `lsp.nvim` | `markdown.nvim` | `mdview.nvim` |
| `migrate.nvim` | `open.nvim` | `pdfport.nvim` | `pickers.nvim` |
| `recommender.nvim` | `replacer.nvim` | `reposcope.nvim` | `runtime-analysis.nvim` |
| `sandbox.nvim` | `sessions.nvim` | `spotlight.nvim` | *(+ diese nvim-Config)* |

Sie liegen unter `$REPOS_DIR` (hier `E:/repos`).

**Warum das hier steht.** `scripts/luals-scan` sucht Workspaces daran, dass
ein Verzeichnis eine `.luarc.json` hat — nicht an dieser Liste. Unter
`E:/repos` liegt derzeit **ein** Verzeichnis, das eine hat und trotzdem nicht
dazugehört: `neotree-fs-refactor.nvim`. Aus den ursprünglich korrekt
gezählten 32 Workspaces (siehe Intro) wurden im Report dadurch still 33, und
am 2026-09-01 ist es einmal versehentlich mitbearbeitet worden. Das ist der
Fehler, den diese Liste verhindern soll.

Praktisch heißt das:

- Ein Lauf **ohne Repo-Argumente** meldet 33 Workspaces. Einer davon zählt
  nicht; seine Zahl gehört aus jeder Summe heraus.
- Vor einem vertikalen Durchgang: **erst gegen diese Liste prüfen**, dann
  anfangen.
- `learn-cli.nvim` liegt zwar auch unter `E:/repos`, hat aber keine
  `.luarc.json` und taucht im Scan gar nicht erst auf.

---

### Gerade in Arbeit

*Nichts.* **cascade.nvim und diff.nvim stehen auf Null** (32 -> 0 und
31 -> 0, 2026-09-02), damit **neunzehn der 32 Workspaces** im Umfang.

---

### Vorschlag nächster Schritt

**pickers.nvim** (32) und **markdown.nvim** (30) -- die zwei größten
verbliebenen Plugins. markdown ist der ergiebigere Einstieg: es trägt
**sechs der elf verbliebenen `pcall(vim.cmd, ...)`** aus Cluster E und mit
`param-type-mismatch` 16 die höchste Einzelkonzentration aller offenen Repos.

| Repo | gesamt | größte Regeln |
|---|---:|---|
| pickers.nvim | 32 | `param-type-mismatch` 8, `need-check-nil` 6 |
| markdown.nvim | 30 | `param-type-mismatch` 16, `duplicate-set-field` 6 |
| insights.nvim | 29 | `param-type-mismatch` 6, `missing-return-value` 6 |
| *(neun Repos unter 15)* | 61 | `recommender` 12, `reposcope` 9, `color_my_ascii` 8, `debugging` 8, … |

**Die neun kleinen Repos zusammen** (61) sind der andere sinnvolle Zuschnitt:
die Sechser-Runde hat gezeigt, dass fünf Repos in einem Zug gehen (126 -> 0),
weil der Denkanteil pro Ursache nur einmal anfällt und die Ursachen sich
wiederholen.

**Danach die nvim-Config selbst** (120) -- das größte Einzelvorkommen. Es
ist weiterhin bewusst nicht der nächste Schritt: `nvim-config` ist im Scan
immer *die Config, aus der `scan.sh` gestartet wurde*, und es liegen elf
Worktrees darunter. Ein vertikaler Durchgang dort will erst die Frage
geklärt haben, gegen welchen Baum gemessen wird -- siehe „Nicht von Claude
entschieden" unten.

**Die Einstiegs-Checkliste** steht vollständig unter
[„Wiederkehrende Muster“ in `Diagnostics_FINISHED.md`]
(./Diagnostics_FINISHED.md#wiederkehrende-muster-die-ableitung-fuer-rules),
Abschnitt H hat die Reihenfolge. Die vier, die sich zuletzt am häufigsten
ausgezahlt haben:

- **`vim.uv.new_timer()`** -- 21 Stellen in drei Repos; die Frage ist nie, wie
  der Befund weggeht, sondern was die Funktion **ohne** Timer tun soll.
- **Eine Cast-Liste anstelle eines Guards** (A5) -- fünf Stellen allein in
  cascade, und eine davon habe ich beim ersten Durchgang übersehen.
- **`undefined-field` in `lua/`** -- vier verschiedene Ursachen, die im Report
  identisch aussehen: falscher Zugriff, fehlender Typ, **anders heißender
  Typ** (diff.nvim: sieben Befunde an einer Zeile), oder Code, den niemand
  ruft.
- **`health.lua` gegen den Code prüfen** -- in beide Richtungen: eine
  Advice-Liste, die `info`/`ok` wegwerfen (sechs Repos), und ein
  `deprecated`, das der Health-Check noch nicht kennt (diff.nvim).

---
### Erledigt

| # | Punkt | Ergebnis |
|---|---|---|
| DF | **diff.nvim** -- vertikal (2026-09-02) | **31 -> 0**, in zwei Läufen bestätigt, `worse: nothing`, alle Specs grün. **Sieben Befunde an einer Zeile**: `register_shortcuts` war mit `Diff.Config` annotiert, der Typ heißt `DiffNvim.Config` -- ein `undefined-doc-name`, drei `undefined-field` auf Feldern, die es gibt, und ein `param-type-mismatch` beim korrekten Aufrufer. Darüber klebte der ältere Doc-Block derselben Funktion. Dazu `vim.diff` (deprecated zugunsten `vim.text.diff`, README nennt 0.9+): **einmal aufgelöst statt dreimal unterdrückt**, und `health.lua` fragt jetzt nach demselben Paar -- vorher hätte `:checkhealth` „vim.diff is missing“ gemeldet für ein Neovim, auf dem alles läuft. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| CS | **cascade.nvim** -- vertikal (2026-09-02) | **32 -> 0**, in zwei Läufen bestätigt, `worse: nothing`, alle Specs grün. Als flachster Posten angekündigt (14 Test-Doubles) und in der anderen Hälfte nicht flach: ein Doc-Block, den eine **nachträglich dazwischengesetzte Variable** von seiner Funktion abgeschnitten hat, und **fünfmal dieselbe Familie** -- eine Funktion liefert N Werte, der Guard prüft einen, der Rest wird per `---@cast` nachgezogen und einer vergessen. Neuer Musterpunkt A5. Dabei ist mir die fünfte Stelle selbst entgangen, weil der zweite Messlauf gegen eine noch nicht fertige Ausgabe lief (nachgereicht mit `2e66c29`). Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| RP | **replacer.nvim** -- vertikal (2026-09-02) | **32 -> 0**, in zwei Läufen bestätigt, `worse: nothing`, alle Smoke-Suiten grün (155/26/7). Zwölf der 32 kamen aus **einer Klasse, die es nicht gibt** (`RP_HighlightConfig`) -- und beim Definieren fiel auf, dass die zwei Funktionen dahinter **keinen Aufrufer haben**: die Telescope-Anbindung, für die sie geschrieben wurden, ist nie entstanden (nicht gelöscht, als Notiz vermerkt). Dazu ein echter Fehler ohne `deprecated`-Markierung: **`vim.str_utfindex` hat in 0.11 die Signatur getauscht** -- das zweite Argument war der Byte-Index und ist jetzt die Kodierung, `:ReplaceDebug` lief damit auf jedem aktuellen Build in einen Fehler. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| GS | **github_stats.nvim** -- vertikal (2026-09-02) | **31 -> 0**, in zwei Läufen bestätigt, `worse: nothing`, alle 9 Specs grün (108 Fälle). Neun der zehn `need-check-nil` gingen auf zwei `---@return boolean`-Helfer über optionalen Argumenten zurück -- **so eine Funktion verengt nichts**, der Aufrufer indiziert nach dem `if` weiter einen optionalen Wert. Dazu drei ungeprüfte `vim.uv.new_timer()` (drittes Repo in Folge), eine Option, die es gibt und die in keinem Typ stand (`dashboard.menu.enable`), und eine Klasse, die genau für solche Fälle existiert und zurückgefallen war. Nebenbefund: **`scripts/test.sh` ist der erste Test-Runner der Reihe, der es richtig macht** -- siehe Offen-Punkt 13. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| LS | **lsp.nvim** -- vertikal (2026-09-02) | **35 -> 0**, in zwei Läufen bestätigt, `worse: nothing`, alle 23 Specs grün (372 Fälle). Der flachste Posten der Runde und der ergiebigste seit filetree: **drei Befunde waren Bedingungen, die nie etwas ausgeschlossen haben.** `workspace_diagnostics` bewachte sein `didOpen` mit `supports_method("textDocumentSync/openClose")` -- kein Methodenname, sondern ein Capability-Pfad, und Neovim antwortet auf unbekannte Namen mit `true`; `loclist` übergab `win_id`, wo Neovim `winnr` liest; `:LspDoctor` prüfte `publishDiagnosticsProvider`, eine Capability, die es im LSP nicht gibt. Dazu **Offen-Punkt 6 beantwortet** (`LspMod.*` beschreibt nichts, was Neovim nicht führt) und `vim.health.info` zum sechsten Mal. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| LG | **language.nvim** -- vertikal (2026-09-02) | **34 -> 28 -> 0**, in zwei Läufen bestätigt, `worse: nothing`, alle vier Specs grün. Der Einstieg war nicht der geplante: die `.luarc.json` setzte `workspace.library` selbst und warf die Injektion weg -- Cluster L zum **siebten** Mal. LuaLS sah hier kein einziges Plugin, und sieben Befunde waren nur das (`Lib.Keymap.Action`/`.Registered` und vier Feldzugriffe darauf). Danach sechs Ursachen für 28: vier `pcall(vim.cmd, ...)` (Cluster E hier leer), acht ungeprüfte `vim.uv.new_timer()`, eine Mehrfachrückgabe, die alles-oder-nichts ist und als vier Optionals deklariert war (sechs Befunde aus zwei Zeilen), Form A aus Offen-Punkt 3 an beiden hiesigen Stellen -- dabei fiel auf, dass `custom.cmd` mit zwei Parametern deklariert und mit drei gerufen wird. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| IM | **images.nvim** -- vertikal (2026-09-01) | **37 -> 0**, in zwei Läufen bestätigt, `worse: nothing`, alle 23 Specs grün. Zwei echte Fehler: `scale.compute`/`fit_cells` bewachten ihren dokumentierten Rückfall mit `a.width > 0` -- ohne ImageMagick ist das ein Vergleich mit `nil` und damit ein Fehler statt eines Rückfalls, erreichbar über `:Image compare`; und `vim.health.info` warf die drei tesseract-Installationshinweise weg (derselbe Fund zum fünften Mal). Dazu die Klassenfrage dahinter: `Images.Scale.Dims` behauptete zwei Maße, die `info.collect` nur mit ImageMagick liefert -- aufgeteilt in `MaybeDims` und `Dims : MaybeDims`. **LuaLS entscheidet Klassenzuweisbarkeit über den Namen, nicht über die Gestalt.** Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| A | **`assert`-Typ**, und die Library-Auflösung dahinter | **6344 -> 3204** über alle 33 Workspaces. `.luarc.json` ersetzt `workspace.library` komplett, deshalb kam lsp.nvims Injektion in 31 Repos nie an. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| B | **`need-check-nil` in Tests** -- unterdrückt, nicht auszementiert | **3204 -> 2289** über alle 33 Workspaces, `need-check-nil` 1128 -> 208. 19 Repos, 93 Testdateien, je ein Kopf-Kommentar mit Begründung. Die geplante `TESTS/.luarc.json` geht nicht -- LuaLS liest nur die im Wurzelverzeichnis. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| D | **`userdata` statt `TSNode`** in documentation.nvim | **383 -> 155** in dem Repo, `undefined-field` 237 -> 9. 154 Annotationen in 18 Dateien, dazu `uv.uv_tcp_t` in `serve.lua` und eine eigene Klasse für die Fremdbindung in `standalone/`. Keine andere Regel hat sich um einen Zähler bewegt. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V | **documentation.nvim fertig** -- der erste vertikale Durchgang | **155 -> 0**. Dreizehn kleine Ursachen statt einer großen; darunter ein echter Fehler (`vim.health.info` nimmt keine Advice-Liste, zwölf Aufrufe verloren ihre Hinweise) und zwei verwaiste Doc-Blöcke, die am Kommentar der nächsten Funktion klebten. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| C | **`missing-fields`** über alle 31 Plugins + Config | **518 -> 21**, die 21 Reste sind lib.nvims Aggregator-Klassen und gehören zu Cluster F. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| F | **`inject-field` in lib.nvim** -- plus die `missing-fields`-Reste aus C | **381 -> 244** in dem Repo, `inject-field` 108 -> 0, `missing-fields` 22 -> 0. Eine Schreibweise (`---@type` auf einer Tabelle, die erst danach gefüllt wird), drei Ursachen darunter -- acht leere „Zombie“-Klassen hinter einem `return`, durch die die `Lib`-Fassade vier Namespaces untypisiert anbot; elf Module, deren Annotation nur auf der falschen Zeile stand; ein Typ, der schlicht falsch war. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| L | **`$VIMRUNTIME/lua` in sechs `.luarc.json`** -- die Messgrundlage | **356 -> 411** über die sechs. `buffer-ctx`, `emojis`, `fileops`, `gopath`, `lib` und `sessions` setzten `workspace.library` selbst und warfen damit die Injektion weg; `vim` war dort ein Global vom Typ `any`. Der Zuwachs ist der Zweck: 60 Befunde fallen weg, weil Typen auflösen, 119 kommen an Stellen dazu, die vorher niemand geprüft hat -- darunter fünf `deprecated`, die seit dem Erstscan in Abschnitt 5 stehen. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V2 | **lib.nvim fertig** -- der zweite vertikale Durchgang | **273 -> 1**. Zwanzig kleine Ursachen, darunter zwei echte Fehler: `getbufinfo()` liefert kein `filetype` (jede Filetype-Ausschlussliste in `buffer_utils` war wirkungslos) und `page_key` verwarf still die Seitenzahl (alle Seiten eines PDFs teilten sich einen Hover-Cache-Slot). Der eine Rest gehört nach lsp.nvim. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V4 | **filetree.nvim** -- der vierte vertikale Durchgang (2026-09-01) | **161 -> 80**, `worse: nothing`. `undefined-field` 60 -> 9. Der Posten war kein Annotationsproblem: `get_node_at_line` wird von fünf Feature-Modulen gerufen und von keinem Adapter implementiert, also rendern `git_status`, `lsp_diagnostics`, `copy_move`, `search.filter` und `ui.size_info` nie etwas. Dazu ein Wort: `org.session` fragte nach `get_root` statt `get_root_path` und hat jede Session mit `root = nil` gespeichert. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V9 | **open.nvim fertig** -- der achte vertikale Durchgang (2026-09-01) | **48 -> 0**, `worse: nothing`, alle 6 Specs grün. Ungewöhnliche Verteilung: 42 der 48 lagen in `TESTS/`. `viewer.run` nahm `---@param opts table` und liest zwölf Schlüssel daraus -- die Gestalt heißt jetzt `OpenNvim.Viewer.RunOpts`. Die interessantere Hälfte: `usrcmds_spec` setzt seinen Fang vor jedem Fall zurück, und ein zurückgesetztes Local ist für den Prüfer `nil` -- jeder Fall holt ihn sich jetzt mit einem `assert` ab, das beim Bruch den Fall benennt statt drei Zeilen später mit „index a nil value" zu scheitern. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V7 | **pdfport.nvim fertig** -- der siebte vertikale Durchgang (2026-09-01) | **61 -> 0**, `worse: nothing`, alle 7 Specs grün. Achtundzwanzig Befunde waren **eine Zeile**: `util.notify.create` deklarierte seinen Rückgabewert als Inline-Tabellentyp, in dem ein `fun(...): nil` alles nach sich verschluckt -- LuaLS sah nur `info`, und `warn`/`error`/`debug` lasen sich an allen 28 Aufrufstellen als undefiniert. Dazu acht `return`-Zeilen hinter einer `@return`-Annotation, die als zwei gelesen wird, und acht aus zwei gestapelten Doc-Blöcken. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V8 | **neotree-fs-refactor.nvim** -- **gehört nicht zum Umfang**, versehentlich bearbeitet (2026-09-01) | Das Repo steht nicht auf der Plugin-Liste oben; es hat nur eine `.luarc.json` und wurde deshalb vom Scan als Workspace geführt. Der Durchgang ist gemacht und gepusht, zählt aber gegen keine Summe hier. Inhaltlich: **4 -> 0** auf der korrigierten Messgrundlage. Das Repo setzte weiter `workspace.library` selbst, also war hier nie etwas geprüft. Beide Ursachen sind Namenskollisionen (`LogLevel` mit lib.nvims Alias, `Luassert` mit plenarys Klasse), beide reine Annotationen. Nebenbefund: zwei Repos haben keine `stylua.toml`, und `tests/run_tests.sh` meldet Erfolg auch ohne geladenen Harness. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| S6 | **Die Sechser-Runde** -- fünf Repos in einem Zug (2026-09-01) | **126 -> 0** (`buffer-ctx` 5, `sessions` 6, `emojis` 13, `fileops` 35, `gopath` 67), `worse: nothing`, jede Suite grün. Dieselbe Familie wie in filetree: Aufrufe, die nie funktioniert haben können -- fileops' bulk-Tastenkürzel meldete weder Erfolg noch Fehler, sein lockinfo-Kürzel warf statt zu melden, und gopaths `make_result` baute Ergebnisse mit `path = nil` neben `exists = true`. Dazu zwei Annotationen, die nicht parsen und alles unter sich mitnehmen. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V6 | **runtime-analysis.nvim fertig** -- der sechste vertikale Durchgang (2026-09-01) | **109 -> 0**, `worse: nothing`, alle 25 Specs grün. Vier Posten mit je einer Ursache: `vim.health.info` nimmt keine Advice-Liste (derselbe echte Fehler wie in documentation.nvim, vier Hinweise fielen weg), `uv_tcp_t` heißt `uv.uv_tcp_t` (25 Befunde an einem falschen Präfix), `_cache_opts`/`_snapshot_retention` waren nirgends deklariert (12), und neun `pcall(vim.cmd, ...)`. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V5 | **filetree.nvim fertig** -- der fünfte vertikale Durchgang (2026-09-01) | **80 -> 0**, `worse: nothing`. Der Config-Split war der vorgeschlagene Einstieg und trug 24; die interessante Hälfte waren vier Stellen, die nie gelaufen sein können -- `find_files` bewachte sein Reveal mit einem Adapter-Member, das es nicht gibt (`reveal_on_open` deckte nie etwas auf), `live_search` las `node.line` statt `node.line_number` (die Overlay-Suche hob nie etwas hervor), `preview`s snacks-Backend rief ein `snacks.image.open()`, das es nicht gibt, und `refs`' Provider-Klasse kannte zwei Felder nicht, die zwei Provider setzen. Dazu Cluster E komplett (15). Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V3 | **lsp.nvim fertig** -- der dritte vertikale Durchgang (2026-09-01) | **172 -> 35**, `worse: nothing`. Die interessante Hälfte waren Annotationen auf Typen, die es im Repo nicht gibt und die gegen eine alte Kopie seiner selbst auflösten. Darunter ein echter Fehler: `client.notify(...)` statt `client:notify(...)` -- `:LspLuaLsReload` hat die Settings aktualisiert und den Server nie benachrichtigt. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| G | **Gesamtlauf über alle 33 Workspaces** (2026-09-01) | **1254**, der erste Lauf auf der korrigierten Messgrundlage. Ersetzt die fortgeschriebene 1353. Verteilung und Tabelle oben unter „Stand“. Der Lauf umfasste 33 Workspaces, davon 32 im Umfang; `neotree-fs-refactor.nvim` steuerte damals 0 bei, die Summe ist also unberührt |
| M2 | **`workspace.ignoreDir` in elf `.luarc.json`** (2026-09-01) | **495 -> 483** ueber die elf, `worse: nothing`. Neun Repos nennen den Schluessel nicht mehr, filetree.nvim und die Config haben `**/.claude` ergaenzt (ihre `docs`-Ausschluesse sind gewollt). Der erwartete grosse Gewinn kam nicht: die 180 waren lsp.nvim-spezifisch, weil nur dort eine alte Kopie *desselben* Plugins herumlag. Bleibt trotzdem richtig -- die `.luarc.json` warfen 124 injizierte Muster fuer nichts weg, teils fuer Verzeichnisse, die es gar nicht gibt |
| M | **Die Messgrundlage, zweiter Teil** (2026-09-01) | `${3rd}/luassert` fehlte in der Injektion, und `workspace.ignoreDir` wurde von der Messreihe gar nicht gesetzt. Letzteres liess LuaLS elf Config-Kopien unter `.claude/worktrees/` mitlesen, eine davon mit einem `lua/lsp/**` von vor der Extraktion: **180 von lsp.nvims 359 Befunden** waren Kollisionen des Repos mit einer alten Kopie seiner selbst. lsp.nvim **359 -> 172**, lib.nvim **1 -> 0**. Details unten unter „Offen“ und in [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| S | **spotlight.nvim** -- vertikal | **37 -> 0**, in zwei Läufen bestätigt. Dreizehn Befunde steckten in `workspace.library`, sieben in einem Doc-Block, der vierzig Zeilen zu weit oben stand, zwei in Signaturen, die ihre eigene Funktion falsch beschrieben. Der Scan meldete zwischendurch 386 -- eine Gegenprobe im laufenden Server hat 346 davon als Werkzeug-Artefakt entlarvt. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| M | **mdview.nvim** -- vertikal | **44 -> 0**, in zwei Läufen bestätigt. Der Prozess-Zustand war dreimal beschrieben und zweimal falsch; alle zehn `need-check-nil` waren zwei ungeprüfte libuv-Aufrufe; wieder zwei verirrte Doc-Blöcke. Dazu ein Fund neben der Zählung: der Test-Harness ersetzt das globale `assert` durch eine Fassung, die ihren Wert nicht zurückgibt. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| G | **Gesamtlauf auf der korrigierten Messgrundlage** | **1254 -> 570**, davon nur 93 gearbeitet. Elf Repos standen in der Tabelle auf Null, während der Rohlauf für sie zusammen 500 führte -- Phantome aus den fremden `TESTS/`-Verzeichnissen. Die Tabelle unten ist wieder gemessen. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| SB | **sandbox.nvim** -- vertikal | **39 -> 0**, in zwei Läufen bestätigt. Fünf Ports fanden ihre eigenen Parameter nicht (`_on_line` gegen `@param on_line`), fünf verirrte Doc-Blöcke, `WslEngine` deklarierte vier von neun Methoden. Dazu ein echter Bug, den die Typen gefunden haben: eine verschachtelte Tastenliste in `list_actions`. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| 6 | **stylua** | alle 4 abweichenden Dateien formatiert, mdview auf `Spaces`/`2` umgestellt |
| 7 | **Claude-Worktree in open.nvim** | entfernt, `.claude/` dort gitignored |
| 9 | **`lib.nvim.ui.list`** | gebaut, 20 Aufrufstellen in 12 Repos umgestellt |

---

### Stand: der Gesamtlauf vom 2026-09-02

Vollständig **gemessen**, nicht fortgeschrieben -- der erste Lauf über alle
33 Workspaces auf der korrigierten Messgrundlage (`dump_library.lua` trägt
`<plugin>/lua` statt der Repo-Wurzel). Gegen diese Summe rechnet ab jetzt
alles; ältere Zahlen sind mit ihr nicht vergleichbar.

| Repo | gesamt | die zwei größten Regeln darin |
|---|---:|---|
| nvim-config | 120 | `param-type-mismatch` 38, `need-check-nil` 17 |
| pickers.nvim | 32 | `param-type-mismatch` 8, `need-check-nil` 6 |
| markdown.nvim | 30 | `param-type-mismatch` 16, `duplicate-set-field` 6 |
| insights.nvim | 29 | `param-type-mismatch` 6, `missing-return-value` 6 |
| *(neun Repos unter 15)* | 61 | `recommender` 12, `reposcope` 9, `color_my_ascii` 8, `debugging` 8, `dap` 6, `filetree` 6, `cmdlog`/`migrate`/`runtime-analysis` je 4 |
| *(neunzehn Repos auf Null)* | **0** | buffer-ctx, **cascade**, **diff**, documentation, emojis, fileops, github_stats, gopath, images, language, lib, lsp, mdview, open, pdfport, replacer, sandbox, sessions, spotlight |
| **Summe (alle 32 im Umfang)** | **272** | |

Die Summe ist die 570 des Laufs minus die 64, die sandbox darin noch trug,
minus die 37 von images, minus die 34 von language, minus die 35 von
lsp, minus die 33 von github_stats, minus die 32 von replacer, minus die
32 von cascade und die 31 von diff -- alle acht stehen inzwischen auf 0. Bei language waren es auf korrigierter Messgrundlage nur
28 und bei github_stats 31 statt 33; die Summe rechnet mit den geführten
Zahlen, weil die übrigen Zeilen dieser Tabelle ebenfalls auf der jeweils
eigenen Grundlage stehen. **Wo ein Repo
`workspace.library` noch selbst setzt, ist seine Zahl mit Vorsicht zu lesen.** Die Zeile der
kleinen Repos stand vorher auf „sieben Repos / 49"; die neun Zahlen daneben
ergeben 61, und die Summe rechnete immer schon mit 61. Korrigiert, nicht neu
gemessen.

**Die Verteilung hat sich verschoben.** `param-type-mismatch` bleibt die
größte Regel (164), `duplicate-set-field` steht auf **60** und damit weiter an
zweiter Stelle -- fast durchweg Test-Doubles über typisierte
`vim.*`-Oberfläche. images hat die Frage beantwortet, die dazu offen war: von
seinen zehn waren neun Doubles in `TESTS/`, unterdrückt mit einer Begründung
daneben, und die Arbeit daran war ein Bruchteil des Durchgangs. **Der Posten
fällt vertikal an und braucht keinen eigenen horizontalen Durchgang.**

---

### Offen

Reihenfolge wie in Abschnitt 8, dazu die Nachträge aus der B-Runde und dem
Messgrundlagen-Durchgang. **Alle Zahlen aus dem gemessenen Gesamtlauf vom
02.09.**, sandbox danach um den `vim.cmd`-Stub bereinigt. Kurz:

1. **markdown.nvim** (30) oder **pickers.nvim** (32) -- vorgeschlagener
   nächster Schritt, siehe oben. markdown trägt **sechs der elf
   verbliebenen `pcall(vim.cmd, ...)`** und mit `param-type-mismatch` 16 die
   höchste Einzelkonzentration. Alternativ **die neun kleinen Repos in einem
   Zug** (61 zusammen), wie in der Sechser-Runde
1c. **Neun rote Tests in sandbox.nvim** -- `init_spec` 4,
   `project_config_spec` 4, `run_argv_spec` 1. Bestand, nicht aus dem
   Durchgang (gegengeprüft auf `94193cd`). **Und der Runner merkt es
   nicht:** `PlenaryBustedDirectory` hat headless unter Windows 2 von 13
   Spec-Dateien abgearbeitet und sich sauber beendet -- dieselbe Falle wie
   in Offen-Punkt 13, hier aber im Umfang. Der Runner ist das größere der
   beiden Probleme
1b. **`duplicate-set-field` steht auf 30** und damit weiter an zweiter Stelle
   der Gesamtverteilung -- fast durchweg Test-Doubles über typisierte
   `vim.*`-Oberfläche. Häufungen: `cascade` 14, `diff` 11, `filetree` 6,
   `markdown` 6. **Entschieden am images-Durchgang: fällt vertikal an.** Neun
   der zehn dort waren Doubles in `TESTS/`, unterdrückt mit Begründung; das
   kostet pro Repo Minuten und rechtfertigt keinen eigenen horizontalen Lauf
2. **Die nvim-Config selbst** (120) -- das größte Einzelvorkommen;
   `param-type-mismatch` 38, `need-check-nil` 17. Braucht vorher die
   Worktree-Frage unten
3. **Drei Stellen der zwei Annotationsformen**, alle drei in der
   nvim-Config. Form A (ein `fun(...): T` im Tabellentyp, auf das noch ein
   Feld folgt): `nvim/lua/config/snacks/picker/init.lua` Zeile 25 und 45.
   Form B (`@return <typ>  <wort>,` ohne Namen):
   `nvim/lua/bindings/usrcmds/case/extract/doclinks.lua:25`. Fällt beim
   jeweiligen Repo an -- als eigener Durchgang zu klein. **Die beiden
   language-Stellen sind erledigt** (2026-09-02): sie kosteten dort einen
   `undefined-field` und verbargen nebenbei, dass `custom.cmd` mit zwei
   Parametern deklariert und mit drei gerufen wird
4. **`get_node_at_line` und die drei anderen Adapter-Fähigkeiten** --
   deklariert, von keinem Backend implementiert, und fünf Features warten
   darauf. neo-tree und nvim-tree führen interne Zeilenindizes, oil und netrw
   müssten ihren eigenen Puffer parsen: eine Designfrage, keine Aufräumarbeit.
   **Entscheidung offen**, siehe [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md)
5. ~~**`luassert`s Assertionen in lib.nvim weiter aufweiten**~~ --
   **gegenstandslos, nachgemessen 2026-09-02.** Die Zahlen des Punkts stimmen
   aufs Wort (`are.equal` 237, `are.same` 97, davon 102 Aufrufe **mit**
   Failure-Message, also genau die Form, die laut der Typdatei
   `redundant-parameter` auslöst) -- nur löst sie keinen aus. Im gemessenen
   Lauf steht `redundant-parameter` über lsp.nvim auf **eins**, und das ist
   `health.lua`. Seit `${3rd}/luassert` in der Injektion liegt
   (Erledigt-Punkt M) ist der Zustand weg; die Aufweitung hätte die Zahlen
   keines Repos verändert
6. ~~**`LspMod.*` gegen Neovims eigene LSP-Typen**~~ -- **beantwortet und
   erledigt 2026-09-02.** Die Frage war, ob `LspMod.*` noch etwas beschreibt,
   das Neovim nicht führt. Feld für Feld nachgesehen: **nein**, in allen
   sechs Fällen (`Client`, `Client.Capabilities`, `TextDocumentIdentifier`,
   `Position`, `Range`, `CodeAction.Params`), und Neovims Fassungen sind
   präziser. Ein zweiter Name ist dabei nicht gratis: LuaLS entscheidet
   Klassenzuweisbarkeit über den **Namen**, nie über die Gestalt -- ein
   `LspMod.Client` ist aus einem `vim.lsp.Client` grundsätzlich nicht
   zuweisbar. Nebenbefund: `publishDiagnosticsProvider` in
   `LspMod.Client.Capabilities` war eine **erfundene** Capability, und
   `:LspDoctor` hat sie abgefragt
7. **`pcall(vim.cmd, ...)`** (E) -- **11 offen**: `markdown` 6, dazu je eines
   in `color_my_ascii`, `mdview`, `migrate` und zwei in der nvim-Config.
   Erledigt sind 68 (lib 10, lsp 4, filetree 15, fileops 16, sessions 4,
   runtime-analysis 9, gopath 2, images 2, language 4, emojis 1, open 1)
   -- die 60 aus dem Erstscan waren eine Schätzung. Mechanisch, fällt beim
   jeweiligen Repo an. **`vim.cmd` ist nicht die einzige `__call`-Tabelle:**
   in lsp.nvim trug `pcall(vim.lsp.config, ...)` denselben Befund mit
   demselben Wortlaut. Wer nach dem Cluster sucht, sucht nach
   `Cannot assign 'table' to parameter 'fun(...any):...unknown'`, nicht nach
   `vim.cmd`. **Nicht blind auf `vim.cmd.<name>` umschreiben:** in
   images tauscht ein Spec `vim.cmd` selbst und liest den Kommandonamen aus
   dem ersten Argument -- die Unterkommando-Form hätte den Test still blind
   gemacht. Die Closure-Form ist die sichere
8. **Die Einzelbefunde** aus Abschnitt 5 -- der inhaltlich interessante Teil;
   der Anteil der elf durchgegangenen Repos daran ist erledigt
9. **Die verbliebenen `need-check-nil` in `lua/`** -- die sind echt: ein
   `string|nil` wird ungeprüft weitergereicht. Fällt beim jeweiligen Repo an,
   nicht als eigener Durchgang
10. ~~**`scripts/luals-scan` dumpt die falsche Library-Funktion**~~ --
   **erledigt 2026-09-01** beim spotlight-Durchgang, wo es vom Kosmetischen
   ins Blockierende kippte: die Repo-*Wurzeln* aus dem `runtimepath` brachten
   die `TESTS/` aller Plugins mit, und ein `require("harness")` fand 21
   Kandidaten. Der Dump trägt jetzt `<plugin>/lua` ein, wie lazydev es tut.
   346 Phantombefunde weg -- und filetree.nvim ist dabei von 0 auf 6
   gesprungen, siehe 1b
11. **Die drei Aggregator-Strategien von lib.nvim decken sich nicht** -- `lazy`
   exportiert neun Schlüssel, die `metatable` (die Voreinstellung) nicht kennt;
   `eager` nennt `augroup` `autogroup` und mutiert beim Aufbau die Modultabelle
   von `lib.lua.json`. Kein LuaLS-Befund, aufgefallen bei Cluster F
12. **Zwei Repos ohne `stylua.toml`** -- `neotree-fs-refactor.nvim` und
    `learn-cli.nvim`, **beide ausserhalb des Umfangs**; alle 31 Plugins der
    Liste haben eine. Ohne Konfiguration formatiert stylua mit **Tabs**, beide
    Repos sind aber zweispaltig eingerückt, ein `stylua .` schreibt dort also
    das ganze Repo um. Aufgefallen am 2026-09-01, nicht angefasst -- eine
    Formatierungsentscheidung, kein Diagnose-Befund
13. **Test-Runner melden fehlende Voraussetzungen nicht** -- am 2026-09-02
    in lsp.nvim auf eine konkrete Ursache zurückgeführt, und damit kein
    Windows-Problem mehr. `TESTS/minimal_init.lua` löst plenary und lib.nvim
    über `PLENARY_PATH`/`LIB_NVIM_PATH` auf; ohne sie lädt
    `runtime plugin/plenary.vim` nichts, `PlenaryBustedFile` existiert als
    Kommando nicht, und **headless nvim meldet das nicht, es wartet** --
    sieben Minuten ohne ein Byte Ausgabe. Mit gesetzten Variablen laufen die
    23 Specs durch (372 Fälle, 0 Fehler). Der gemeinsame Nenner mit
    neotree-fs-refactor (dort: "All tests passed" **ohne** geladenen Harness)
    ist nicht das Betriebssystem, sondern dieselbe Lücke an derselben Stelle:
    beide Male sieht das Ergebnis aus wie "die Tests laufen gerade". **Ein
    Runner gehört so gebaut, dass ein fehlender Harness scheitert und nicht
    wartet oder grün meldet** -- der Rest von neotree-fs-refactor liegt
    weiterhin ausserhalb des Umfangs.
    **Die Vorlage dafür liegt seit dem 2026-09-02 vor:**
    `github_stats.nvim/scripts/test.sh` mit `scripts/minimal_init.lua` sucht
    plenary an drei Orten (`$PLENARY_DIR`, `.deps/`, daneben), meldet beim
    Scheitern alle drei -- *"Set PLENARY_DIR, or clone it to
    .deps/plenary.nvim, or place it beside this repo"* -- und **endet mit
    Exit-Code 1**. Das ist die Fassung, gegen die die anderen beiden zu
    messen sind, und die Vorlage für die RULES-Ableitung der Abschluss-Task
14. Der Rest der Verteilung (`param-type-mismatch`, `assign-type-mismatch`,
    Annotationsfehler)

**Nicht von Claude entschieden:** die elf git-Worktrees unter
`C:/Users/bartl/AppData/Local/nvim/.claude/worktrees/`. Einer davon
(`filetree-statusline-modes-c96cc9`) trägt noch ein `lua/lsp/**` aus der Zeit
vor der Extraktion von lsp.nvim und ist die Quelle der 180. Mit dem
injizierten `ignoreDir` sind sie für LuaLS unsichtbar, das Problem ist also
entschärft; ob die veralteten weg sollen, ist eine Aufräumfrage und keine
Messfrage.

---

### Arbeitsmodus

**Vertikal, ein Repo nach dem anderen** -- nicht mehr ein Punkt quer über alle
Repos. Begründung: der Denkanteil pro Cluster fällt nur einmal an (bei C waren
das die Werkzeuge und die Entscheidung, wann welches Muster gilt), der
Overhead pro Repo dagegen -- Scan davor, Scan danach, Testsuite, Commit --
fällt horizontal **pro Punkt** an, vertikal nur **einmal für alle Punkte**. Bei
den verbliebenen Clustern (D, E, F plus die Einzelbefunde) ist das grob Faktor
4 bis 5.

**Zwei Ausnahmen liefen vorher horizontal**, weil sie die Zahlen aller anderen
Repos verändern: das `assert`-Meta (A) und die Entscheidung zu
`need-check-nil` in Tests (B) -- solange die drin sind, geht man in jedem Repo
dieselbe Phantomliste durch. Beide sind seit dem 2026-08-31 erledigt, damit
gilt ab jetzt nur noch der vertikale Modus.

Regeln, die sich in Cluster C bewährt haben und weiter gelten:

- **Messen statt schätzen.** Pro Repo ein Scan vor und nach der Änderung, und
  der Vergleich zeigt *alle* Regeln, nicht nur die bearbeitete. Bei C hat genau
  das sechs Repos davor bewahrt, Warnungen gegen neue einzutauschen. Das
  Werkzeug dafür liegt seit 2026-08-31 fest im Repo:
  [`scripts/luals-scan/`](../../../../scripts/luals-scan/README.md) --
  `scan.sh before <repo>`, ändern, `scan.sh after <repo>`,
  `compare.py before after`.
- **Ein Nachher-Lauf beweist keine Null.** Bei pdfport.nvim tauchte ein
  Befund in einer **unveränderten** Datei erst im dritten Lauf auf, als die
  anderen weg waren. Der Vergleich sagt zuverlässig, ob etwas *schlechter*
  wurde; „0" beim ersten Versuch kann dagegen heißen, dass ein Befund noch
  nicht an der Reihe war. Bei einem Ergebnis von 0 also zweimal messen.
- **Kein Fix, der eine Warnung nur verschiebt.** Wenn eine Änderung anderswo
  neue Befunde erzeugt, ist sie unfertig -- entweder das Muster wechseln oder
  die Folgestelle mitreparieren.
- **Testsuite pro Repo laufen lassen**, bevor committet wird.
- **Ein Commit pro Repo und Thema**, direkt gepusht, damit die Repos
  durchgehend benutzbar bleiben.
- **Unterdrückung braucht eine Begründung im Code.** `---@diagnostic disable`
  nur, wo der Befund sachlich falsch ist (Upstream-Meta) oder das Verhalten
  Absicht ist (Test-Doubles, absichtlich ungültige Eingaben) -- und dann mit
  einem Satz, der sagt warum.
- **Erledigtes wandert nach `Diagnostics_FINISHED.md`**, mit dem, was dabei
  interessant war. Dieses Dokument bleibt der Stand des Offenen.

---

## 1. Methode

`<leader>wq` ist `lsp.bindings.actions.diag_to_qflist` ->
`lsp.diagnostics.quickfix.to_qf({open=true})` -> `vim.diagnostic.setqflist()`,
also **alle Diagnosen aller geladenen Buffer**, in der Praxis kombiniert mit
`lsp.core.workspace_diagnostics`, das beim Attach die Repo-Dateien nachlädt.
Das Äquivalent ohne laufende Session ist `lua-language-server --check` pro Repo.

Damit der Befund dem entspricht, was der Editor tatsächlich zeigt, wurde die
Prüf-Config pro Repo aus drei Quellen zusammengesetzt:

1. die `.luarc.json` des Repos (alle 31 haben eine),
2. das, was `lsp.nvim` zur Laufzeit injiziert und *nicht* in der `.luarc.json`
   steht -- `library_profiles.build_runtime_library()` hängt `$VIMRUNTIME/lua`,
   `${3rd}/luv/library` und `${3rd}/busted/library` an (11 der 31 `.luarc.json`
   führen `$VIMRUNTIME/lua` selbst nicht),
3. die Cross-Repo-Typen, die lazydev live nachzieht: für jedes Repo die
   `lua/`-Verzeichnisse aller Repos, die es (transitiv) `require`t.

Punkt 3 wurde gegengeprüft: ein Lauf mit 1+2 allein ergab 4139 Warnungen über
die 31 Repos, mit Punkt 3 dazu 3781. Die Differenz sind Phantom-Befunde --
davon allein ~220 `undefined-doc-name` auf `Lib.*`-, `RA.*`- und
`Documentation.*`-Typen, die es im Editor nie gibt, weil lazydev sie dort
auflöst. Punkt 2 ist nicht separat gemessen, aber ohne ihn hätten 11 der 31
Repos überhaupt keine `vim.*`-Typen.

Kommandozeile pro Repo:

```
PC:
lua-language-server --check "E:/repos/<repo>" --checklevel=Warning --check_format=json --check_out_path=<out>.json --configpath=<merged>.json

workstation/laptop:
lua-language-server --check "E:/repos/<repo>" --checklevel=Warning --check_format=json --check_out_path=<out>.json --configpath=<merged>.json
```

Laufzeit gesamt: rund 10 Minuten. LuaLS 3.18.2-dev, Neovim 0.12.2.

**Die Messung rauscht.** Zwei Läufe über denselben unveränderten Stand
unterscheiden sich um einige Zähler, `param-type-mismatch` ist der unruhigste
Posten: pdfport.nvim, in der B-Runde nicht angefasst, kam einmal mit -7 und
einmal mit +7 zurück. Ein Delta unter etwa 10 in einem einzelnen Repo ist ohne
Gegenprobe nicht belastbar, und zwar in beide Richtungen --
`scripts/luals-scan/compare.py` markiert solche Deltas deshalb, statt sie als
Ergebnis zu melden.

**Grenze der Methode.** `--checklevel=Warning` erfasst `Error` + `Warning`.
`Hint`/`Information` (ungenutzte Locals, fehlende Felder in Hover-Doku) sind
bewusst draußen -- die zeigt `<leader>wq` zwar auch, sie sind aber keine
Fehlerklasse.

**Korrektur (2026-09-01).** Hier stand, LuaLS indiziere Punkt-Verzeichnisse
nicht, `.claude/` und `.git/` blieben also außen vor. Das gilt für den
*Workspace*, nicht für die *Library*: der Config-Root ist für jedes Repo ein
Library-Eintrag, und dessen `.claude/worktrees/` wurde mitgelesen -- elf
Kopien der Config, eine davon mit einem `lua/lsp/**` aus der Zeit vor der
Extraktion von lsp.nvim. Draußen bleiben sie erst durch das injizierte
`workspace.ignoreDir`, das die Messreihe bis dahin gar nicht gesetzt hat.
Allein in lsp.nvim waren das 180 von 359 Befunden.

---

## 2. Gesamtbild pro Repo

| Repo | gesamt | `lua/` | `TESTS/` | Rest |
|---|---:|---:|---:|---:|
| documentation.nvim | 753 | 326 | 405 | 22 |
| lib.nvim | 532 | 304 | 226 | 2 |
| filetree.nvim | 314 | 142 | 172 | 0 |
| runtime-analysis.nvim | 271 | 50 | 220 | 1 |
| lsp.nvim | 233 | 132 | 100 | 1 |
| nvim-config | 185 | 183 | 0 | 2 |
| spotlight.nvim | 157 | 14 | 143 | 0 |
| mdview.nvim | 115 | 91 | 24 | 0 |
| gopath.nvim | 107 | 63 | 1 | 43 |
| open.nvim | 106 | 8 | 98 | 0 |
| pdfport.nvim | 106 | 80 | 26 | 0 |
| github_stats.nvim | 93 | 27 | 66 | 0 |
| markdown.nvim | 71 | 15 | 56 | 0 |
| sandbox.nvim | 70 | 44 | 26 | 0 |
| diff.nvim | 62 | 12 | 50 | 0 |
| replacer.nvim | 60 | 30 | 30 | 0 |
| images.nvim | 46 | 22 | 23 | 1 |
| fileops.nvim | 40 | 33 | 7 | 0 |
| language.nvim | 40 | 36 | 4 | 0 |
| pickers.nvim | 39 | 32 | 7 | 0 |
| cascade.nvim | 35 | 17 | 18 | 0 |
| insights.nvim | 31 | 26 | 5 | 0 |
| emojis.nvim | 28 | 10 | 18 | 0 |
| sessions.nvim | 23 | 13 | 10 | 0 |
| debugging.nvim | 17 | 6 | 11 | 0 |
| recommender.nvim | 15 | 6 | 9 | 0 |
| dap.nvim | 14 | 7 | 7 | 0 |
| reposcope.nvim | 10 | 5 | 5 | 0 |
| color_my_ascii.nvim | 9 | 8 | 1 | 0 |
| buffer-ctx.nvim | 8 | 6 | 2 | 0 |
| migrate.nvim | 6 | 6 | 0 | 0 |
| cmdlog.nvim | 4 | 4 | 0 | 0 |
| **Summe** | **3600** | **1758** | **1770** | **72** |

Die vier größten Repos stellen 52 Prozent aller Befunde. Sieben Repos liegen im
einstelligen bis niedrigen zweistelligen Bereich und sind praktisch fertig.

> **Diese Tabelle ist der Ausgangsstand vom 2026-08-29 vor den Fixes.** Sie
> wird bewusst nicht fortgeschrieben -- sie ist der Referenzpunkt, gegen den
> gemessen wird. Was seither gefallen ist, steht in Abschnitt 0 und in
> `Diagnostics_FINISHED.md`, jeweils mit eigener Vorher/Nachher-Messung.
>
> **Zur Vergleichbarkeit:** die Messungen der Folgearbeiten laufen mit einer
> etwas anderen Prüf-Config als dieser Erstscan -- sie setzt
> `runtime.path = lua/?.lua` und löst damit `require("<repo>")` innerhalb des
> Repos auf, was 11 `.luarc.json` mit `runtime.pathStrict` nicht tun. Dadurch
> sieht sie in Testdateien mehr als der Erstscan (bei pickers.nvim etwa 121
> statt 39 Befunde) und ist näher an dem, was der Editor zeigt, wo das Plugin
> auf dem `runtimepath` liegt. Vorher/Nachher-Zahlen sind deshalb immer
> innerhalb einer Messreihe zu lesen, nie gegen diese Tabelle.

---

## 3. Verteilung nach Regel

|          Regel           | gesamt | davon `lua/` |
|--------------------------|--------|--------------|
|     `need-check-nil`     |  1190  |     265      |
|  `param-type-mismatch`   |  510   |     336      |
|    `undefined-field`     |  507   |     396      |
|     `missing-fields`     |  441   |     111      |
|  `assign-type-mismatch`  |  160   |     122      |
|  `duplicate-set-field`   |  135   |      8       |
|  `redundant-parameter`   |  126   |      27      |
|      `inject-field`      |  120   |     119      |
|   `undefined-doc-name`   |   55   |      48      |
|  `return-type-mismatch`  |   52   |      44      |
|  `duplicate-doc-field`   |   47   |      47      |
|   `different-requires`   |   41   |      41      |
|  `undefined-doc-param`   |   37   |      37      |
|  `missing-return-value`  |   35   |      35      |
|  `duplicate-doc-param`   |   30   |      30      |
|    `cast-local-type`     |   26   |      26      |
| `redundant-return-value` |   25   |      14      |
|       `deprecated`       |   23   |      23      |
|     `missing-return`     |   17   |      9       |
|   `missing-parameter`    |   8    |      6       |
|   `luadoc-miss-symbol`   |   7    |      7       |
|  `duplicate-doc-alias`   |   5    |      5       |
|       `invisible`        |   2    |      1       |
| `unbalanced-assignments` |   1    |      1       |

Ebenfalls Ausgangsstand, und inzwischen historisch: die aktuelle Verteilung
steht in Abschnitt 0 unter „Stand“, gemessen am 2026-09-01 über alle 33
Workspaces. Gegen diese Tabelle hier zu rechnen führt in die Irre, sie ist
mit einer anderen Prüf-Config entstanden.

Zum Vergleich, was aus den drei größten Posten geworden ist: `need-check-nil`
1190 -> 155, `undefined-field` 507 -> 225, `missing-fields` 441 -> 9.

---

## 4. Die Ursachen-Cluster

---

### A. Fehlender `assert`-Typ in den Tests -- ERLEDIGT 2026-08-31

`assert.are.same(...)`, `assert.is_true(...)`: LuaLS kannte den globalen
`assert` nur als Lua-Standardfunktion, jedes Feld daran war `undefined-field`.

Die Diagnose hier war zu kurz gegriffen. Die Meta-Datei, die den globalen
`assert` typisiert, war schnell gebaut und richtig -- sie **erreichte nur 2 von
33 Workspaces**. Die eigentliche Ursache liegt eine Ebene tiefer und ist
inzwischen im Editor nachgewiesen: **`.luarc.json` ersetzt
`workspace.library` vollständig**, sie ergänzt sie nicht. 31 Repos führten eine
eigene Liste aus ein bis sieben Einträgen und warfen damit die 43 Einträge weg,
die `lsp.nvim` zur Laufzeit zusammenstellt -- busted, `$VIMRUNTIME`, sämtliche
Plugin-Typen und lib.nvim inklusive.

Dazu kam ein zweiter Befund: `build_library.lua` hängte den `runtimepath`
ungefiltert an, also auch das Repo, das gerade offen ist. Ein Workspace, der
seine eigene Library ist, wird zweimal gelesen -- allein in der nvim-Config
waren das 1085 `duplicate-doc-field`.

**Über alle 33 Workspaces von 6344 auf 3204**, kein Repo verschlechtert.
Vollständige Aufstellung samt Messmethode:
[`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).

---

### B. `need-check-nil` in Tests -- ERLEDIGT 2026-08-31

Das dominante Muster in `TESTS/`: `local ok, mod = pcall(require, "x")` und
danach `mod.foo()` ohne Nil-Prüfung, bzw. `vim.fn.getreg`-Rückgaben direkt
weiterverwendet. In Testcode ist der Befund invertiert -- kommt dort etwas als
`nil` zurück, *soll* die Datei krachen und es benennen; die verlangte
Nil-Prüfung würde genau den Fehlschlag verstecken, für dessen Meldung der Test
existiert.

Entschieden wurde deshalb **unterdrücken statt auszementieren**. Die geplante
`TESTS/.luarc.json` pro Repo geht allerdings nicht: **LuaLS liest
ausschließlich die `.luarc.json` im Wurzelverzeichnis des Workspace**, eine in
einem Unterverzeichnis wird ignoriert -- zweimal gegengeprüft, per
`lua-language-server --check` und gegen einen laufenden Server. Also
Dateiebene: 19 Repos, 93 Testdateien, je ein Kopf-Kommentar mit der Begründung
plus `---@diagnostic disable: need-check-nil`. Kein Zeichen Code geändert.

**Über alle 33 Workspaces von 3204 auf 2289**, `need-check-nil` selbst von
1128 auf 208. Vollständige Aufstellung:
[`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).

Die verbliebenen 208 liegen in `lua/` und sind **echt** -- das sind Stellen, an
denen ein `string|nil` ungeprüft weitergereicht wird. Nach Repo: documentation
44, filetree 43, lib 18, lsp 15, gopath 14, nvim-config 11, github_stats 10,
mdview 10, der Rest verteilt.

---

### C. `missing-fields` -- ERLEDIGT 2026-08-29

`Missing required fields in type 'Pickers.Config': depth_aliases, find, ...`

Die `@class *.Config`-Klassen deklarierten ihre Felder als Pflicht. Jedes
partielle `setup({...})` verletzte sie damit -- obwohl genau das die vorgesehene
Nutzung ist.

**Über alle 31 Plugins plus Config von 518 auf 21 gebracht.** Die 21 Reste
liegen sämtlich in lib.nvim und sind die Namespace-Aggregatoren
(`---@type Lib` auf einer Tabelle, die per `LIB.x = ...` gefüllt wird) --
dieselbe Ursache wie Cluster F, und dort aufgeräumt, nicht hier.

Der Fix war **nicht** überall derselbe, und welcher der richtige ist, ließ sich
nur messen: bei 15 Repos genügte es, die Felder optional zu stellen; bei sechs
hätte genau das die Warnungen gegen neue `need-check-nil` eingetauscht, weil
der Code die aufgelöste Config direkt liest -- dort wurde die **Opts**-Klasse
(Eingabe) von der **Config**-Klasse (nach `vim.tbl_deep_extend`) getrennt.

Vollständige Aufstellung, samt der Nebenbefunde, die dabei sichtbar wurden:
[`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).

---

### D. `userdata` statt `TSNode` in documentation.nvim -- ERLEDIGT 2026-08-31

`Undefined field 'iter_children'` (92), `'start'` (65), `'end_'` (28), `'type'`
(26). Ursache ist eine einzelne Annotation, wiederholt über alle Sprachmodule:

```lua
---@param node userdata
local function child_of(node, kind)
  for child in node:iter_children() do
```

`userdata` typisiert als *gar keine Felder*, deshalb war jeder Aufruf darauf ein
Befund. Neovim liefert `TSNode` mit genau diesen Methoden in
`$VIMRUNTIME/lua/vim/treesitter/_meta/tsnode.lua` mit -- die Annotation war also
nur der falsche Name für einen Typ, der die ganze Zeit da war. 154 Stellen in
17 Sprachmodulen plus `core/plugins.lua`.

Zwei Nachbarn derselben Klasse, von derselben Messung mitgefunden: die
Client-Handles in `editor/serve.lua` kommen aus `uv.new_tcp()` und sind
`uv.uv_tcp_t` (11 Befunde), und `standalone/treesitter.lua` übersetzt
`lua-tree-sitter`, dessen Knoten **kein** `TSNode` sind -- die Bindung hat
`start_byte`/`end_byte` statt `start()`/`end_()`, weshalb dort eine eigene
Klasse steht statt Neovims Typ.

**383 -> 155 in dem Repo**, `undefined-field` 237 -> 9, und keine andere Regel
hat sich um einen Zähler bewegt. Vollständige Aufstellung:
[`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).

---

### E. `pcall(vim.cmd, ...)` -- 46 offen, lib.nvim und lsp.nvim erledigt

`Cannot assign 'table' to parameter 'fun(...any):...unknown'`. `vim.cmd` ist in
Neovims Meta-Definition eine aufrufbare **Tabelle**, keine Funktion, passt also
nicht auf `pcall`s ersten Parameter. Der Aufruf funktioniert zur Laufzeit
einwandfrei, LuaLS kann es nur nicht ausdrücken.

Fix: `pcall(function() vim.cmd(...) end)`. Häufungen in
`fileops.nvim/lua/fileops/ops/file.lua` (12), `ops/cycle.lua` (6),
`filetree.nvim/lua/filetree/adapter/{netrw,oil}.lua`, `sessions.nvim/core.lua`.

**lib.nvims zehn sind erledigt (2026-08-31)** -- sieben in `lua/`, drei in
`TESTS/`, genau in dieser Form. `vim.cmd.edit` / `vim.cmd.colorscheme` sind
davon nicht betroffen: die Feldform *ist* eine Funktion. **lsp.nvims vier
folgten am 2026-09-01** (`bindings/actions.lua`, `diagnostics/quickfix.lua`).

---

### F. `inject-field` (119) -- fast vollständig lib.nvim -- ERLEDIGT 2026-08-31

`Fields cannot be injected into the reference of 'LibStringsCore' for 'trim'.`

Das Muster: `---@class LibStringsCore` deklariert die Felder, dann folgen
`function S.trim(...)`-Definitionen, die LuaLS als Injektion in eine bereits
geschlossene Klasse liest. Konzentriert in
`lib/lua/tables/{set,core,array,safe,dict,functional}.lua` (~90) und
`lib/lua/strings/core.lua` (21). Ein Muster, ein Fix pro Datei.

**Erledigt 2026-08-31.** Die Vermutung „ein Muster, ein Fix pro Datei“ hat
gehalten, die Diagnose darunter nicht: die genannten Klassen sind leer --
acht Deklarationen ohne ein einziges `---@field`, abgelegt hinter dem
`return` der jeweiligen `@types/init.lua`. Die gefüllten Klassen liegen
daneben und heißen anders. 108 -> 0, zusammen mit den 22
`missing-fields`-Resten; Details in
[`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).

---

## 5. Die kleinen, echten Befunde

Diese sind **nicht** musterhaft, sondern einzeln zu prüfen. Zusammen ~90 Stück
-- das ist die Liste, bei der sich Durchgehen am ehesten lohnt.

---

### `deprecated` (23) -- veraltete Neovim-APIs

| API | Ersatz | Fundstellen |
|---|---|---|
| `vim.lsp.stop_client` | `client:stop()` | ~~lsp.nvim: `usercmds/stop.lua`, `usercmds/restart.lua`, `usercmds/recovery.lua`~~ -- **2026-09-01**: nicht mehr gemeldet; die drei verbliebenen `deprecated` des Repos stehen in `bindings/usrcmds.lua:588` und `bindings/which_key.lua:63,69` |
| `vim.diff` | `vim.text.diff` | diff.nvim: `core/render.lua:26,398,442`, `health.lua:25` |
| `vim.fn.termopen` | `vim.fn.jobstart(..., {term=true})` | debugging.nvim `tools/proc_trace.lua:130`, filetree.nvim `features/system/shell_run/init.lua:58` |
| `vim.api.nvim_buf_get_option` | `nvim_get_option_value` | ~~lib.nvim `buf_win_tab/get_option/init.lua:24`~~ -- **2026-08-31**: bewusster Kompatibilitätszweig, läuft nur wenn `nvim_get_option_value` davor scheitert; unterdrückt mit Begründung |
| `vim.api.nvim_buf_add_highlight` | `vim.hl.range` / Extmarks | sandbox.nvim `ui/list_view.lua:47` |
| `vim.lsp.get_log_path` | `vim.lsp.log.get_filename()` | lsp.nvim `bindings/usrcmds.lua:405` |

Sechs weitere sind **bewusste Fallbacks** für ältere Neovim-Versionen und
sollten so bleiben -- wer sie "repariert", bricht die Abwärtskompatibilität:
`vim.islist or vim.tbl_islist` (lib.nvim `logger/serialize.lua:72,73`),
`vim.lsp.get_clients or vim.lsp.get_active_clients` (gopath.nvim `health.lua:94`,
language.nvim `spell/providers/lsp.lua:23`), `vim.diagnostic.goto_next/goto_prev`
im Alt-API-Zweig (language.nvim `spell/init.lua:170`).

---

### `missing-parameter` (6) -- Aufruf mit zu wenig Argumenten

- `buffer-ctx.nvim/lua/buffer_ctx/format/column_align.lua:47` (3 erwartet, 2 übergeben)
- `fileops.nvim/lua/fileops/bindings/keymaps.lua:256` (1 erwartet, 0)
- `lsp.nvim/lua/lsp/servers/lua_ls/reload.lua:106` (3 erwartet, 2)
- `lsp.nvim/lua/lsp/usercmds/init.lua:66` (1 erwartet, 0)
- `lsp.nvim/lua/lsp/usercmds/stop.lua:54` und `:83` (1 erwartet, 0)

---

### `luadoc-miss-symbol` (7) -- kaputte Annotation, Klammer fehlt

- `fileops.nvim/lua/fileops/ops/file.lua:628` (`}` erwartet)
- ~~`lib.nvim/lua/lib/nvim/buf_win_tab/@types/resize_guarded.lua:40`~~
- ~~`lib.nvim/lua/lib/nvim/cross/@types/init.lua:20`~~
- ~~`lib.nvim/lua/lib/nvim/cross/fs/mutate/@types/init.lua:13`~~
- `pickers.nvim/lua/pickers/ui/{action_picker.lua:9,dir_nav_picker.lua:15,scope_picker.lua:34}`

Diese sieben sind der einzige Fall, in dem eine Annotation gar nicht geparst
wird -- der dokumentierte Typ existiert dort effektiv nicht.

**lib.nvims drei sind erledigt (2026-08-31).** Alle drei hatten dieselbe
Ursache: ein inneres `fun(): X` in einer Signatur frisst jeden Parameter, der
danach kommt. Klammern drum -- `(fun(): X)` -- und die Annotation parst. Der
Fix ist selbst eine Fehlerquelle: dieselbe Form in `Lib.AutoCmd.create` hat
`create` still auf zwei Parameter reduziert und vier `redundant-parameter` an
der Aufrufstelle erzeugt, ohne dass die `@types`-Datei selbst einen Befund
bekam.

---

### `duplicate-set-field` (8 in `lua/`)

- `filetree.nvim/lua/filetree/features/infra/watcher_quarantine/init.lua:76` -- `notify`
- `images.nvim/lua/images/debug.lua:86` -- `draw`
- ~~`lib.nvim/lua/lib/nvim/system/proc_trace.lua:144,158`~~ -- `system`, `jobstart`. **2026-08-31**: bestätigt Monkey-Patching, unterdrückt mit Begründung
- `sandbox.nvim/lua/sandbox/bindings/usrcmds/init.lua:74` -- `notify`
- `nvim-config/lua/bindings/mappings/editing.lua:216` -- `paste`
- `nvim-config/lua/config/todo_comments/init.lua:42` -- `nvim_buf_set_extmark`
- `nvim-config/lua/config/ui_open.lua:43` -- `open`

Die in `proc_trace.lua` und `todo_comments` sind vermutlich beabsichtigtes
Monkey-Patching; die übrigen sind zu prüfen.

---

### `duplicate-doc-alias` (5) -- derselbe Typname zweimal definiert

`LogLevel` existierte dreifach: `lib.nvim/lua/lib/nvim/notify/@types/init.lua:9`,
`gopath.nvim/lua/gopath/util/@types/init.lua:28` und
`nvim-config/lua/@types/log.lua:20`. Dazu `LogLevelNumber`
(`nvim-config/lua/@types/log.lua:12`) und `Result`
(`nvim-config/lua/@types/functional.lua:26`) gegen lib.nvim.

Das ist echt und fällt im Editor an, weil lazydev lib.nvim mitlädt: welche
Definition gewinnt, ist nicht bestimmt.

**lib.nvims Anteil ist erledigt (2026-08-31)** -- und zwar andersherum als
hier vermutet: nicht einmal gemeinsam definieren, sondern getrennt benennen.
Was der Library gehört, heißt jetzt `Lib.Notify.LogLevel*`; was die Config
global braucht, behält seinen Namen. Dasselbe für
`AutoCmds.General.MD.GotoFile.Cfg`, das lib.nvim von der Config geborgt
hatte und jetzt `Lib.Fs.Open.Url.SystemOpener.Cfg` heißt. Offen bleiben
gopath.nvims `LogLevel` und `Result`.

---

### `unbalanced-assignments` (1)

~~`lib.nvim/lua/lib/nvim/bindings/autocmd/docs.lua:591`~~ -- eine Variable bekam
still `nil`, weil die rechte Seite zu wenige Werte lieferte. **Erledigt
2026-08-31**: `local ok, err, written = true, nil, nil`. Absicht war es, die
dritte Variable erst weiter unten zu setzen -- das schreibt man jetzt hin.

---

### `invisible` (1)

`lsp.nvim/lua/lsp/integrations/trouble.lua:84` greift auf
`vim.treesitter.highlighter._on_win` zu -- privates Upstream-Feld. Bekannt
riskant, aber bewusst; gehört dokumentiert statt behoben.

---

### `different-requires` (41) -- ausschließlich nvim-Config

`The same file is required with different names` -- dieselbe Datei wird einmal
als `require("autocmds.git")` und einmal als `require("autocmds.git.init")`
gezogen. Betroffen u.a. `lua/autocmds/{git,terminals,text}/init.lua`,
`lua/config/neotree/keymaps/init.lua`,
`lua/wkdnvchad/config/statusline/{custom,custom_minimal,normal}.lua`,
`lua/wkdnvchad/mappings/init.lua`. Kosmetisch, aber es führt dazu, dass Module
doppelt im `package.loaded`-Cache landen können.

---

### Weitere Annotationsfehler (144)

`duplicate-doc-field` (47, davon 30 allein in
`lsp.nvim/lua/lsp/@types/vim_lsp.lua`), `undefined-doc-param` (37, d.h. `@param`
auf einen Parameter, den die Funktion nicht hat), `duplicate-doc-param` (30,
u.a. `emojis.nvim/lua/emojis/search.lua:181-185`,
`images.nvim/lua/images/paste.lua`), `missing-return-value` (35, Hotspot
`gopath.nvim/lua/gopath/resolve.lua` mit 11 und
`pdfport.nvim/lua/pdfport/integrations/init.lua` mit 8),
`redundant-return-value` (14), `undefined-doc-name` (48).

Alles Doku-gegen-Code-Abweichungen: niedriges Risiko, hoher Aufräumwert, gut
delegierbar.

---

## 6. stylua

**ERLEDIGT 2026-08-29** -- mit einer Ausnahme, die am 2026-08-31 aufgefallen
ist: `diff.nvim/plugin/diff.lua` hat CRLF-Zeilenenden und fällt deshalb bei
`stylua --check` durch. Nicht von den Formatierungen unten verursacht, die
Zeilenenden stammen aus `4cb35d4` vom 2026-08-06; der Punkt steht in
Abschnitt 0 unter *Offen*. Sonst ist `stylua --check` über alle 31 Repos
sauber.

Ursprünglich wichen vier Dateien in drei Repos ab, alle derselbe Fall -- ein
einzeiliges `function() ... end`, das stylua aufklappen will:
`emojis.nvim/plugin/{emojis,emojis_autodoc}.lua`,
`gopath.nvim/scripts/ci/headless_tests.lua`,
`mdview.nvim/docs/templates/usercmds.lua`. Alle formatiert.

Dazu die Ausreißer-Entscheidung: `mdview.nvim` formatierte als einziges der 31
Repos mit Tabs (`indent_type = "Tabs"`, `indent_width = 4`) und steht jetzt auf
der Repo-Konvention `Spaces` / `2`. Siehe
[`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).

---

## 7. Nebenbefunde

- ~~**Übrig gebliebener Claude-Worktree in `open.nvim`.**~~ **Erledigt
  2026-08-29:** Worktree und beide Altbranches entfernt, nachdem geprüft war,
  dass ihre zwei Commits inhaltlich schon auf `main` liegen. `.claude/` ist
  dort jetzt gitignored. Siehe
  [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).
- **Zwei Worktrees in dieser Config:**
  `.claude/worktrees/dazzling-chaplygin-5284d5` und `serene-gagarin-e46262`,
  zusammen 1620 Lua-Dateien. Hier ist `.claude/` gitignored, also auch für
  LuaLS unsichtbar -- reiner Plattenplatz.
- **`.claude/` ist in sieben Repos nicht gitignored** (diff, documentation,
  lib, markdown, mdview, recommender, replacer) -- in allen sieben ist das
  Verzeichnis leer, also folgenlos, solange dort kein Worktree entsteht.
  open.nvim war der achte und ist seit 2026-08-29 versorgt.
- ~~**11 von 31 `.luarc.json` führen `$VIMRUNTIME/lua` nicht**~~ -- die Frage
  hat sich umgedreht und ist am 2026-08-31 beantwortet: `.luarc.json`
  **ersetzt** `workspace.library`, also kam bei den 31 Repos mit eigener Liste
  gar nichts von der Injektion an, `$VIMRUNTIME` eingeschlossen. In den 20
  Repos, wo die Messung dafür sprach, ist die Liste jetzt weg. Kein CI ruft
  `lua-language-server` auf, das war also folgenlos. Siehe
  [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).
- **Die 20 bereinigten Repos hängen jetzt an `lsp.nvim`.** Ohne diese Config
  geöffnet -- anderer Editor, `lua-language-server` von Hand -- bekommen sie
  eine leere Library. Bewusst in Kauf genommen: die entfernten Listen waren
  ohnehin unvollständig, und kein CI prüft mit LuaLS. Die 11 Repos, bei denen
  die Messung gegen den Fix sprach, behalten ihre Liste.

---

## 8. Was daraus folgt

Nach Aufwand-zu-Wirkung geordnet. Punkt 1 und 5 liefen **horizontal**, weil sie
die Zahlen aller Repos verändern; beide sind seit dem 2026-08-31 erledigt. Was
bleibt, läuft **vertikal pro Repo** -- siehe Arbeitsmodus in Abschnitt 0.

1. ~~**`assert`-Meta einbauen**~~ -- **erledigt 2026-08-31**, aber anders als
   hier vermutet: nicht die vier Zeilen waren das Problem, sondern dass
   `.luarc.json` die Library-Injektion ersetzte und die Meta-Datei deshalb
   nirgends ankam. 6344 -> 3204 über alle 33 Workspaces.
2. ~~**`TSNode` statt `userdata` in documentation.nvim**~~ -- **erledigt
   2026-08-31**: 154 Annotationen in 18 Dateien, dazu `uv.uv_tcp_t` in
   `serve.lua`. 383 -> 155, `undefined-field` 237 -> 9.
3. ~~**Opts/Config trennen** (Cluster C)~~ -- **erledigt 2026-08-29**, 518 -> 21.
4. **Die ~90 kleinen Befunde aus Abschnitt 5** -- der Teil, bei dem Durchgehen
   tatsächlich Fehler findet statt Rauschen. Hier liegen die einzigen
   Kandidaten für echte Laufzeitfehler (`missing-parameter`,
   `unbalanced-assignments`, `luadoc-miss-symbol`).
5. ~~**`need-check-nil` in Tests** (920)~~ -- **erledigt 2026-08-31**:
   unterdrückt, nicht auszementiert, mit der Begründung im Kopf jeder
   betroffenen Testdatei. Nicht auf Verzeichnisebene wie geplant -- LuaLS liest
   nur die `.luarc.json` im Wurzelverzeichnis. 3204 -> 2289.
6. ~~**`inject-field` in lib.nvim**~~ -- **erledigt 2026-08-31**, 108 -> 0
   samt der 22 `missing-fields`-Reste. Mechanisch war daran nur die Form;
   die Ursache waren acht leere Klassen, durch die die `Lib`-Fassade vier
   Namespaces untypisiert anbot.
7. ~~**lib.nvim vertikal**~~ -- **erledigt 2026-08-31**, 273 -> 1. Zwanzig
   kleine Ursachen statt einer großen, zwei davon echte Fehler. Zehn der
   60 `pcall(vim.cmd, ...)` sind dabei mit weggegangen; 50 stehen noch aus.
8. ~~**stylua**~~ -- **erledigt 2026-08-29**: alle vier abweichenden Dateien
   formatiert, mdview.nvim auf `Spaces`/`2` umgestellt. `stylua --check` ist
   über alle 31 Repos sauber.

Von den offenen ist der `pcall(vim.cmd, ...)`-Fix (50) der mechanische
Rest. Punkt 4 ist der inhaltlich interessante Teil -- und zwei vertikale
Durchgänge haben inzwischen gezeigt, dass er das zu Recht ist: die einzigen
echten Laufzeitfehler, die diese Arbeit gefunden hat, standen alle in
Regeln, die von außen wie Kosmetik aussehen.

---

## 9. Anhang: der delegierbare Teil des Roadmap-Punkts

Der ursprüngliche Eintrag trug den Zusatz *"Das Refactoring der `wq`-Logik nach
`lib.nvim.ui` selbst ist delegierbar"*. Rekonstruktion, was gemeint war:

`lib.nvim/lua/lib/nvim/ui/` enthält `hl`, `kit`, `nerd_font`, `statusline` --
**kein** Quickfix-/Loclist-Modul. Gleichzeitig bauen 20 Dateien in 14 Repos ihre
`setqflist`/`setloclist`-Senke jeweils selbst: `spotlight/qf.lua`,
`replacer/export.lua`, `markdown/core/{refs,link_diagnostics}.lua`,
`documentation/bindings/usrcmds/*.lua` (11 Dateien),
`filetree/{features/search/grep_in_dir,util/refs_picker}`,
`insights/conflicts/init.lua`, `language/spell/ui/list.lua`,
`diff/core/{directory,render}.lua`, `emojis/{actions,search}.lua`,
`debugging/autocmds/sources.lua`, `runtime-analysis/bindings/usrcmds.lua` --
und, am ausgereiftesten, `lsp.nvim/lua/lsp/diagnostics/{quickfix,loclist}.lua`.

Der delegierbare Teil war also: die Listen-Senke nach `lib.nvim.ui` heben,
damit es eine gemeinsame Implementierung gibt statt 14 Eigenbauten -- und die
vorhandenen Aufrufer darauf umstellen.

**Erledigt 2026-08-29** als `lib.nvim.ui.list` (`set`/`qf`/`loc`), alle 20
Aufrufstellen in 12 Repos umgestellt; in ganz `C:/repos` liegt unter `lua/`
noch genau eine `setqflist`-Zeile, und die steht im Modul selbst. Eine
Korrektur zur Vermutung oben: `lsp.nvim/lua/lsp/diagnostics/*` war gerade
**nicht** die Vorlage -- das ist `vim.diagnostic.setqflist`, eine andere API
mit eigener Severity-Behandlung und einer zwischen Neovim 0.10 und 0.11
geänderten Signatur, und blieb unangetastet. Details, inklusive der vier
Unterschiede, die die Eigenbauten stillschweigend hatten, in
[`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md).

---

