# `spec.nvim` — Konzept

Ein multilang-fähiger Test-Runner für die eigene Plugin-Welt, gebaut auf
`lib.nvim`.

> **Abgrenzung zu [test.md](./test.md):** Das dort beschriebene `test.nvim`
> lagert die *neotest-Konfiguration* aus — den Adapter-/UI-Layer für fremde
> Testsuites. `spec.nvim` ist die **Engine**: Discovery, Ausführung,
> Ergebnis-IR, Reporting. Saubere Arbeitsteilung, kein Konflikt (§12).

**Ergebnis vorab: Ja, lohnt sich** — aber nicht mit der Begründung "es fehlt
ein Test-Framework". Der Befund ist: **es existieren bereits 16 davon, in 4
zueinander inkompatiblen Dialekten**, `lib.nvim` hat seit 2026-08-17 genau
die Bausteine, an denen plenary/busted schwach sind, und
`documentation.nvim` liefert einen Abhängigkeitsgraphen, mit dem sich
Dinge bauen lassen, die **kein generisches Test-Framework kann** (§9).

---

## Table of Content

- [1. Ist-Zustand](#1-ist-zustand)
- [2. Die vier Dialekte](#2-die-vier-dialekte)
- [3. Konkrete Probleme im Ist-Zustand](#3-konkrete-probleme-im-ist-zustand)
- [4. Warum jetzt: lib.nvim liefert die Bausteine](#4-warum-jetzt-libnvim-liefert-die-bausteine)
- [5. Abgrenzung zu bestehenden Frameworks](#5-abgrenzung-zu-bestehenden-frameworks)
- [6. Architektur](#6-architektur)
- [7. Multilang](#7-multilang)
- [8. Öffentliche API](#8-öffentliche-api)
- [9. Performance-Architektur](#9-performance-architektur)
- [10. Safety & Determinismus](#10-safety--determinismus)
- [11. Fortgeschrittene Testarten](#11-fortgeschrittene-testarten)
- [12. Ökosystem-Integration](#12-ökosystem-integration)
- [13. Migrationsplan](#13-migrationsplan)
- [14. Dokumentationspflichten](#14-dokumentationspflichten)
- [15. Offene Fragen / Risiken](#15-offene-fragen--risiken)

---

## 1. Ist-Zustand

Scan über `$REPOS_DIR\*.nvim\` (2026-08-17):

| Kennzahl | Wert |
|---|---|
| Repos mit Specs | 19 von 33 |
| Repos **ohne** jede Spec | 14 |
| Handgerollter `harness.lua` + `run.lua` | **16** |
| `PlenaryBustedDirectory` | 3 (`dap`, `sandbox`, `github_stats`) |
| Spec-Dateien gesamt | ~550 |

Spitzenreiter: `lib.nvim` (137), `runtime-analysis` (82), `documentation`
(76), `markdown` (55), `images` (39), `spotlight` (38).

Selbst der Ablageort divergiert: `docs/TESTS/` (9×), `TESTS/` (6×),
`tests/` (2×), `scripts/` (1×).

## 2. Die vier Dialekte

| Dialekt | Repos | Zeilen | Helper | Fehlersemantik |
|---|---|---|---|---|
| **A** `H.eq/ok/tmpfile/read_lines` | lib.nvim, documentation, runtime-analysis | 48 | 4 | **bricht bei 1. Fehler ab** |
| **B** `H.eq/ok/scratch` | markdown, diff | 37 | 3 | bricht ab |
| **C** `+ falsy/contains/tmpdir/write` | images | 73 | 7 | bricht ab |
| **D** `M.ok(name, cond, msg)` | spotlight | 100 | eigene | **sammelt, zählt Passes** |
| **E** `describe`/`it`/`assert` | dap, sandbox, github_stats | — | plenary.busted | busted |

Die Inkompatibilität ist strukturell, nicht kosmetisch:

```lua
H.ok(value, msg)              -- lib.nvim   (Dialekt A)
M.ok(name, cond, msg)         -- spotlight  (Dialekt D)
```

**Argument-Reihenfolge verschieden.** Specs sind zwischen Repos nicht
bewegbar.

> **Die wichtigste Einzelbeobachtung:** `spotlight.nvim` hat das
> Abbruch-Problem (P1) **eigenständig gelöst** — sammelt Failures, zählt
> Passes. Die anderen 15 Repos haben die schlechtere Semantik. Genau diese
> Sorte Verbesserung propagiert bei 16 Kopien nie. Dasselbe Muster wie beim
> `await`/`run_async`-Helper, der in zwei Modulen divergierte, bevor er zu
> `lib.nvim.async` wurde — nur mit Faktor 16 statt 2.

## 3. Konkrete Probleme im Ist-Zustand

| # | Problem | Evidenz |
|---|---|---|
| **P1** | Erster fehlgeschlagener Assert killt die Datei (`pcall` + `error`). Bei 137 Specs sieht man einen Fehler pro Lauf. | alle außer D |
| **P2** | Specs nicht portabel; Harness-Verbesserungen propagieren nicht. | §2 |
| **P3** | Keine Isolation. Reihenfolge-Abhängigkeiten bleiben unsichtbar. | `telemetry_wrap_spec` |
| **P4** | Stille No-Op-Specs melden `ok`. Kein Assertion-Count. | alle außer D |
| **P5** | Kein Filtern — immer die volle Suite. | alle `run.lua` |
| **P6** | `PlenaryBustedDirectory` liefert in CI teils `0` trotz Fehlern. | dap, sandbox, github_stats |
| **P7** | Windows zweitklassig (CRLF, Separatoren, `fs_event`-Handles). | quer durch alle Repos |
| **P8** | Fehlerausgabe = zwei `vim.inspect`-Wände, kein Diff. | alle |
| **P9** | Async-Tests sind handgerolltes `vim.wait`-Polling. | `async_spec`, `watch_spec`, `curl_spec`, … |
| **P10** | Keine Aussage über *Test-Qualität*. 137 grüne Specs sagen nicht, ob sie Fehler fangen würden. | — |

## 4. Warum jetzt: lib.nvim liefert die Bausteine

Fast jedes Problem hat einen fertigen Baustein — mehrere **am 2026-08-17
entstanden**:

| Problem | Baustein | Status |
|---|---|---|
| P8 Diff-Ausgabe | `lib.lua.diff.myers` | vorhanden |
| P9 Async | `lib.nvim.async` (`await`/`run`/`wrap`) | **neu** |
| Worker-Pool-Drosselung | `lib.nvim.async.Semaphore` | **neu** |
| P1 Traceback je Assertion | `lib.lua.error.safe_call` | vorhanden |
| P3 Isolation | `lib.nvim.system.job.start_blocking`/`chain` | **neu** |
| Fixtures | `lib.nvim.fs.path.object`, `fs.collect_recursive` | **neu** |
| Cleanup garantiert | `lib.lua.context_manager.with` | **neu** |
| Report-Spalten | `lib.lua.strings.width` (CJK/Emoji/Tab) | **neu** |
| Maschinenlesbar | `lib.nvim.json` | **neu** |
| Watch-Mode + FS-Guard | `lib.nvim.fs.watch` | **neu** |
| Laufzeiten | `lib.lua.time.diff` | vorhanden |
| Suite/Case-Modell | `lib.lua.class` | **neu** |
| P7 Cross-Platform | `lib.nvim.cross.fs.*` | vorhanden |
| Fortschritt / UI | `lib.nvim.progress`, `ui.kit`, `window` | vorhanden |

`spec.nvim` wäre also überwiegend **Verdrahtung getesteter Bausteine** —
genau das, was plenary jeweils selbst mitbringen muss, und schlechter.

## 5. Abgrenzung zu bestehenden Frameworks

| | plenary.busted | mini.test | neotest | **spec.nvim** |
|---|---|---|---|---|
| Dependency | plenary | mini.nvim | Adapter | lib.nvim (hat man eh) |
| Isolation | ❌ | ✅ | n/a | ✅ opt-in |
| Alle Fehler/Datei | ❌ | ✅ | n/a | ✅ |
| Diff-Ausgabe | ❌ | teilw. | n/a | ✅ |
| Async-nativ | ❌ | ❌ | n/a | ✅ |
| CI-Exit-Code | ⚠️ flaky | ✅ | ✅ | ✅ |
| Windows-first | ❌ | ⚠️ | ⚠️ | ✅ |
| Läuft bestehende Specs | ❌ | ❌ | ❌ | ✅ **alle 4 Dialekte** |
| Affected-Selection | ❌ | ❌ | ❌ | ✅ (§9) |
| Multilang | ❌ | ❌ | ✅ | ✅ (§7) |
| Mutation/Property | ❌ | ❌ | ❌ | ✅ (§11) |

`mini.test` ist die ernsthafteste Alternative. Der harte Grund dagegen ist
K1: es kann die ~550 bestehenden Specs nicht ausführen. Ehrlich als Risiko
in §15.

## 6. Architektur

Konventionen wie überall (`lua/spec/`, Modul pro Verzeichnis, `@types/`,
README je Modul):

```
lua/spec/
├── init.lua               -- Facade + setup()
├── core/
│   ├── suite.lua          -- Suite/Case-Modell (lib.lua.class)
│   ├── assert.lua         -- sammelnde Assertions
│   ├── render.lua         -- Fehlerdarstellung (lib.lua.diff.myers)
│   └── result.lua         -- ⭐ Ergebnis-IR: sprach- und dialektunabhängig
├── dialect/               -- ⭐ Kompatibilität (K1)
│   ├── harness_{a,c,d}.lua
│   └── busted.lua
├── lang/                  -- ⭐ Sprach-Backends (§7)
│   ├── init.lua           -- Registry
│   ├── lua.lua            -- nativ, in-process oder Kind-nvim
│   ├── jsts.lua           -- vitest/jest --reporter=json
│   ├── go.lua             -- go test -json
│   ├── python.lua         -- pytest --json-report
│   └── rust.lua           -- cargo test --format json
├── run/
│   ├── inproc.lua         -- schnell, geteilter State
│   ├── pool.lua           -- ⭐ paralleler Worker-Pool (§9)
│   └── watch.lua          -- Re-Run bei Änderung
├── cache/                 -- ⭐ content-addressed (§9)
│   ├── hash.lua
│   └── graph.lua          -- Abhängigkeiten via documentation.nvim
├── guard/                 -- ⭐ Safety (§10)
│   ├── fs.lua             -- Schreibzugriffe außerhalb tmpdir
│   ├── state.lua          -- Leak-Erkennung
│   └── clock.lua          -- Determinismus
├── advanced/              -- §11
│   ├── property.lua
│   ├── mutation.lua
│   ├── snapshot.lua
│   └── flaky.lua
├── report/
│   ├── term.lua           -- (lib.lua.strings.width)
│   ├── json.lua  junit.lua  markdown.lua  pdf.lua
│   └── ui.lua             -- (lib.nvim.ui.kit)
└── discover.lua
```

**Der Dreh- und Angelpunkt ist `core/result.lua`.** Ein einziges,
sprach- und dialektunabhängiges Ergebnis-IR. Alles danach — Reporter,
Cache, Dashboard, PDF, neotest-Adapter — arbeitet nur gegen dieses IR und
funktioniert dadurch für **jede** Sprache und **jeden** Dialekt
automatisch. Derselbe IR-Trick, den `documentation.nvim` für seinen Scan
schon benutzt.

## 7. Multilang

`documentation.nvim` hat mit `docs/ROADMAP/MULTILANG.md` bereits eine
durchgerechnete Multilang-Architektur (tree-sitter-Backends, JS/TS zuerst).
**Dieselbe Struktur hier übernehmen**, statt eine zweite zu erfinden.

Ein Sprach-Backend implementiert genau vier Funktionen:

```lua
---@class Spec.Lang.Backend
---@field detect      fun(root: string): boolean          -- ist das ein X-Projekt?
---@field discover    fun(root: string): Spec.File[]      -- welche Dateien sind Specs?
---@field run         fun(files, opts, on_done)           -- ausführen
---@field parse       fun(raw: string): Spec.Result       -- → gemeinsames IR
```

Der Clou: **die meisten Test-Runner können bereits JSON.** Ein Backend ist
damit überwiegend Subprozess + Feldmapping — `lib.nvim.system.job` +
`lib.nvim.json`, beides vorhanden:

| Sprache | Kommando | Aufwand |
|---|---|---|
| **Lua** | nativ (in-process / Kind-nvim) | Kern, Phase 0 |
| **JS/TS** | `vitest --reporter=json`, `jest --json` | niedrig |
| **Go** | `go test -json` | niedrig |
| **Python** | `pytest --json-report` | niedrig |
| **Rust** | `cargo test -- -Z unstable-options --format json` | mittel |
| **Shell** | `bats --formatter tap` | niedrig (TAP-Parser) |

Nutzen über die eigene Plugin-Welt hinaus: `portfolio-next-ts`,
`template_bun_nest_next`, `docmap-desktop`, `loomAI` sind
Nicht-Lua-Projekte im selben `$REPOS_DIR`. Ein Runner, der alle abdeckt,
macht Cache (§9), Affected-Selection (§9) und Dashboard (K7)
**sprachübergreifend** — und *das* kann neotest nicht, weil es pro Adapter
isoliert bleibt und kein gemeinsames IR mit Cache/Graph darunter hat.

## 8. Öffentliche API

```lua
local spec = require("spec")

return spec.describe("lib.nvim.fs.watch", function(t)
  t.test("fires on a real write", function(a)
    local dir = a.tmpdir()                 -- auto-cleanup
    local handle = watch.start(dir, on_change)
    a.defer(handle.stop)                   -- garantiert (context_manager)

    a.eq(calls, 0, "no callback before any write")
    a.write(dir .. "/x.txt", "hi")
    a.eventually(function() return calls >= 1 end, "callback fires")
  end)

  t.test("await statt polling", function(a)
    local err, stat = a.await(uv.fs_stat, path)   -- lib.nvim.async.wrap
    a.eq(err, nil)
    a.eq(stat.type, "file")
  end)

  t.prop("json round-trips", spec.gen.table(), function(a, value)  -- §11
    a.eq(json.decode(json.encode(value)), value)
  end)
end)
```

`a.eq` **sammelt**, statt abzubrechen (P1). Ein Block ohne jede Assertion
gilt als Fehler (P4).

**CLI:**

```sh
nvim --headless -l spec.lua                    # alles
nvim --headless -l spec.lua --affected         # ⭐ nur von HEAD~1 betroffene (§9)
nvim --headless -l spec.lua --cached           # ⭐ unveränderte überspringen (§9)
nvim --headless -l spec.lua --jobs 8           # ⭐ parallel (§9)
nvim --headless -l spec.lua --isolated         # Kind-nvim pro Datei
nvim --headless -l spec.lua --shuffle --seed 42
nvim --headless -l spec.lua --filter "CRLF" --file watch
nvim --headless -l spec.lua --json out.json --junit out.xml --pdf report.pdf
nvim --headless -l spec.lua --watch
nvim --headless -l spec.lua --mutate lua/lib/nvim/json   # §11
nvim --headless -l spec.lua --flaky 20                   # §11
```

## 9. Performance-Architektur

Ziel: **die volle Suite über alle 19 Repos in Sekunden, nicht Minuten.**

### F1 — Content-addressed Caching ⭐

Nach Vorbild von Bazel/Turborepo/Nx: Hash über (Spec-Datei + transitive
Abhängigkeiten + Runner-Version + relevante Env). Unveränderter Hash ⇒
Ergebnis aus dem Cache, Spec läuft gar nicht erst.

Bei ~550 Specs und typischerweise ein bis zwei geänderten Modulen ist das
der mit Abstand größte Hebel — Größenordnung 95 % Ersparnis im
Alltagslauf.

### F2 — Affected-Selection über den docmap-Graphen ⭐⭐

**Das ist das Feature, das kein generisches Framework haben kann.**

`documentation.nvim` extrahiert bereits `require`- und Call-Kanten
(`calls.lua`, `external_repos.lua`, `docs/map/module_map.json`). Damit
lässt sich der Graph *umkehren*: geänderte Datei → welche Module hängen
transitiv daran → welche Specs decken die ab.

```
git diff --name-only HEAD~1
  → lua/lib/nvim/json/init.lua
  → Reverse-Deps: fs.json, net.curl
  → betroffene Specs: nvim_helpers_spec, curl_spec
  → 2 statt 27 Spec-Dateien
```

Bazel/Nx machen das für Monorepos; hier fällt es praktisch **gratis** an,
weil der Graph bereits existiert und gepflegt wird.

### F3 — Paralleler Worker-Pool

N Kind-`nvim`-Prozesse, Work-Stealing-Queue, gedrosselt über
`lib.nvim.async.Semaphore` (gestern gebaut) und gestartet über
`lib.nvim.system.job`. Default `--jobs` = CPU-Kerne − 1.

Nur bei `--isolated` relevant; in-process bleibt einprozessig und schnell.

### F4 — Native Sidecar: ehrliche Analyse

In [RULES.md](RULES.md) steht die Frage schon: bringt ein
Rust/Go/Zig-Binary etwas? Nüchtern:

| Aufgabe | Sidecar sinnvoll? |
|---|---|
| Hashing von 550 Dateien + Deps (F1) | **Ja** — blake3 ist ~10× schneller als Lua-Hashing |
| Graph-Umkehrung + transitive Hülle (F2) | **Ja** bei großen Graphen; bei ~500 Modulen aber auch in Lua unter 50 ms |
| Diff großer Ausgaben (P8) | Grenzwertig — `lib.lua.diff.myers` reicht für Testausgaben |
| Test-Ausführung selbst | **Nein** — muss in `nvim` laufen |
| JSON-Parsing der Fremd-Runner | **Nein** — `vim.json` ist C |
| Mutation-Testing-AST (§11) | **Ja**, aber tree-sitter ist bereits nativ da |

**Empfehlung:** Sidecar **nicht** in Phase 0–5. Der ehrliche Flaschenhals
ist Prozess-Start von `nvim` (~50–150 ms), nicht Lua-Rechenzeit — dagegen
hilft F1/F2 (gar nicht erst starten) um Größenordnungen mehr als ein
schnellerer Hasher. Falls doch: optionaler Beschleuniger mit
Pure-Lua-Fallback, nie Pflicht — sonst kostet es plattformspezifische
Prebuilt-Binaries und eine Bauinfrastruktur, die ein Neovim-Plugin
schlecht trägt.

## 10. Safety & Determinismus

Was heutige Frameworks schlicht nicht anbieten:

| Guard | Umsetzung | Fängt |
|---|---|---|
| **FS-Guard** | `lib.nvim.fs.watch` auf Repo-Root während des Laufs | Specs, die außerhalb ihres tmpdir schreiben — heute unbemerkt bis das Repo dreckig ist |
| **State-Leak-Guard** | Snapshot von Autocmds/Keymaps/Buffers/`vim.g` vor+nach jeder Spec, Diff via `lib.lua.diff` | Ursache von P3. `debugging.nvim` auditiert Autocmds bereits statisch-vs-laufzeit — dasselbe Verfahren |
| **Timeout je Test** | `lib.nvim.async` + harter Kill | Hängende Specs, die heute die CI blockieren |
| **Netz-Guard** | `vim.system`/socket-Wrapper zählt Verbindungen | Versehentlich echte Netzwerkzugriffe |
| **Determinismus** | eingefrorene Uhr + geseedete `math.random` | Zeit-/Zufallsabhängige Flakes |
| **Shuffle + Seed** | reproduzierbare Reihenfolge | Reihenfolge-Abhängigkeiten (P3) |

Der State-Leak-Guard ist der wertvollste: er verwandelt „irgendwann kippt
eine Spec" in eine sofortige, benannte Meldung — *„`foo_spec` hinterlässt
Autocmd `X` in Gruppe `Y`"*.

## 11. Fortgeschrittene Testarten

### Property-based Testing (`a.prop`)

Generatoren + Shrinking (QuickCheck-Stil). Für eine Bibliothek wie
`lib.nvim` außerordentlich passend, weil es dort viele echte Invarianten
gibt:

```lua
t.prop("json round-trip", spec.gen.value(), function(a, v)
  a.eq(json.decode(json.encode(v)), v)
end)
t.prop("display_width >= 0", spec.gen.utf8_string(), function(a, s)
  a.ok(width.display_width(s) >= 0)
end)
t.prop("truncate hält das Budget ein", spec.gen.utf8_string(), spec.gen.int(0, 40),
  function(a, s, n) a.ok(width.display_width(width.truncate(s, n)) <= n) end)
```

Shrinking (minimales Gegenbeispiel finden) ist der Teil mit echtem
Aufwand — aber auch der mit dem größten Aha-Effekt.

### Mutation Testing (`--mutate`) — Antwort auf P10

Cutting edge und direkt nützlich: tree-sitter mutiert gezielt den Code
(`>=`→`>`, `and`→`or`, `true`→`false`, Zweig entfernen) und prüft, ob
*irgendeine* Spec anschlägt. Überlebt ein Mutant, ist die Stelle nur
scheinbar getestet.

Das beantwortet erstmals *„sind meine 137 Specs eigentlich gut?"* statt
nur *„sind sie grün?"*. Teuer im Lauf — aber F1/F2 machen es überhaupt
erst praktikabel, weil pro Mutant nur die betroffenen Specs laufen.

### Snapshot / Golden Files

`a.snapshot(name, value)` — erster Lauf schreibt, danach vergleicht;
Abweichung wird über `diff.nvim` gerendert, Update via `--update-snapshots`.
Ideal für die vielen Render-/Format-Ausgaben (`markdown.nvim`,
`documentation.nvim`-HTML, `ui.kit`-Layouts).

### Flaky-Erkennung (`--flaky N`)

Verdächtige Specs N-mal laufen lassen, Instabilität statistisch melden,
optional Quarantäne-Liste. Adressiert P6 an der Wurzel statt am Symptom.

## 12. Ökosystem-Integration

Nur verifizierte Fähigkeiten der jeweiligen Plugins:

| Plugin | Cross-Feature | Richtung |
|---|---|---|
| **lib.nvim** | Fundament (§4) — und `spec.nvim` wird dessen größter Konsument, damit realer Härtetest für `async`/`fs.watch`/`context_manager`/`strings.width` | nutzt |
| **documentation.nvim** | ⭐ Abhängigkeitsgraph für F2 (Affected-Selection); umgekehrt docmap-Ansicht um „hat Specs / letzter Status" ergänzen. Multilang-Architektur als Vorlage (§7) | beide |
| **runtime-analysis.nvim** | Telemetrie beim Testlauf ⇒ **Coverage-Näherung ohne Coverage-Tool**: „diese 23 exportierten Funktionen ruft keine Spec auf". Für die 14 Repos ohne Specs zugleich die Antwort auf „wo anfangen" | nutzt |
| **diff.nvim** | Assertion-Diffs und Snapshot-Abweichungen im echten Diff-Viewer statt im Terminal | nutzt |
| **filetree.nvim** | Neo-tree-**Source** „Tests": Baum aus Suiten/Cases, Status-Icons, `<CR>` führt aus. Das Test-Explorer-UI, ohne eines zu bauen | nutzt |
| **pickers.nvim** | `:Pickers spec` — Spec/Case auswählen und ausführen; funktioniert über telescope/fzf/snacks gleichermaßen | nutzt |
| **pdfport.nvim** | ⭐ PDF-Report **ohne jede Erweiterung**: `pdfport.create{ text = report_md, from = "markdown", output = "…pdf" }` existiert bereits (`producers/`-Kette, `markdown`→`pandoc`, `html`→`weasyprint`/`chromium`). `can_create("markdown")` liefert die Verfügbarkeitsprüfung gleich mit — der PDF-Reporter ist damit ~20 Zeilen | nutzt |
| **markdown.nvim** | Markdown-Report rendern; Link-Auflösung für Verweise auf Modul-READMEs im Bericht | nutzt |
| **images.nvim** | Visuelle Diffs von Snapshot-Abweichungen als Bild darstellen | nutzt |
| **migrate.nvim** | ⭐ Dialekt-Migration A/B/C/D/E → neuer Stil als Codemod. Genau sein Zweck („deprecated API calls ausräumen") | erweitert |
| **insights.nvim** | ripgrep-Symbolindex ⇒ Gegenprobe „welches exportierte Symbol hat keine Spec" (statisch, komplementär zur Telemetrie) | nutzt |
| **debugging.nvim** | Fehlgeschlagene Spec direkt in den DAP-Lauf; sein Autocmd-Audit als Vorlage für den State-Leak-Guard (§10) | beide |
| **sandbox.nvim** | Isolierte Läufe in dessen Sandbox statt nackter Kind-`nvim` | nutzt |
| **github_stats.nvim** | JUnit ⇒ GH-Actions-Annotationen; Testtrends neben den Repo-Statistiken | erweitert |
| **test.nvim** (→ [test.md](./test.md)) | `neotest-spec`-Adapter: `spec.nvim` = Engine, `test.nvim` = Adapter/UI | beide |
| **spotlight.nvim / cmdlog.nvim** | keine sinnvolle Kopplung erkennbar — bewusst weggelassen | — |

## 13. Migrationsplan

| Phase | Inhalt | Abbruchkriterium |
|---|---|---|
| **0** | Kern + IR + Dialekt A. Muss `lib.nvim`s 137 Specs **unverändert** grün fahren. | Schafft er das nicht → Konzept kippen. |
| **1** | Dialekte B/C/D gegen `images`/`markdown`/`spotlight`/`diff`. |
| **2** | Fehler-Sammeln (P1), Assertion-Count (P4), Diff (P8), Filter (P5). Ab hier Mehrwert bei null Migrationskosten. |
| **3** | Isolation + Shuffle + State-Leak-Guard. Erwartung: deckt bestehende Reihenfolge-Abhängigkeiten auf — das ist Erfolg, nicht Fehlschlag. |
| **4** | F1 Cache + F2 Affected-Selection. Der Punkt, ab dem es sich schneller anfühlt als alles andere. |
| **5** | Dialekt E ⇒ plenary aus `dap`/`sandbox`/`github_stats`-CI werfen. |
| **6** | Multilang: JS/TS zuerst (`portfolio-next-ts`, `docmap-desktop`), dann Go/Python. |
| **7** | Reporter: JSON/JUnit/Markdown/PDF, UI-Report, neo-tree-Source, Picker. |
| **8** | Property-based, Snapshot, Flaky. |
| **9** | Mutation Testing + Coverage-Näherung (runtime-analysis). |

Phase 0 ist bewusst als **Falsifikationstest** gebaut: `lib.nvim` ist mit
137 Specs und der bekannt umgebungsabhängigen `telemetry_wrap_spec` der
härteste Fall. Läuft der nicht sauber, ist die Idee widerlegt, bevor
nennenswert Arbeit hineinfließt.

## 14. Dokumentationspflichten

README je Modul, `@types/` für alle öffentlichen Typen, `:help spec.nvim`,
`docs/modules.md`-Eintrag, `docs/FEATURES/`-Seite je Killer-Feature — und
`spec.nvim` testet sich selbst mit sich selbst (der ehrlichste
Dogfood-Test, den es gibt).

## 15. Offene Fragen / Risiken

- **NIH-Falle.** Ein eigenes Test-Framework zu bauen ist ein klassischer
  Fehler. Gegenargument: es sind bereits 16 gebaut worden; die Frage ist
  nicht *ob*, sondern nur, ob sie konsolidiert werden. Bleibt trotzdem der
  ehrlichste Einwand gegen das gesamte Konzept.
- **Scope-Explosion.** §9–§11 beschreiben zusammen eher ein
  Build-System-mit-Testrunner als einen Testrunner. Realistisch sind
  Phase 0–5 das Produkt; alles danach ist optional und darf nie Bedingung
  für den Nutzen der frühen Phasen werden.
- **`mini.test` ist gut.** Isolation hat es fertig. Einziger harter Grund
  dagegen ist K1 (~550 nicht-portable Specs). Wer bereit wäre, alle
  umzuschreiben, sollte `mini.test` ernsthaft prüfen statt zu bauen.
- **Zirkuläre Abhängigkeit.** `spec.nvim` hängt hart an `lib.nvim`, und
  `lib.nvim` würde es zum Testen nutzen — ein `lib.nvim`-Bug kann dann
  seinen eigenen Test verstecken. Gegenmittel: `lib.nvim` behält einen
  minimalen Bootstrap-Harness für die Kernmodule (`error`, `async`, `fs`)
  und nutzt `spec.nvim` erst darüber. **Vor Phase 0 entscheiden.**
- **F2 hängt an documentation.nvim.** Wenn dessen Graph unvollständig ist,
  überspringt Affected-Selection Specs, die hätten laufen müssen —
  gefährlicher als zu viel laufen zu lassen. Deshalb: `--affected` niemals
  Default in CI, dort immer voller Lauf; `--affected` ist ein
  Entwickler-Werkzeug.
- **Cache-Invalidierung.** Der klassische Fehlerfall. Hash muss Env,
  Neovim-Version und Runner-Version einschließen; im Zweifel lieber zu oft
  invalidieren. `--no-cache` muss immer funktionieren.
- **Dialekt-Erkennung heuristisch.** Signatur-Sniffing kann danebenliegen;
  Fallback: explizite Markierung pro Repo (`.spec.json`).
- **Isolation kostet.** Kind-Prozess pro Datei ist bei 137 Specs spürbar
  langsamer — muss opt-in bleiben, nicht Default.
- **14 Repos ohne Specs** werden durch einen besseren Runner nicht
  automatisch getestet. Er senkt die Hürde und priorisiert (Coverage-
  Näherung), schreibt aber keine Tests.
