# Diagnostics -- LSP-Befund über alle Plugins

## Table of content

  - [TASK an Claude delegieren (Claude soll diesen Punkt nicht bearbeiten!)](#task-an-claude-delegieren-claude-soll-diesen-punkt-nicht-bearbeiten)
  - [Intro](#intro)
  - [0. Stand, Arbeitsmodus, nächster Schritt](#0-stand-arbeitsmodus-nchster-schritt)
    - [Gerade in Arbeit](#gerade-in-arbeit)
    - [Vorschlag nächster Schritt](#vorschlag-nchster-schritt)
    - [Erledigt](#erledigt)
    - [Stand nach dem lib.nvim-Durchgang (2026-08-31)](#stand-nach-dem-libnvim-durchgang-2026-08-31)
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
    - [E. `pcall(vim.cmd, ...)` -- 50 offen, lib.nvims 10 erledigt](#e-pcallvimcmd-50-offen-libnvims-10-erledigt)
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

## Intro

Ergebnis des Roadmap-Punkts *"`<leader>wq`: alle damit auffindbaren Issues live
durchgehen"* (aus `FINISH/MERGED.md`, Liste A / Live-Testing).

Stand: 2026-08-29. Umfang: 31 `*.nvim`-Repos unter `C:/repos` plus diese
nvim-Config. 32 Workspaces, ~2900 Lua-Dateien.

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

**Stand: 2026-08-31.** Alles unten Genannte ist in den jeweiligen Repos
committet und auf `main` gepusht.

---

### Gerade in Arbeit

**lsp.nvim.** Die Messgrundlage ist am 2026-09-01 korrigiert (siehe unten),
damit steht das Repo bei **172** statt 359. Die Codearbeit daran hat noch
nicht angefangen.

---

### Vorschlag nächster Schritt

**lsp.nvim vertikal** (172). Die Zahl ist neu und niedriger als die 379 im
Report: am 2026-09-01 hat sich herausgestellt, dass **180 der 359 Befunde gar
nicht dem Repo gehörten** -- dazu unten mehr. Was übrig bleibt, hat keinen
einzelnen großen Posten mehr:

- `param-type-mismatch` **32**, `duplicate-doc-field` **30**,
  `assign-type-mismatch` **21**, `undefined-doc-name` **19**,
  `need-check-nil` **17**, `redundant-parameter` **15**
- Die 19 `undefined-doc-name` zuerst: `Lsp.Languages.ConfiguredLangs.*.Module`
  (acht Sprachmodule), `FormatterApi`, `FormatterOptions`, `FormatterState`.
  Diese Typen werden referenziert und sind in lsp.nvim **nirgends definiert** --
  sie haben bis zum 01.09. still gegen eine veraltete Kopie des Repos
  aufgelöst. Das ist der interessanteste Teil des Repos, nicht der lästigste
- die 30 verbliebenen `duplicate-doc-field` sind der Rest von
  `lua/lsp/@types/vim_lsp.lua`: Neovim 0.12 führt alle sieben dort
  nachdeklarierten Klassen selbst (`vim.lsp.Client`, `ClientConfig`,
  `get_clients.Filter`, `start.Opts`, `buf.{format,code_action,rename}.Opts`).
  Der Dateikopf sagt „missing from Neovim's builtin types" -- das stimmt nicht
  mehr

Danach die fünf kleineren der sechs (`buffer-ctx` 8, `emojis` 13, `sessions`
15, `fileops` 35, `gopath` 67) -- je ein kurzer Durchgang, zusammen 138. Deren
Zahlen sind allerdings ebenfalls vor der Korrektur der Messgrundlage
entstanden und gehören neu genommen.

---

### Erledigt

| # | Punkt | Ergebnis |
|---|---|---|
| A | **`assert`-Typ**, und die Library-Auflösung dahinter | **6344 -> 3204** über alle 33 Workspaces. `.luarc.json` ersetzt `workspace.library` komplett, deshalb kam lsp.nvims Injektion in 31 Repos nie an. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| B | **`need-check-nil` in Tests** -- unterdrückt, nicht auszementiert | **3204 -> 2289** über alle 33 Workspaces, `need-check-nil` 1128 -> 208. 19 Repos, 93 Testdateien, je ein Kopf-Kommentar mit Begründung. Die geplante `TESTS/.luarc.json` geht nicht -- LuaLS liest nur die im Wurzelverzeichnis. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| D | **`userdata` statt `TSNode`** in documentation.nvim | **383 -> 155** in dem Repo, `undefined-field` 237 -> 9. 154 Annotationen in 18 Dateien, dazu `uv.uv_tcp_t` in `serve.lua` und eine eigene Klasse für die Fremdbindung in `standalone/`. Keine andere Regel hat sich um einen Zähler bewegt. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V | **documentation.nvim fertig** -- der erste vertikale Durchgang | **155 -> 0**. Dreizehn kleine Ursachen statt einer großen; darunter ein echter Fehler (`vim.health.info` nimmt keine Advice-Liste, zwölf Aufrufe verloren ihre Hinweise) und zwei verwaiste Doc-Blöcke, die am Kommentar der nächsten Funktion klebten. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| C | **`missing-fields`** über alle 31 Plugins + Config | **518 -> 21**, die 21 Reste sind lib.nvims Aggregator-Klassen und gehören zu Cluster F. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| F | **`inject-field` in lib.nvim** -- plus die `missing-fields`-Reste aus C | **381 -> 244** in dem Repo, `inject-field` 108 -> 0, `missing-fields` 22 -> 0. Eine Schreibweise (`---@type` auf einer Tabelle, die erst danach gefüllt wird), drei Ursachen darunter -- acht leere „Zombie“-Klassen hinter einem `return`, durch die die `Lib`-Fassade vier Namespaces untypisiert anbot; elf Module, deren Annotation nur auf der falschen Zeile stand; ein Typ, der schlicht falsch war. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| L | **`$VIMRUNTIME/lua` in sechs `.luarc.json`** -- die Messgrundlage | **356 -> 411** über die sechs. `buffer-ctx`, `emojis`, `fileops`, `gopath`, `lib` und `sessions` setzten `workspace.library` selbst und warfen damit die Injektion weg; `vim` war dort ein Global vom Typ `any`. Der Zuwachs ist der Zweck: 60 Befunde fallen weg, weil Typen auflösen, 119 kommen an Stellen dazu, die vorher niemand geprüft hat -- darunter fünf `deprecated`, die seit dem Erstscan in Abschnitt 5 stehen. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| V2 | **lib.nvim fertig** -- der zweite vertikale Durchgang | **273 -> 1**. Zwanzig kleine Ursachen, darunter zwei echte Fehler: `getbufinfo()` liefert kein `filetype` (jede Filetype-Ausschlussliste in `buffer_utils` war wirkungslos) und `page_key` verwarf still die Seitenzahl (alle Seiten eines PDFs teilten sich einen Hover-Cache-Slot). Der eine Rest gehört nach lsp.nvim. Details: [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| M | **Die Messgrundlage, zweiter Teil** (2026-09-01) | `${3rd}/luassert` fehlte in der Injektion, und `workspace.ignoreDir` wurde von der Messreihe gar nicht gesetzt. Letzteres liess LuaLS elf Config-Kopien unter `.claude/worktrees/` mitlesen, eine davon mit einem `lua/lsp/**` von vor der Extraktion: **180 von lsp.nvims 359 Befunden** waren Kollisionen des Repos mit einer alten Kopie seiner selbst. lsp.nvim **359 -> 172**, lib.nvim **1 -> 0**. Details unten unter „Offen“ und in [`Diagnostics_FINISHED.md`](./Diagnostics_FINISHED.md) |
| 6 | **stylua** | alle 4 abweichenden Dateien formatiert, mdview auf `Spaces`/`2` umgestellt |
| 7 | **Claude-Worktree in open.nvim** | entfernt, `.claude/` dort gitignored |
| 9 | **`lib.nvim.ui.list`** | gebaut, 20 Aufrufstellen in 12 Repos umgestellt |

---

### Stand nach dem lib.nvim-Durchgang (2026-08-31)

Nur die Repos über 100 Befunden; Summe über alle 33 Workspaces. Gemessen in der
Messreihe vom 31.08., nicht gegen die eingefrorene Tabelle in Abschnitt 2. Eine
Gegenprobe mit `scripts/luals-scan` kam nach Cluster B auf 2285 statt 2289 --
vier Zähler daneben, bei repoweise identischen Zahlen. Das ist das Rauschen aus
Abschnitt 1.

| Repo | gesamt | die zwei größten Regeln darin |
|---|---:|---|
| lsp.nvim | **172** | `param-type-mismatch` 32, `duplicate-doc-field` 30 |
| filetree.nvim | 167 | `undefined-field` 60, `need-check-nil` 43 |
| nvim-config | 137 | `param-type-mismatch` 38, `assign-type-mismatch` 26 |
| runtime-analysis.nvim | 119 | `param-type-mismatch` 47, `undefined-field` 30 |
| documentation.nvim | **0** | -- |
| lib.nvim | **1** | `undefined-doc-name` auf `luassert` -- gehört nach lsp.nvim |
| **Summe (alle 33)** | **1365** | |

Zwei Repos stehen jetzt praktisch auf null, und beide sind vertikal
durchgegangen worden. Die Summe ist fortgeschrieben (1824 - 272 - 187), nicht
neu über alle 33 gemessen.

**Der Gesamtlauf steht jetzt nicht mehr nur aus, er ist fällig.** Die
Korrektur vom 01.09. wirkt auf jedes Repo, dessen `.luarc.json` einen
`workspace.ignoreDir` nennt -- das sind elf plus die Config -- und auf jedes
mit Testsuite (luassert). Alle Zahlen oben ausser lsp.nvim und lib.nvim sind
vor dieser Korrektur entstanden.

**Die 55 aus dem Library-Fix bleiben ein Vorzeichenwechsel, kein Rückschritt.**
Bis dahin hieß eine fallende Zahl "behoben". Bei den sechs Repos ohne
`$VIMRUNTIME/lua` hieß die niedrige Zahl "nicht geprüft", und sie stieg, weil
jetzt geprüft wird. lib.nvims 273 sind genau diese Sorte Zahl gewesen -- und
sie sind jetzt echt abgearbeitet, nicht bloß wieder unsichtbar.

---

### Offen

Reihenfolge wie in Abschnitt 8, dazu zwei Nachträge aus der B-Runde (9 und 10).
Kurz:

1. **`workspace.ignoreDir` in elf `.luarc.json` plus der Config** --
   `cmdlog`, `dap`, `debugging`, `diff`, `filetree`, `neotree-fs-refactor`,
   `open`, `pdfport`, `recommender`, `sandbox` und die nvim-Config nennen den
   Schlüssel und werfen damit die 124 injizierten Muster weg, `**/.claude`
   darunter. Dieselbe Falle wie bei `workspace.library` in Cluster A, nur auf
   einem zweiten Schlüssel. In lsp.nvim ist er entfernt (2026-09-01) und hat
   dort 187 Befunde gekostet -- bei den übrigen ist die Wirkung ungemessen.
   **Vor** dem nächsten Gesamtlauf zu erledigen
2. **Gesamtlauf über alle 33 Workspaces** -- die erste Summe, die nach der
   korrigierten Messgrundlage entsteht. Alles darunter rechnet gegen sie
3. **lsp.nvim vertikal** (172) -- vorgeschlagener nächster Schritt, siehe oben
4. **Die fünf kleineren der sechs** (`buffer-ctx` 8, `emojis` 13, `sessions` 15,
   `fileops` 35, `gopath` 67) -- Zahlen vor der Korrektur, neu zu nehmen
5. **`pcall(vim.cmd, ...)`** (E) -- 50 der 60 offen, lib.nvims 10 erledigt.
   Mechanisch, über mehrere Repos
6. **Die Einzelbefunde** aus Abschnitt 5 -- der inhaltlich interessante Teil;
   documentation.nvims und lib.nvims Anteil daran ist erledigt
7. **Die verbliebenen `need-check-nil` in `lua/`** -- die sind echt: ein
   `string|nil` wird ungeprüft weitergereicht. Fällt beim jeweiligen Repo an,
   nicht als eigener Durchgang
8. **`scripts/luals-scan` dumpt die falsche Library-Funktion** --
   `dump_library.lua` ruft `build_library(root)` (37-147 Einträge), der
   Attach-Pfad des Editors benutzt `library_profiles.build_runtime_library()`
   (drei). Praktisch ersetzt das Werkzeug damit lazydev, was als Annäherung
   taugt -- aber der README beschreibt es als das, was der Editor tut
9. **Die drei Aggregator-Strategien von lib.nvim decken sich nicht** -- `lazy`
   exportiert neun Schlüssel, die `metatable` (die Voreinstellung) nicht kennt;
   `eager` nennt `augroup` `autogroup` und mutiert beim Aufbau die Modultabelle
   von `lib.lua.json`. Kein LuaLS-Befund, aufgefallen bei Cluster F
10. **`diff.nvim/plugin/diff.lua` auf LF umstellen** -- CRLF seit `4cb35d4`
    (2026-08-06), fällt bei `stylua --check` durch
11. Der Rest der Verteilung (`param-type-mismatch`, `assign-type-mismatch`,
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

Ebenfalls Ausgangsstand. `missing-fields` steht seit dem 2026-08-29 bei 21
statt 441, alle verbliebenen in lib.nvim (Cluster F). `need-check-nil` steht
seit dem 2026-08-31 bei 208 statt 1190 -- die aus `TESTS/` und `scripts/` sind
dort unterdrückt, die in `lua/` stehen noch.

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

### E. `pcall(vim.cmd, ...)` -- 50 offen, lib.nvims 10 erledigt

`Cannot assign 'table' to parameter 'fun(...any):...unknown'`. `vim.cmd` ist in
Neovims Meta-Definition eine aufrufbare **Tabelle**, keine Funktion, passt also
nicht auf `pcall`s ersten Parameter. Der Aufruf funktioniert zur Laufzeit
einwandfrei, LuaLS kann es nur nicht ausdrücken.

Fix: `pcall(function() vim.cmd(...) end)`. Häufungen in
`fileops.nvim/lua/fileops/ops/file.lua` (12), `ops/cycle.lua` (6),
`filetree.nvim/lua/filetree/adapter/{netrw,oil}.lua`, `sessions.nvim/core.lua`.

**lib.nvims zehn sind erledigt (2026-08-31)** -- sieben in `lua/`, drei in
`TESTS/`, genau in dieser Form. `vim.cmd.edit` / `vim.cmd.colorscheme` sind
davon nicht betroffen: die Feldform *ist* eine Funktion.

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
| `vim.lsp.stop_client` | `client:stop()` | lsp.nvim: `usercmds/stop.lua:39,43,55,88`, `usercmds/restart.lua:67,99`, `usercmds/recovery.lua:137` |
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

