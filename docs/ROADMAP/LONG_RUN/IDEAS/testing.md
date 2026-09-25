# Test-Strategie: `spec.nvim`, `test.nvim` und synthetische Feature-Tests

> Ersetzt `spec.nvim.md` und `test.md` (beide Stand vor 2026-09-20, Inhalt
> hier vollständig übernommen). Zusammengeführt, weil
> alle drei Themen eine einzige Fragestellung sind — *wie testet die eigene
> Plugin-Flotte sich selbst* — nur auf drei verschiedenen Ebenen:

| Teil | Ebene | Kernfrage | Status |
|---|---|---|---|
| **A** — `spec.nvim` | Engine | Wie werden ~550 Specs über 19 Repos in 4 inkompatiblen Dialekten konsolidiert, gecacht, parallelisiert? | Konzept, Phase-0-Falsifikationstest offen |
| **B** — `test.nvim` | UI/Adapter | Wie wird die bestehende neotest-Config (Adapter/Commands/Neo-tree-Bridge) aus dem Host in ein eigenständiges Plugin ausgelagert? | Konzept, Auslagerung befürwortet |
| **C** — Synthetische Feature-Tests | Neue Testart | Wie testet man automatisiert das, was heute nur live geprüft werden kann (Keybindings, Notifies, Terminal-Grafik, Browser-Ausgabe, native App)? | Analyse + Konzept, diese Runde |
| **D** — Überarbeitung v2 | Zielbild + Plan | Was an A–C stimmt, was verifiziert falsch ist, und wie Architektur, Performance, Features, Security und ein Meilensteinplan konkret aussehen | Ausgearbeitet 2026-09-20, **bei Widerspruch gilt D** |

**Geltung:** Teile A–C sind die Basis und bleiben als Herleitung unverändert
stehen. Teil D ([§D.1](#d1-analyse-des-bisherigen-konzepts)) listet die
verifizierten Korrekturen und ersetzt an diesen Stellen A–C. Wer nur das
Zielbild braucht, liest D.

**Wie sie zusammenhängen:** `spec.nvim` ist die Ausführungs-Engine (Discovery,
IR, Cache, Parallelisierung). `test.nvim` ist die Neovim-seitige
UI/Adapter-Schicht, die Ergebnisse anzeigt (Neo-tree-Source, Picker,
Commands) — beide waren schon in der ursprünglichen `spec.nvim`-Fassung als
„Engine vs. Adapter/UI" sauber getrennt (s. [§A.12](#a12-ökosystem-integration)).
Synthetische Feature-Tests (Teil C) sind **keine vierte Komponente**,
sondern schlicht eine neue *Testart*, die durch dieselbe Engine laufen und
in derselben UI erscheinen soll — Details dazu in
[§C.5](#c5-einordnung-in-specnvim-die-libnvim-frage).

---

## Teil A — `spec.nvim`: Test-Runner-Konsolidierung

Ein multilang-fähiger Test-Runner für die eigene Plugin-Welt, gebaut auf
`lib.nvim`.

**Ergebnis vorab: Ja, lohnt sich** — aber nicht mit der Begründung "es fehlt
ein Test-Framework". Der Befund ist: **es existieren bereits 16 davon, in 4
zueinander inkompatiblen Dialekten**, `lib.nvim` hat seit 2026-08-17 genau
die Bausteine, an denen plenary/busted schwach sind, und
`documentation.nvim` liefert einen Abhängigkeitsgraphen, mit dem sich
Dinge bauen lassen, die **kein generisches Test-Framework kann** (§A.9).

### Inhalt Teil A

- [A.1 Ist-Zustand](#a1-ist-zustand)
- [A.2 Die vier Dialekte](#a2-die-vier-dialekte)
- [A.3 Konkrete Probleme im Ist-Zustand](#a3-konkrete-probleme-im-ist-zustand)
- [A.4 Warum jetzt: lib.nvim liefert die Bausteine](#a4-warum-jetzt-libnvim-liefert-die-bausteine)
- [A.5 Abgrenzung zu bestehenden Frameworks](#a5-abgrenzung-zu-bestehenden-frameworks)
- [A.6 Architektur](#a6-architektur)
- [A.7 Multilang](#a7-multilang)
- [A.8 Öffentliche API](#a8-öffentliche-api)
- [A.9 Performance-Architektur](#a9-performance-architektur)
- [A.10 Safety & Determinismus](#a10-safety--determinismus)
- [A.11 Fortgeschrittene Testarten](#a11-fortgeschrittene-testarten)
- [A.12 Ökosystem-Integration](#a12-ökosystem-integration)
- [A.13 Migrationsplan](#a13-migrationsplan)
- [A.14 Dokumentationspflichten](#a14-dokumentationspflichten)
- [A.15 Offene Fragen / Risiken](#a15-offene-fragen--risiken)

### A.1 Ist-Zustand

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

### A.2 Die vier Dialekte

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

### A.3 Konkrete Probleme im Ist-Zustand

| # | Problem | Evidenz |
|---|---|---|
| **P1** | Erster fehlgeschlagener Assert killt die Datei (`pcall` + `error`). Bei 137 Specs sieht man einen Fehler pro Lauf. | alle außer D |
| **P2** | Specs nicht portabel; Harness-Verbesserungen propagieren nicht. | §A.2 |
| **P3** | Keine Isolation. Reihenfolge-Abhängigkeiten bleiben unsichtbar. | `telemetry_wrap_spec` |
| **P4** | Stille No-Op-Specs melden `ok`. Kein Assertion-Count. | alle außer D |
| **P5** | Kein Filtern — immer die volle Suite. | alle `run.lua` |
| **P6** | `PlenaryBustedDirectory` liefert in CI teils `0` trotz Fehlern. | dap, sandbox, github_stats |
| **P7** | Windows zweitklassig (CRLF, Separatoren, `fs_event`-Handles). | quer durch alle Repos |
| **P8** | Fehlerausgabe = zwei `vim.inspect`-Wände, kein Diff. | alle |
| **P9** | Async-Tests sind handgerolltes `vim.wait`-Polling. | `async_spec`, `watch_spec`, `curl_spec`, … |
| **P10** | Keine Aussage über *Test-Qualität*. 137 grüne Specs sagen nicht, ob sie Fehler fangen würden. | — |

### A.4 Warum jetzt: lib.nvim liefert die Bausteine

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
| Notify-Interception (Teil C) | `lib.nvim.notify` | vorhanden, **nicht 100 % zentralisiert** — s. [§C.2](#c2-bestandsaufnahme-recherche-2026-09-20) |

`spec.nvim` wäre also überwiegend **Verdrahtung getesteter Bausteine** —
genau das, was plenary jeweils selbst mitbringen muss, und schlechter.

### A.5 Abgrenzung zu bestehenden Frameworks

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
| Affected-Selection | ❌ | ❌ | ❌ | ✅ (§A.9) |
| Multilang | ❌ | ❌ | ✅ | ✅ (§A.7) |
| Mutation/Property | ❌ | ❌ | ❌ | ✅ (§A.11) |
| Screen-Snapshot (Teil C) | ❌ | ✅ | n/a | geplant (§C.7) |

`mini.test` ist die ernsthafteste Alternative. Der harte Grund dagegen ist
K1: es kann die ~550 bestehenden Specs nicht ausführen. Ehrlich als Risiko
in §A.15. Für Teil C (Screen-Snapshots) bleibt `mini.test` trotzdem die
Referenz für das *Verfahren*, auch wenn `spec.nvim` die Ausführung übernimmt
— s. [§C.7](#c7-existierende-bausteine--nicht-neu-erfinden).

### A.6 Architektur

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
├── lang/                  -- ⭐ Sprach-/Runner-Backends (§A.7, §C.5)
│   ├── init.lua           -- Registry
│   ├── lua.lua            -- nativ, in-process oder Kind-nvim
│   ├── jsts.lua           -- vitest/jest --reporter=json
│   ├── go.lua             -- go test -json
│   ├── python.lua         -- pytest --json-report
│   ├── rust.lua           -- cargo test --format json
│   └── vhs.lua / playwright.lua / webdriver.lua  -- ⭐ Teil C, gleiches Interface
├── run/
│   ├── inproc.lua         -- schnell, geteilter State
│   ├── pool.lua           -- ⭐ paralleler Worker-Pool (§A.9)
│   └── watch.lua          -- Re-Run bei Änderung
├── cache/                 -- ⭐ content-addressed (§A.9)
│   ├── hash.lua
│   └── graph.lua          -- Abhängigkeiten via documentation.nvim
├── guard/                 -- ⭐ Safety (§A.10)
│   ├── fs.lua             -- Schreibzugriffe außerhalb tmpdir
│   ├── state.lua          -- Leak-Erkennung
│   └── clock.lua          -- Determinismus
├── advanced/              -- §A.11
│   ├── property.lua
│   ├── mutation.lua
│   ├── snapshot.lua
│   ├── flaky.lua
│   └── synthetic/         -- ⭐ Teil C: feedkeys/screen/notify-Helper
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
schon benutzt. Genau dieses IR ist auch der Anschlusspunkt für Teil C
(synthetische Tests liefern dasselbe Result-IR wie ein Lua-Unit-Test).

### A.7 Multilang

`documentation.nvim` hat mit `docs/ROADMAP/MULTILANG.md` bereits eine
durchgerechnete Multilang-Architektur (tree-sitter-Backends, JS/TS zuerst).
**Dieselbe Struktur hier übernehmen**, statt eine zweite zu erfinden.

> **Korrektur 2026-09-20 (§D.1):** diese Datei existiert nicht (kein
> `docs/ROADMAP/` in documentation.nvim). Das Vier-Funktionen-Interface unten
> steht für sich; es gibt keine Vorlage zu übernehmen.

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
macht Cache (§A.9), Affected-Selection (§A.9) und Dashboard (K7)
**sprachübergreifend** — und *das* kann neotest nicht, weil es pro Adapter
isoliert bleibt und kein gemeinsames IR mit Cache/Graph darunter hat.

**Dieselbe Vier-Funktionen-Schnittstelle trägt auch Teil C:** ein
`lang/vhs.lua` (Terminal-Aufzeichnung, §C.7) oder `lang/playwright.lua`
(Browser, §C.7) ist strukturell dasselbe wie `lang/go.lua` — Subprozess
starten, JSON/Ergebnis parsen, ins gemeinsame IR gießen. Kein Sonderpfad
nötig.

### A.8 Öffentliche API

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

  t.prop("json round-trips", spec.gen.table(), function(a, value)  -- §A.11
    a.eq(json.decode(json.encode(value)), value)
  end)
end)
```

`a.eq` **sammelt**, statt abzubrechen (P1). Ein Block ohne jede Assertion
gilt als Fehler (P4).

**CLI:**

```sh
nvim --headless -l spec.lua                    # alles
nvim --headless -l spec.lua --affected         # ⭐ nur von HEAD~1 betroffene (§A.9)
nvim --headless -l spec.lua --cached           # ⭐ unveränderte überspringen (§A.9)
nvim --headless -l spec.lua --jobs 8           # ⭐ parallel (§A.9)
nvim --headless -l spec.lua --isolated         # Kind-nvim pro Datei
nvim --headless -l spec.lua --shuffle --seed 42
nvim --headless -l spec.lua --filter "CRLF" --file watch
nvim --headless -l spec.lua --json out.json --junit out.xml --pdf report.pdf
nvim --headless -l spec.lua --watch
nvim --headless -l spec.lua --mutate lua/lib/nvim/json   # §A.11
nvim --headless -l spec.lua --flaky 20                   # §A.11
```

### A.9 Performance-Architektur

Ziel: **die volle Suite über alle 19 Repos in Sekunden, nicht Minuten.**

#### F1 — Content-addressed Caching ⭐

Nach Vorbild von Bazel/Turborepo/Nx: Hash über (Spec-Datei + transitive
Abhängigkeiten + Runner-Version + relevante Env). Unveränderter Hash ⇒
Ergebnis aus dem Cache, Spec läuft gar nicht erst.

Bei ~550 Specs und typischerweise ein bis zwei geänderten Modulen ist das
der mit Abstand größte Hebel — Größenordnung 95 % Ersparnis im
Alltagslauf.

#### F2 — Affected-Selection über den docmap-Graphen ⭐⭐

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

#### F3 — Paralleler Worker-Pool

N Kind-`nvim`-Prozesse, Work-Stealing-Queue, gedrosselt über
`lib.nvim.async.Semaphore` (gestern gebaut) und gestartet über
`lib.nvim.system.job`. Default `--jobs` = CPU-Kerne − 1.

Nur bei `--isolated` relevant; in-process bleibt einprozessig und schnell.

#### F4 — Native Sidecar: ehrliche Analyse

In `RULES.md` steht die Frage schon: bringt ein Rust/Go/Zig-Binary etwas?
Nüchtern:

| Aufgabe | Sidecar sinnvoll? |
|---|---|
| Hashing von 550 Dateien + Deps (F1) | **Ja** — blake3 ist ~10× schneller als Lua-Hashing |
| Graph-Umkehrung + transitive Hülle (F2) | **Ja** bei großen Graphen; bei ~500 Modulen aber auch in Lua unter 50 ms |
| Diff großer Ausgaben (P8) | Grenzwertig — `lib.lua.diff.myers` reicht für Testausgaben |
| Test-Ausführung selbst | **Nein** — muss in `nvim` laufen |
| JSON-Parsing der Fremd-Runner | **Nein** — `vim.json` ist C |
| Mutation-Testing-AST (§A.11) | **Ja**, aber tree-sitter ist bereits nativ da |

**Empfehlung:** Sidecar **nicht** in Phase 0–5. Der ehrliche Flaschenhals
ist Prozess-Start von `nvim` (~50–150 ms), nicht Lua-Rechenzeit — dagegen
hilft F1/F2 (gar nicht erst starten) um Größenordnungen mehr als ein
schnellerer Hasher. Falls doch: optionaler Beschleuniger mit
Pure-Lua-Fallback, nie Pflicht — sonst kostet es plattformspezifische
Prebuilt-Binaries und eine Bauinfrastruktur, die ein Neovim-Plugin
schlecht trägt.

### A.10 Safety & Determinismus

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
Autocmd `X` in Gruppe `Y`"*. Für Teil C ist derselbe Guard sogar wichtiger
als für Unit-Tests: ein Feature-Test, der reale Keymaps/Autocmds/Buffer
anfasst, hinterlässt viel leichter Zustand als eine reine Funktionsprüfung.

### A.11 Fortgeschrittene Testarten

#### Property-based Testing (`a.prop`)

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

#### Mutation Testing (`--mutate`) — Antwort auf P10

Cutting edge und direkt nützlich: tree-sitter mutiert gezielt den Code
(`>=`→`>`, `and`→`or`, `true`→`false`, Zweig entfernen) und prüft, ob
*irgendeine* Spec anschlägt. Überlebt ein Mutant, ist die Stelle nur
scheinbar getestet.

Das beantwortet erstmals *„sind meine 137 Specs eigentlich gut?"* statt
nur *„sind sie grün?"*. Teuer im Lauf — aber F1/F2 machen es überhaupt
erst praktikabel, weil pro Mutant nur die betroffenen Specs laufen.

#### Snapshot / Golden Files

`a.snapshot(name, value)` — erster Lauf schreibt, danach vergleicht;
Abweichung wird über `diff.nvim` gerendert, Update via `--update-snapshots`.
Ideal für die vielen Render-/Format-Ausgaben (`markdown.nvim`,
`documentation.nvim`-HTML, `ui.kit`-Layouts) — und für die
Screen-Grid-Snapshots aus Teil C ([§C.4](#c4-die-test-pyramide), Tier 2).

#### Flaky-Erkennung (`--flaky N`)

Verdächtige Specs N-mal laufen lassen, Instabilität statistisch melden,
optional Quarantäne-Liste. Adressiert P6 an der Wurzel statt am Symptom.

#### Synthetische/E2E-Tests (`a.feedkeys`, `a.screen`, `a.notify`) — ⭐ Teil C

Fünfte Kategorie, ausgearbeitet in [Teil C](#teil-c--synthetische-feature-tests-analyse--konzept):
RPC-getriebene Feature/Binding-Tests, Screen-Grid-Snapshots und
Real-Rendering-Backends (Terminal/Browser/native App) über dasselbe
`lang/`-Interface wie §A.7.

### A.12 Ökosystem-Integration

Nur verifizierte Fähigkeiten der jeweiligen Plugins:

| Plugin | Cross-Feature | Richtung |
|---|---|---|
| **lib.nvim** | Fundament (§A.4) — und `spec.nvim` wird dessen größter Konsument, damit realer Härtetest für `async`/`fs.watch`/`context_manager`/`strings.width` | nutzt |
| **documentation.nvim** | ⭐ Abhängigkeitsgraph für F2 (Affected-Selection); umgekehrt docmap-Ansicht um „hat Specs / letzter Status" ergänzen. Multilang-Architektur als Vorlage (§A.7) | beide |
| **runtime-analysis.nvim** | Telemetrie beim Testlauf ⇒ **Coverage-Näherung ohne Coverage-Tool**: „diese 23 exportierten Funktionen ruft keine Spec auf". Für die 14 Repos ohne Specs zugleich die Antwort auf „wo anfangen" | nutzt |
| **diff.nvim** | Assertion-Diffs und Snapshot-Abweichungen im echten Diff-Viewer statt im Terminal | nutzt |
| **filetree.nvim** | Neo-tree-**Source** „Tests": Baum aus Suiten/Cases, Status-Icons, `<CR>` führt aus. Das Test-Explorer-UI, ohne eines zu bauen | nutzt |
| **pickers.nvim** | `:Pickers spec` — Spec/Case auswählen und ausführen; funktioniert über telescope/fzf/snacks gleichermaßen | nutzt |
| **pdfport.nvim** | ⭐ PDF-Report **ohne jede Erweiterung**: `pdfport.create{ text = report_md, from = "markdown", output = "…pdf" }` existiert bereits (`producers/`-Kette, `markdown`→`pandoc`, `html`→`weasyprint`/`chromium`). `can_create("markdown")` liefert die Verfügbarkeitsprüfung gleich mit — der PDF-Reporter ist damit ~20 Zeilen | nutzt |
| **markdown.nvim** | Markdown-Report rendern; Link-Auflösung für Verweise auf Modul-READMEs im Bericht | nutzt |
| **images.nvim** | Visuelle Diffs von Snapshot-Abweichungen als Bild darstellen — und selbst **Testobjekt** für Teil C (Tier 3, echtes Terminal-Rendering) | beide |
| **migrate.nvim** | ⭐ Dialekt-Migration A/B/C/D/E → neuer Stil als Codemod. Genau sein Zweck („deprecated API calls ausräumen") | erweitert |
| **insights.nvim** | ripgrep-Symbolindex ⇒ Gegenprobe „welches exportierte Symbol hat keine Spec" (statisch, komplementär zur Telemetrie) | nutzt |
| **debugging.nvim** | Fehlgeschlagene Spec direkt in den DAP-Lauf; sein Autocmd-Audit als Vorlage für den State-Leak-Guard (§A.10) | beide |
| **sandbox.nvim** | ~~Isolierte Läufe in dessen Sandbox statt nackter Kind-`nvim`~~ — **Korrektur §D.1:** sandbox.nvim ist ein Container-Engine-Frontend (Podman/Docker/nerdctl), kein Kind-nvim-Isolator. Relevant als *Container*-Ebene für Tier 3 und als echte Sicherheitsgrenze (§D.8), nicht für Spec-Isolation | nutzt (Tier 3) |
| **github_stats.nvim** | JUnit ⇒ GH-Actions-Annotationen; Testtrends neben den Repo-Statistiken | erweitert |
| **test.nvim** (→ [Teil B](#teil-b--testnvim-neotest-auslagerung)) | `neotest-spec`-Adapter: `spec.nvim` = Engine, `test.nvim` = Adapter/UI | beide |
| **mdview.nvim** | Testobjekt für Teil C (Tier 3, echter Browser) | wird genutzt von |
| **docmap-desktop** | Testobjekt für Teil C (Tier 3, WebDriver/`tauri-driver`) | wird genutzt von |
| **spotlight.nvim / cmdlog.nvim** | keine sinnvolle Kopplung erkennbar — bewusst weggelassen | — |

### A.13 Migrationsplan

| Phase | Inhalt | Abbruchkriterium |
|---|---|---|
| **0** | Kern + IR + Dialekt A. Muss `lib.nvim`s 137 Specs **unverändert** grün fahren. | Schafft er das nicht → Konzept kippen. |
| **1** | Dialekte B/C/D gegen `images`/`markdown`/`spotlight`/`diff`. | — |
| **2** | Fehler-Sammeln (P1), Assertion-Count (P4), Diff (P8), Filter (P5). Ab hier Mehrwert bei null Migrationskosten. | — |
| **3** | Isolation + Shuffle + State-Leak-Guard. Erwartung: deckt bestehende Reihenfolge-Abhängigkeiten auf — das ist Erfolg, nicht Fehlschlag. **Voraussetzung für Teil C/Tier 1** (§C.4), weil Feature-Tests ohne Isolation Zustand zwischen sich hinterlassen. | — |
| **4** | F1 Cache + F2 Affected-Selection. Der Punkt, ab dem es sich schneller anfühlt als alles andere. | — |
| **5** | Dialekt E ⇒ plenary aus der CI werfen. **Veraltet:** ursprünglich nur `dap`/`sandbox`/`github_stats`, seit §B.11-Update 2026-09-22 alle elf betroffenen Repos (Liste dort). | — |
| **6** | Multilang: JS/TS zuerst (`portfolio-next-ts`, `docmap-desktop`), dann Go/Python. | — |
| **7** | Reporter: JSON/JUnit/Markdown/PDF, UI-Report, neo-tree-Source, Picker. | — |
| **8** | Property-based, Snapshot, Flaky. | — |
| **9** | Mutation Testing + Coverage-Näherung (runtime-analysis). | — |
| **10** | ⭐ **Synthetische Tests (Teil C):** Tier 1 (RPC-Feature-Tests) als neue `dialect`/`advanced/synthetic`-Bausteine; Tier 3 (VHS/Playwright/tauri-driver) als neue `lang/`-Backends. Bewusst *nach* Phase 4, weil Tier-1-Tests am meisten von Isolation + Cache profitieren (teuerste Testart im Alltag). | Reihenfolge überholt durch §D.9 (M0–M9) |

Phase 0 ist bewusst als **Falsifikationstest** gebaut: `lib.nvim` ist mit
137 Specs und der bekannt umgebungsabhängigen `telemetry_wrap_spec` der
härteste Fall. Läuft der nicht sauber, ist die Idee widerlegt, bevor
nennenswert Arbeit hineinfließt.

### A.14 Dokumentationspflichten

README je Modul, `@types/` für alle öffentlichen Typen, `:help spec.nvim`,
`docs/modules.md`-Eintrag, `docs/FEATURES/`-Seite je Killer-Feature — und
`spec.nvim` testet sich selbst mit sich selbst (der ehrlichste
Dogfood-Test, den es gibt).

### A.15 Offene Fragen / Risiken

- **NIH-Falle.** Ein eigenes Test-Framework zu bauen ist ein klassischer
  Fehler. Gegenargument: es sind bereits 16 gebaut worden; die Frage ist
  nicht *ob*, sondern nur, ob sie konsolidiert werden. Bleibt trotzdem der
  ehrlichste Einwand gegen das gesamte Konzept.
- **Scope-Explosion.** §A.9–§A.11 beschreiben zusammen eher ein
  Build-System-mit-Testrunner als einen Testrunner. Realistisch sind
  Phase 0–5 das Produkt; alles danach ist optional und darf nie Bedingung
  für den Nutzen der frühen Phasen werden. Teil C (Phase 10) verschärft das
  noch — bewusst ganz ans Ende gesetzt.
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
- **Teil-C-Risiken** (VM/Browser/Terminal-Flakiness, Golden-Image-Drift)
  sind separat in [§C.10](#c10-offene-fragen--risiken) behandelt — sie
  betreffen nur `lang/vhs.lua`/`playwright.lua`/`webdriver.lua`, nicht den
  Kern aus Phase 0–9.

---

## Teil B — `test.nvim`: neotest-Auslagerung

Prüfung, ob eine Auslagerung von `nvim/lua/config/neotest/**` +
`nvim/lua/plugins/neotest.lua` in ein eigenständiges Plugin Sinn macht,
analog zu den bereits extrahierten `*.nvim`-Repos (`dap.nvim`,
`filetree.nvim`, ...) und den Konzepten `lsp.md` und `NEW_PLUGIN.md`.
Ausgangsfrage aus `00_MISC.md`: "Checken ob das sinn macht".

**Ergebnis vorab: Ja, es macht Sinn** — gleiche Begründung wie bei `dap.nvim`
(stateful Subsystem mit eigener Registry/State, kein deklaratives
Options-Bündel) — aber die Analyse hat unterwegs vier konkrete, unabhängig
vom Auslagerungs-Thema bestehende Inkonsistenzen im heutigen Code
aufgedeckt (§B.2), die bei der Migration mit-bereinigt werden sollten.

### Inhalt Teil B

- [B.1 Ist-Zustand](#b1-ist-zustand)
- [B.2 Gefundene Inkonsistenzen im Ist-Zustand](#b2-gefundene-inkonsistenzen-im-ist-zustand)
- [B.3 Lohnt sich die Auslagerung?](#b3-lohnt-sich-die-auslagerung)
- [B.4 Architektur / Modul-Mapping](#b4-architektur--modul-mapping)
- [B.5 lib.nvim-Integration](#b5-libnvim-integration)
- [B.6 Öffentliche API](#b6-öffentliche-api)
- [B.7 Dokumentationspflichten](#b7-dokumentationspflichten)
- [B.8 Migrationsplan](#b8-migrationsplan)
- [B.9 Brainstorm: fehlende / neue Features](#b9-brainstorm-fehlende--neue-features)
- [B.10 Offene Fragen / Risiken](#b10-offene-fragen--risiken)
- [B.11 Randnotiz: plenary.nvim ist nicht vollständig durch lib.nvim ersetzt](#b11-randnotiz-plenarynvim-ist-nicht-vollständig-durch-libnvim-ersetzt)

### B.1 Ist-Zustand

| Bereich | Pfad | Verantwortung |
|---|---|---|
| Plugin-Spec | `lua/plugins/neotest.lua` | Lazy-Spec für `nvim-neotest/neotest`, baut `opts` inline, ruft nach `neotest.setup()` sechs weitere Setup-Funktionen auf |
| Adapter (aktiv) | `opts.adapters` in `plugins/neotest.lua` | Hartcodiert: `neotest-plenary`, `neotest-vitest`, `neotest-go` — **ignoriert** `config.neotest.adapters.factory` komplett |
| Adapter (Registry, unbenutzt) | `adapters/factory.lua` | Singleton-Cache-Registry mit eigenen `ADAPTER_BUILDERS` für lua/go/python/rust (inline) + typescript (delegiert an `adapters/typescript.lua`) — wird nirgends aufgerufen |
| Adapter (Einzeldateien, unbenutzt) | `adapters/{lua,go,python,rust}.lua` | Eigenständige, dritte Implementierung derselben vier Adapter — weder von `factory.lua` noch von `plugins/neotest.lua` referenziert |
| Adapter (Einzeldateien, nie verdrahtet) | `adapters/{bash,assembly,c_ccp,wasm,zig}.lua` | Vollständig implementiert (Framework-Erkennung, Test-Pattern-Matching), aber in keiner Dependency-Liste, keinem Factory-Eintrag und keinem Setup-Aufruf referenziert |
| Adapter (smart, teilweise unbenutzt) | `adapters/typescript.lua` | CWD-gesperrte Root-Erkennung + Vitest/Jest-Autodetektion — wird nur über `factory.lua` erreicht, das selbst unbenutzt ist; die aktive Config in `plugins/neotest.lua` nutzt stattdessen ein rohes `require("neotest-vitest")` ohne jede Optionen |
| Core | `core/init.lua` | Auto-Attach an Testdateien per Dateinamen-Pattern, Auto-Open des Output-Fensters bei Fehlschlag — per `Autocmd`, optional aufgerufen (`pcall(require, "config.neotest.core")`) |
| Actions | `actions/init.lua` | Zentrale, saubere Fassade (`run_nearest`, `run_file`, `run_all`, `debug_nearest`, `toggle_summary`, `open_output`, `toggle_output_panel`, `stop`, `toggle_watch`) — von Keymaps, Commands, Telescope und Which-Key gleichermaßen konsumiert |
| Commands | `commands/init.lua` | 10 `:Neotest*`-Usercmds, direkt auf `actions` gemappt |
| Keymaps | `keymaps/init.lua` | `<leader>nt*`-Mappings über `lib.nvim.bindings.keymap`; **zusätzlich** zwei Mappings (`<leader>ntr`/`<leader>ntD`) bereits beim `require()` selbst gesetzt (Modul-Top-Level-Code, nicht in `setup()`) |
| Which-Key | `whichkey/init.lua` | Dieselben 9 `<leader>nt*`-Mappings noch einmal, über `which-key`s `wk.add()` |
| Debug | `debug/init.lua` | Fünf `:NeotestDebug*`-Usercmds (Adapter-Status, State, File, Root, Framework) **plus** eine dritte Definition von `<leader>ntr`/`<leader>ntD` |
| Highlights | `highlights/init.lua` | 8 statische `NeotestPassed/Failed/Running/...`-Highlight-Gruppen |
| Telescope | `telescope/init.lua` | Picker über dieselben `actions`-Funktionen |
| Neo-tree-Bridge (aktiv) | `neotree/init.lua` | `commands()`/`keymaps()` für die `tests`-Source in Neo-tree — **wird tatsächlich verwendet**, von `lua/plugins/neotree.lua:4` (`local NEOTEST = require("config.neotest.neotree")`) |
| Neo-tree-Consumer (aktiv) | `consumers/neotree_wrapper.lua` | Deferred-Wrapper um `neotest.consumers.neotree` (aus `TimCreasman/neo-tree-tests-source.nvim`), verhindert Race Condition beim Initialisieren |
| Validierung | `utils/validate_consumer.lua` | `:NeotestValidateConsumer` — prüft Consumer-Initialisierung und ob Neo-tree die `tests`-Source kennt |
| Auto-Discovery | `autocmds/auto_discovery.lua` | `VimEnter`-Trigger für initialen Scan + Neo-tree-Refresh — **auskommentiert** in `plugins/neotest.lua`, also inaktiv |
| Icons | `init/icons.lua` | Icon-Set-Auflösung (`"devicons"`-Variante wird aktiv genutzt) |
| Dependencies | `init/dependencies.lua` | Lazy-Deps-Liste: 5 Plugin-Deps, 1 Consumer-Plugin, 7 Adapter-Plugins (inkl. `neotest-python`, `rouge8/neotest-rust`, `neotest-jest` — installiert, aber s. §B.2 nie tatsächlich aktiviert) |
| Doku | `docs/COMMANDS.md` | Deutsche Kurzreferenz für Commands/Keymaps/Autocmds — bereits vorhanden, gut wiederverwendbar |

Gesamtumfang: ~2.500 Zeilen über 27 Dateien — deutlich kleiner als `lsp.nvim`
(~11.600) oder das kombinierte `wkdnvchad`/`wkdoptions` (~11.800), vergleichbar
mit `dap.nvim`s ursprünglichem `lua/wkddap`-Umfang.

### B.2 Gefundene Inkonsistenzen im Ist-Zustand

Diese vier Punkte sind unabhängig von der Auslagerungsfrage bereits heute
bestehende Bugs bzw. totes Gewicht im Host — analog zum in `lsp.md §1`
dokumentierten Fund, dass `lsp/debug_adapters/init.lua` nur auskommentierte
`require`s enthält.

1. **Adapter-Split-Brain (drei parallele Implementierungen, eine davon aktiv):**
   `plugins/neotest.lua` setzt `opts.adapters` hartcodiert auf drei Einträge
   (`neotest-plenary`, `neotest-vitest`, `neotest-go`), jeweils ohne Optionen.
   Parallel existieren (a) `adapters/factory.lua` mit einer eigenen,
   Singleton-gecachten `ADAPTER_BUILDERS`-Registry für lua/go/python/rust/
   typescript und (b) fünf weitere eigenständige `adapters/{lua,go,python,
   rust}.lua`-Dateien, die *keine* der beiden anderen Stellen referenziert.
   **Konsequenz:** `neotest-python`, `rouge8/neotest-rust` und
   `neotest-jest` werden laut `init/dependencies.lua` als Lazy-Deps
   installiert, aber nie als Adapter aktiviert — Python-, Rust- und
   Jest-Projekte bekommen aktuell keine Testerkennung, obwohl die Plugins
   vorhanden sind. Die sorgfältig gebaute CWD-Sperre + Framework-Erkennung in
   `adapters/typescript.lua` (verhindert Multi-Root-Discovery, erkennt Vitest
   vs. Jest über Config-Dateien/`package.json`) wird ebenfalls nie erreicht,
   weil sie nur über das unbenutzte `factory.lua` verdrahtet ist — die aktive
   Config nutzt stattdessen ein Vitest-Adapter ohne jede Option.

2. **Fünf komplett unverdrahtete Adapter-Dateien:**
   `adapters/{bash,assembly,c_ccp,wasm,zig}.lua` sind vollständig
   implementiert (inkl. Framework-Erkennung wie `bats`/`shunit2` für Bash),
   aber in keiner Dependency-Liste, keinem Factory-Eintrag und keinem
   Setup-Pfad referenziert. Reines totes Gewicht — vermutlich Ausbaustufen,
   die nie angeschlossen wurden.

3. **Dreifache Keymap-Registrierung für `<leader>ntr`/`<leader>ntD`:**
   Dieselben zwei Tastenkombinationen werden an drei Stellen definiert:
   einmal als Modul-Top-Level-Code in `keymaps/init.lua` (läuft bereits beim
   `require()`, nicht erst bei `setup()`), einmal identisch-benannt (aber mit
   abweichender, elaborierterer Implementierung inkl. Test-Zähler) in
   `debug/init.lua:M.keymaps()`, aufgerufen über `debug.setup_all()` in
   `plugins/neotest.lua`. Wer zuletzt lädt, gewinnt (`vim.keymap.set`
   überschreibt kommentarlos) — nicht offensichtlich, welche Variante aktiv
   ist, ohne die Load-Reihenfolge nachzuvollziehen.

4. **Doppelte Registrierung der übrigen neun `<leader>nt*`-Keymaps:**
   `plugins/neotest.lua` ruft sowohl `require("config.neotest.keymaps").setup()`
   (bindet über `lib.nvim.bindings.keymap`/`vim.keymap.set`) als auch
   `require("config.neotest.whichkey").setup()` (bindet dieselben LHS über
   `which-key`s `wk.add()`) auf. Funktional vermutlich unschädlich (letzter
   Bind gewinnt, which-key registriert vermutlich nach dem nativen Mapping),
   aber unklar, ob die which-key-Beschreibungen tatsächlich die sind, die
   angezeigt werden, oder ob sie vom nativen `desc` überschrieben werden —
   ungetestet, sollte vor der Migration einmal manuell verifiziert werden.

**Auto-Discovery ist zusätzlich bewusst deaktiviert** (auskommentiert in
`plugins/neotest.lua`) — kein Bug, aber beim Umzug zu entscheiden, ob das
Feature reaktiviert oder als offiziell-abgeschaltet in die neue README
übernommen wird.

### B.3 Lohnt sich die Auslagerung?

Ja — aus denselben Gründen wie bei `dap.nvim`/`lsp.nvim` (`nvim.md`):
`config/neotest/**` ist ein **stateful Subsystem** (Adapter-Registry,
Discovery-State, Consumer-Wiring) mit eigenen Commands und Keymaps, keine
deklarativen Settings — gehört damit strukturell zur selben Kategorie wie
`lsp.nvim`/`dap.nvim`, nicht zu `options.nvim`.

Zusätzliches Argument: Die Extraktion ist der **richtige Zeitpunkt**, die
vier in [§B.2](#b2-gefundene-inkonsistenzen-im-ist-zustand) gefundenen
Inkonsistenzen zu bereinigen — ein 1:1-Copy ins neue Repo würde die Bugs
sonst nur mitverschieben, wie es analog bei `lsp.nvim`s
`debug_adapters`-Fund der Fall gewesen wäre.

Anders als bei `wkdnvchad`/`wkdoptions` (`NEW_PLUGIN.md`) gibt es hier
**keine NvChad-Kopplung** (0 Treffer beim Grep nach `nvchad` im gesamten
`config/neotest`-Baum) — die Frage "eigenständig lauffähig ohne NvChad"
stellt sich also gar nicht, `test.nvim` wäre von Anfang an NvChad-frei.

Es gibt aber eine **echte Neo-tree-Kopplung** (`neotree/init.lua`,
`consumers/neotree_wrapper.lua`, `utils/validate_consumer.lua`), die beim
Zuschnitt berücksichtigt werden muss — anders als die reine
Optionale-Adapter-Beziehung bei `lsp.nvim` zu `dap.nvim` ist diese Kopplung
für den Testrunner *funktional relevant* (die "tests"-Quelle in Neo-tree
existiert nur durch dieses Zusammenspiel), s. [§B.4](#b4-architektur--modul-mapping)
und [§B.10](#b10-offene-fragen--risiken).

### B.4 Architektur / Modul-Mapping

```
test.nvim/
├── lua/test/                    -- oder wkdtest/ o.ä., s. §B.10 (Namenskollision)
│   ├── init.lua                 -- M.setup(opts) — Orchestrierung
│   ├── @types/
│   ├── adapters/
│   │   ├── init.lua             -- EINE Registry statt drei parallelen
│   │   │                           Implementierungen (factory.lua + Einzeldateien
│   │   │                           + Hardcode in plugins/neotest.lua verschmelzen)
│   │   ├── lua.lua / go.lua / python.lua / rust.lua / typescript.lua
│   │   └── bash.lua / assembly.lua / c_ccp.lua / wasm.lua / zig.lua
│   │                             -- entweder anschließen (opt.adapters aus opts.servers-
│   │                                artigem Array bauen) oder bewusst als "vorbereitet,
│   │                                nicht aktiv" markiert lassen — s. §B.10
│   ├── core/                    -- Auto-Attach, Auto-Open-on-Fail
│   ├── actions/                 -- unverändert, bereits die richtige Fassade
│   ├── commands/
│   ├── keymaps/                 -- EINE Quelle statt drei (s. §B.2 Punkt 3/4)
│   ├── highlights/
│   ├── telescope/               -- optional, pcall-guarded (Soft-Dep)
│   ├── neotree/                 -- Bridge: commands()/keymaps() für die "tests"-Source,
│   │                                bleibt öffentliche API, vom Host konsumiert
│   ├── consumers/                -- neotree_wrapper (Deferred-Consumer)
│   ├── utils/validate_consumer.lua
│   └── autocmds/auto_discovery.lua -- Default-Zustand (an/aus) explizit in setup(),
│                                       nicht mehr stumm auskommentiert
├── plugin/health.lua (oder lua/test/health.lua)  -- :checkhealth test
├── README.md
├── doc/test.txt
└── docs/
    ├── COMMANDS.md               -- bereits vorhanden, 1:1 übernehmen
    └── ROADMAP.md
```

Die interne Struktur (Actions als zentrale Fassade, von Keymaps/Commands/
Telescope/Which-Key gleichermaßen konsumiert) ist bereits gut nach SRP
organisiert und muss nicht neu entworfen werden — die Bereinigung betrifft
gezielt die Adapter- und Keymap-Redundanzen aus §B.2, nicht die
Gesamtarchitektur.

### B.5 lib.nvim-Integration

| Aktuell | Status |
|---|---|
| `lib.nvim.notify` (`actions`, `debug`, `consumers/neotree_wrapper`, `utils/validate_consumer`) | bereits verwendet ✅ |
| `lib.nvim.bindings.keymap` (`keymaps/init.lua`, `debug/init.lua`) | bereits verwendet ✅ — aber s. §B.2 Punkt 3/4 zur Redundanz |
| `lib.nvim.bindings.usercmd` (`debug/init.lua`, `utils/validate_consumer.lua`) | bereits verwendet ✅ |
| `lib.nvim.bindings.autocmd` (`core/init.lua`, `autocmds/auto_discovery.lua`) | bereits verwendet ✅ |
| `vim.api.nvim_create_user_command` direkt statt `lib.nvim.bindings.usercmd` (`commands/init.lua`) | uneinheitlich — `commands/init.lua` nutzt die native API, `debug/init.lua` im selben Plugin nutzt `lib.nvim.bindings.usercmd`. Beim Umzug vereinheitlichen |
| Adapter-Singleton-Cache (`adapters/factory.lua`, `_G._neotest_adapter_cache`) | globaler State über `_G` statt `lib.lua.memo` — sollte bei der Konsolidierung aus §B.4 durch `lib.lua.memo`/`lib.lua.memo.lru` ersetzt werden, kein `_G`-Zugriff nötig |
| Framework-Detection-Caching (`adapters/typescript.lua` liest bei jedem Aufruf `package.json` neu) | Kandidat für `lib.lua.memo` (pro Root-Pfad einmalig cachen) |

### B.6 Öffentliche API

```lua
require("test").setup({
  adapters = {
    lua = true, go = true, python = true, rust = true, typescript = true,
    -- bash/assembly/c_ccp/wasm/zig: bewusst standardmäßig aus, s. §B.10
  },
  neotree_bridge = true,        -- entspricht heutigem neotree/init.lua + consumers/neotree_wrapper
  auto_discovery = false,       -- expliziter Default statt stiller Auskommentierung
  core = {
    auto_attach_on_test_file = true,
    show_output_on_fail = true,
  },
  keymaps = { enable = true, which_key = "auto" }, -- "auto" = nutzt which-key falls vorhanden,
                                                     -- sonst native Keymaps — NICHT beides
  telescope = true,             -- optional, nur falls telescope installiert
})
```

Commands (bereits vorhanden, bleiben stabil): `:NeotestRunNearest`,
`:NeotestRunFile`, `:NeotestRunAll`, `:NeotestDebugNearest`,
`:NeotestSummaryToggle`, `:NeotestOutput`, `:NeotestOutputPanelToggle`,
`:NeotestStop`, `:NeotestWatchToggle`, `:NeotestActions`,
`:NeotestDebugAdapters`, `:NeotestDebugState`, `:NeotestDebugFile`,
`:NeotestDebugRoot`, `:NeotestDebugFramework`, `:NeotestValidateConsumer`,
`:NeotestClearAll`.

### B.7 Dokumentationspflichten

Wie in `NEW_Project.md` festgelegt:

- `README.md` (deutsch) — ASCII-Art + Badges + Table of Content (nur H2)
- `/doc/test.txt` (englisch, `:h`-fähig)
- `/docs/ROADMAP.md` — künftige Features (§B.9)
- `/docs/COMMANDS.md` — **bereits vorhanden und gut**, 1:1 übernehmen, nur
  Pfade/Modulnamen nach dem Umzug aktualisieren
- **`:checkhealth test`** — prüft `lib.nvim`-Verfügbarkeit, ob `nvim-neotest/
  neotest` geladen ist, welche Adapter tatsächlich aktiv sind (direkte
  Antwort auf den in §B.2 Punkt 1 gefundenen Split-Brain — die Health-Ausgabe
  sollte explizit auflisten: "installiert, aber nicht aktiviert" vs. "aktiv"),
  und ob die Neo-tree-Bridge (`tests`-Source) korrekt registriert ist —
  letzteres im Kern eine Wiederverwendung von `utils/validate_consumer.lua`,
  analog zum in `lsp.md §6` beschriebenen Muster ("kein Code-Duplikat, nur
  eine zweite dünne Schnittstelle").

### B.8 Migrationsplan

1. Repo `test.nvim` unter `$REPOS_DIR\test.nvim` anlegen (Grundgerüst: README,
   doc, ROADMAP, `:checkhealth`, `.luarc.json`, `stylua.toml` — Vorlage:
   `dap.nvim`).
2. `lua/config/neotest/**` 1:1 kopieren.
3. **Adapter-Konsolidierung** (Kernarbeit dieser Migration, nicht nur
   Verschieben): eine einzige `adapters/init.lua`-Registry bauen, die
   entweder die `factory.lua`-Logik (Singleton-Cache, `M.get`/`M.get_all`)
   oder die Einzeldateien als Quelle nimmt — nicht beide parallel behalten.
   `plugins/neotest.lua`s künftiges Äquivalent (`nvchad`/Host-Spec) muss
   `adapters.get_all()` tatsächlich aufrufen statt eine Hardcode-Liste zu
   pflegen, sonst wiederholt sich der Fund aus §B.2 Punkt 1 im neuen Repo.
4. **Keymap-Konsolidierung**: `keymaps/init.lua`s Top-Level-Code in
   `setup()` verschieben (kein Side-Effect bei `require()`), `debug/init.lua`s
   `<leader>ntr`/`<leader>ntD`-Duplikate entfernen (eine Implementierung
   behalten — die elaboriertere aus `debug/init.lua` mit Test-Zähler wirkt
   ausgereifter). Which-Key vs. native Keymaps: **eines von beiden**, per
   `opts.keymaps.which_key` steuerbar (s. [§B.6](#b6-öffentliche-api)), nicht
   beides gleichzeitig binden.
5. Fünf unverdrahtete Adapter (`bash`, `assembly`, `c_ccp`, `wasm`, `zig`)
   entweder anschließen (`opts.adapters.bash = true` etc.) oder explizit in
   `docs/ROADMAP.md` als "vorbereitet, aber nicht standardmäßig aktiv"
   vermerken — nicht stillschweigend als totes Gewicht mitschleppen.
6. Neo-tree-Bridge (`neotree/init.lua`, `consumers/neotree_wrapper.lua`)
   als öffentliche API belassen — der Host (`lua/plugins/neotree.lua`)
   konsumiert sie weiterhin per `require("test.neotree")` (oder
   `require("test").neotree`), analog zum heutigen
   `require("config.neotest.neotree")`. Keine Änderung an der Kopplungsrichtung
   nötig, nur am Modul-Pfad.
7. `:checkhealth`-Brücke ergänzen (s. [§B.7](#b7-dokumentationspflichten)).
8. Host-Wiring in `lua/plugins/personal/init.lua` analog zum bestehenden
   `dap.nvim`-Eintrag ergänzen; `lua/plugins/neotest.lua` und
   `lua/config/neotest/**` entfernen, `lua/plugins/neotree.lua:4`
   (`require("config.neotest.neotree")`) auf `require("test.neotree")`
   umstellen.
9. Manuell verifizieren: Testerkennung für mindestens Lua/Go (aktueller
   Stand) UND Python/Rust/TS (bisher nie aktiviert, s. §B.2), Neo-tree
   `tests`-Source funktioniert weiterhin, keine doppelten Keymap-Meldungen
   mehr in `:verbose map <leader>ntr`.
10. Diesen Roadmap-Eintrag nach Abschluss aktualisieren, analog zur
    Memory-Notiz `lib-nvim-extraction.md`.

### B.9 Brainstorm: fehlende / neue Features

| Feature | Nutzen | Aufwand |
|---|---|---|
| **Adapter-Status in `:checkhealth`** | Direkte Antwort auf §B.2 Punkt 1 — sichtbar machen, welche Sprache tatsächlich Testerkennung hat, statt es stillschweigend nicht zu tun | klein (Kern der Migration ohnehin) |
| **Coverage-Anzeige** (z. B. über `neotest`s eigene Coverage-Konsumenten oder externe Tools) | Aktuell nirgends in `config/neotest/**` referenziert | mittel-groß |
| **Test-Historie/letzter-Lauf-Zusammenfassung** (`:NeotestHistory` o. ä.) | `actions.lua` hat keinen Zugriff auf vergangene Läufe über die aktuelle Session hinaus | mittel |
| **Watch-Mode-Statusanzeige in der Statusline** | `toggle_watch()` existiert (Action + Keymap + Command), aber kein sichtbarer Indikator, ob Watch gerade aktiv ist — leicht mit `wkdnvchad`/`nvchad-ui.nvim`s Statusline-Modulen kombinierbar (s. `NEW_PLUGIN.md`) | klein-mittel |
| **Per-Projekt-Adapter-Override** (`.neotest.json` o. ä. im Repo-Root) | Analog zum in `lsp.md §8` vorgeschlagenen Per-Projekt-Override für Server — hier für Adapter/Frameworks (z. B. Vitest erzwingen statt Auto-Detect) | mittel |
| **DAP-Integration verifizieren** | `actions.debug_nearest()` setzt `strategy = "dap"` voraus — ob das mit dem parallel geplanten `dap.nvim` (s. `lsp.md`) tatsächlich zusammenspielt, ist unverifiziert; sollte beim Umzug einmal end-to-end getestet werden | klein (Audit) |
| **Assembly/Bash/Wasm/Zig-Adapter tatsächlich anschließen** | Code existiert bereits fertig (s. §B.2 Punkt 2), reine Verdrahtungsarbeit | klein |

### B.10 Offene Fragen / Risiken

- **Modulname `test`:** `require("test")` ist ein sehr generischer,
  kollisionsanfälliger Name (andere Plugins/Projekte könnten eigene
  `lua/test/`-Verzeichnisse für ihre eigenen Testsuiten haben, die versehentlich
  auf dem `runtimepath` landen). Analog zu `dap.nvim`, dessen Lua-Modul
  bewusst `wkddap` statt `dap` heißt (Kollision mit `nvim-dap`s eigenem
  `dap`-Modul), empfiehlt sich hier ein spezifischerer Modulname wie
  `wkdtest` oder `testing` statt `test` — Repo-Name `test.nvim` kann davon
  unabhängig bleiben (Präzedenzfall: `dap.nvim` → `wkddap`).
- **Which-Key vs. native Keymaps:** aktuell laufen beide parallel (s. §B.2
  Punkt 4) und es ist unklar, ob das je zu sichtbaren Problemen geführt hat
  (falsche Beschreibung in `:WhichKey`, doppelte `<leader>nt`-Einträge in
  Popup-Menüs). Vor der endgültigen Entscheidung "which_key = auto"
  (s. §B.6) einmal interaktiv mit `:WhichKey <leader>nt` gegenprüfen.
- **Neo-tree-Kopplungsrichtung:** wie in `nvim.md` vermerkt, besitzt
  der Host aktuell noch direkt `lua/config/neotree/**` (die
  neo-tree→filetree.nvim-Migration "Liste 1" ist offen). Die
  Neotest-Neotree-Bridge sollte deshalb bewusst als **von `test.nvim` nach
  außen exportierte** Funktion (`commands()`/`keymaps()`) gebaut werden, die
  der Host konsumiert — nicht als Config, die `test.nvim` selbst gegen ein
  bestimmtes Neo-tree-Setup fest verdrahtet. Falls/wenn "Liste 1" abgeschlossen
  wird, übernimmt `filetree.nvim` diesen Konsum-Punkt, ohne dass `test.nvim`
  selbst geändert werden muss.
- **`TimCreasman/neo-tree-tests-source.nvim`** ist eine Third-Party-Abhängigkeit
  außerhalb der eigenen `*.nvim`-Familie — als externe Dependency in
  `test.nvim`s eigenem `dependencies`-Feld deklarieren, nicht implizit über
  den Host erwarten.
- **Auto-Discovery-Reaktivierung:** aktuell bewusst auskommentiert. Vor der
  Migration entscheiden, ob das Feature (2s+1s verzögerter VimEnter-Scan)
  tatsächlich gewollt ist oder ob die Auskommentierung ein bewusster,
  dauerhafter Zustand war (z. B. wegen Startup-Performance) — dann gehört
  der Code nicht referenzlos ins neue Repo, sondern klar als "deaktiviert,
  weil X" dokumentiert, analog zur Sorgfalt bei den anderen Startup-Phasen
  in `init.lua` (s. `NEW_PLUGIN.md §8` zur Startup-Reihenfolge-Disziplin).

### B.11 Randnotiz: `plenary.nvim` ist nicht vollständig durch `lib.nvim` ersetzt

Nicht Teil der `neotest`-Auslagerung oben, sondern eine separate, beim
Aufräumen der Startup-Notifies in `lsp.nvim`/`dap.nvim` (2026-09-12)
aufgekommene Erkenntnis, die hier festgehalten wird, weil sie die nächste
Diskussion "können wir `plenary.nvim` als Dependency ganz loswerden, jetzt wo
`lib.nvim` das doch eh reimplementiert hat" vorwegnimmt — und weil sie
**direkt in Teil A** hineinspielt (§A.5, §A.13 Phase 5).

**Die Annahme stimmt nur zur Hälfte.**

- **Tatsächlich absorbiert:** `lib.nvim` hat plenarys *Runtime-Utilities*
  (Path, Job, async/fs-Traversal, Git-Helper) durch eigene Implementierungen
  auf Basis nativer Neovim-APIs ersetzt — Beleg:
  `lib.nvim.system.job`s eigener Docstring nennt sich wörtlich einen "thin
  `vim.system` wrapper restoring plenary.job-like ergonomics"
  (`lib.nvim/docs/API/commands-and-infra.md`). Deshalb: **0 Treffer** für
  `require("plenary...")` im gesamten Produktivcode von `lsp.nvim` und
  `dap.nvim` — dort wird plenary schon lange nicht mehr direkt benutzt.
- **Nicht absorbiert:** Plenarys Busted-artiges Test-Framework
  (`describe`/`it`/`assert.*` in `plenary/busted.lua`) plus der headless
  Test-Runner (`plenary/test_harness.lua`, angesprochen über
  `:PlenaryBustedFile`/`:PlenaryBustedDirectory`) hat in `lib.nvim` **keine
  Entsprechung** — kein `describe`/`it` irgendwo im `lib.nvim`-Baum. Und
  `lib.nvim` hat selbst ein `TESTS/`-Verzeichnis, das für seine eigene
  Suite denselben Mechanismus braucht (`PLENARY_PATH` +
  `runtime plugin/plenary.vim`) wie `lsp.nvim`s und `dap.nvim`s
  `TESTS/minimal_init.lua` / `tests/minimal_init.lua`.

**Konsequenz:** `plenary.nvim` ist über die ganze `*.nvim`-Flotte hinweg zu
einer reinen **Dev/Test-only-Dependency** (Test-Runner) geschrumpft, keine
Runtime-Dependency mehr. Kein Handlungsbedarf jetzt — aber falls irgendwann
vorgeschlagen wird, plenary komplett rauszuwerfen: das würde jede
`PlenaryBustedDirectory`-Testsuite in der Flotte brechen, solange `lib.nvim`
nicht zusätzlich ein eigenes, minimales `describe/it/assert`-Framework +
Headless-Runner bereitstellt — genau das, was `spec.nvim` (Teil A) ohnehin
vorschlägt. Kein aktuell geplantes Feature außerhalb davon, nur als
Beobachtung festgehalten, damit die Antwort beim nächsten Aufkommen dieser
Frage nicht neu recherchiert werden muss.

> **Update 2026-09-22 (Nutzerentscheidung): "kein Handlungsbedarf" gilt nicht
> mehr.** `plenary.nvim` als Test-Harness soll aktiv ersetzt werden —
> flottenweit, nicht nur für die drei in §A.1/§A.2 als Dialekt E gelisteten
> Repos (`dap`, `sandbox`, `github_stats`). Diese Liste war zum
> 2026-08-17-Snapshot korrekt, ist aber überholt: eine frische
> Bestandsaufnahme (2026-09-22) findet Dialekt E (busted-artig, `describe`/
> `it`, `PLENARY_DIR`/`PLENARY_PATH` zum Laufen nötig) in **elf** Repos:
> `ai.nvim`, `casedesk.nvim`, `dap.nvim`, `data.nvim`, `github_stats.nvim`,
> `gitsuite.nvim`, `hover.nvim`, `lsp.nvim`, `my.nvim`, `rules.nvim`,
> `sandbox.nvim`. §A.1/§A.2/§A.13-Phase-5 sind an dieser Stelle entsprechend
> veraltet. Sieben weitere Repos erwähnen "plenary" im Testbaum, nutzen es
> aber **nicht** als eigenen Harness (Dialekt A/eigener Runner, "plenary"
> taucht nur als Fixture-Inhalt oder als Dependency-Check für ein *anderes*
> getestetes Plugin auf): `cmdlog.nvim`, `documentation.nvim`, `fileops.nvim`,
> `filetree.nvim`, `media.nvim`, `pickers.nvim`, `runtime-analysis.nvim` —
> für diese besteht kein Handlungsbedarf. Der Ersatz läuft über den in §D.10
> ohnehin vorgesehenen busted-Shim von `spec.nvim` (Dialekt E bleibt lauffähig,
> ohne dass die echte `plenary.nvim`-Dependency gebraucht wird) — s. den
> neuen Entscheidungseintrag in [§D.10](#d10-entscheidungen-vor-m0).

---

## Teil C — Synthetische Feature-Tests: Analyse & Konzept

### C.1 Ausgangsfrage

Ausgangsidee: Mit VM (VMware) + Klick-Simulator + Überwachung aller
Ausgaben (`:messages`, Notifies, bei Plugins mit Browser-Anteil auch die
Browser-Konsole) müsste sich fast alles automatisieren lassen, was heute
nur live geprüft werden kann. Vorschlag: neben dem bestehenden `TESTS/` in
jedem Plugin-Repo eine zweite Struktur für "synthetische" Tests — ein Test
pro Feature/Binding.

**Kurze Antwort:** Ja, im Prinzip — aber eine VM ist für die meisten Fälle
der falsche Hebel. Neovim hat mit seiner RPC-Schnittstelle
(`nvim_input`/`nvim_feedkeys`, headless `--embed`) bereits einen
eingebauten "Klick-Simulator", der deterministischer, schneller und
CI-tauglicher ist als OS-Level-Input in einer VM. Eine VM lohnt sich nur
dort, wo tatsächlich reales OS-/Terminal-/Browser-Rendering im Spiel ist,
das die API nicht abbildet.

### C.2 Bestandsaufnahme (Recherche 2026-09-20)

**Test-Infrastruktur ist bereits uneinheitlich vorhanden — deckungsgleich
mit dem Befund aus [§A.1/§A.2](#a1-ist-zustand):**

- `$REPOS_DIR/ui.nvim/TESTS` nutzt plenary/busted über `scripts/test.sh`,
  headless. `TESTS/ui_kit_spec.lua` (~230 Assertions)
  und `TESTS/contextmenu_spec.lua` decken `ui.kit`/`ui.contextmenu` bereits
  ab; `TESTS/kit_drift_spec.lua` bewacht zusätzlich, dass `lib.nvim`s
  eingefrorene Kopie dieser Module nicht von ui.nvims Live-Version abweicht.
- `lib.nvim`, `sessions.nvim`, `pickers.nvim` nutzen den handgerollten
  Dialekt-A-Runner (`TESTS/run.lua` + `harness.lua`), ebenfalls headless.

**Notify-Interception:** `lib.nvim.notify` ist der De-facto-Sammelpunkt
(dap, debugging, pickers, cascade, spotlight nutzen ihn), aber nicht
vollständig zentralisiert — vereinzelt rufen Plugins noch `vim.notify(`
direkt (sessions.nvim: 7 Stellen, dap.nvim: 2, cascade/pickers/spotlight:
je 1). Kein Blocker: Ein Monkeypatch von `vim.notify` **im Testprozess**
fängt beides ab, roh und über `lib.nvim.notify` weitergereicht — solange
Letzteres letztlich `vim.notify` aufruft. Keine Vereinheitlichung im
Produktivcode nötig, um Notifies synthetisch zu prüfen.

**Rendering-Oberflächen — das entscheidet, wer eine VM/Browser/Terminal
braucht:**

| Kategorie | Plugins | Per RPC allein testbar? |
|---|---|---|
| Reines Buffer/Float-UI | filetree, spotlight, pickers, reposcope, color_my_ascii (Extmark-Highlights über `nvim_buf_add_highlight`) | Ja, vollständig |
| Terminal-Grafikprotokoll | images.nvim (iTerm2-Inline-Image-Protokoll OSC 1337, laut README — nicht Kitty; Fallbacks `ascii.lua`/`blocks.lua`), media.nvim (erzeugt PNGs/Waveforms via ffmpeg, delegiert Anzeige an images.nvim), pdfport.nvim (rastert Seite 1 zu Bild, zeigt über images.nvim/hover.nvim oder degradiert zu Text) | Nein — braucht echtes Terminal-Rendering |
| Echter Browser | mdview.nvim (echter Browser-Tab, lokaler Server + WebSocket-Client, Rust/WASM-Renderer clientseitig — nichts wird serverseitig gerendert) | Nein — braucht Browser |
| Native Desktop-App | docmap-desktop (Tauri 2, HTML/JS-Frontend, bisher **nur** Rust-Unit-Tests via `tauri::test::mock_app()` ohne echtes Fenster, keine E2E-Infra) | Nein — braucht WebDriver/echtes Fenster |

`ui.kit`/`ui.contextmenu` haben bereits solide Spec-Abdeckung inkl.
Drift-Guard — ein gutes Vorbild für "geteilte Tests statt 20× dasselbe"
(Analogie zu §C.6).

### C.3 Warum keine VM als Standard

Eine VM pro Feature/Binding wäre langsam (VM-Boot + Login + Klick-Timing
statt ms-schnelle RPC-Calls), flaky (Font-/Theme-/DPI-Drift bricht
Golden-Images) und in normaler CI kaum praktikabel. Die RPC-Schnittstelle
deckt dagegen genau das ab, was die Ausgangsidee eigentlich will: "als ob
ich die Taste gedrückt hätte" — nur ohne Pixel-Koordinaten, ohne
Timing-Abhängigkeit, ohne Fensterfokus-Probleme.

### C.4 Die Test-Pyramide

| Tier | Zweck | Werkzeug | VM nötig? |
|---|---|---|---|
| **0 — Unit** | reine Lua-Logik | bereits vorhanden (§A.1) | Nein |
| **1 — Headless-RPC Feature/Binding** | ein Test pro Keymap/Command, Assertions auf Buffer-Diff, `:messages`, abgefangene Notifies, Autocmd-Feuerung | `nvim_input`/`feedkeys` im headless-Kindprozess | Nein |
| **2 — Screen-Grid-Snapshot** | visuelle Regressionen in Floats/Toasts/Statusline | Grid-Snapshot-Verfahren wie Neovim-Core (`test/functional/ui/screen.lua`) bzw. `mini.test` | Nein |
| **3 — Echtes Rendering** | die vier Ausreißer aus §C.2 | Terminal: `tmux capture-pane` / [VHS](https://github.com/charmbracelet/vhs); Browser: Playwright (headless Chromium, Konsole+DOM+Screenshot); native App: `tauri-driver` (WebDriver) | Nein — echtes Terminal/Browser reicht, kein OS-Umbau |
| **4 — Volle VM/OS-Integration** | Clipboard-Interop nvim↔OS, Drag&Drop in filetree.nvim, Fenstermanager-/Fokus-Verhalten, Windows-spezifische Eigenheiten | VMware o. ä. | Ja — aber nur für diese Handvoll Szenarien, nie als Default |

Tier 1 deckt schätzungsweise 80–90 % der ~35 Plugins ab, weil die meisten
reines Buffer/Float-UI sind (obere Zeile der Tabelle in §C.2). Tier 4
bleibt die Ausnahme, nicht die Regel.

### C.5 Einordnung in spec.nvim: die lib.nvim-Frage

Zu prüfen war die Idee aus dem ersten Gesprächsdurchgang, einen
zentralisierten Test-Harness (`capture_notify()`, `feedkeys_and_wait()`,
`snapshot_screen()`) direkt als neues Modul in `lib.nvim` zu bauen (z. B.
`lib.testkit`). **Das ist gegen Teil A geprüft worden — Ergebnis: teilweise
richtig, aber falsch verortet.**

- `lib.nvim`s Rolle ist in [§A.4](#a4-warum-jetzt-libnvim-liefert-die-bausteine)
  bereits klar definiert: **niedrigschwellige Bausteine** (async, fs.watch,
  context_manager, notify, strings.width, …), auf denen andere aufbauen.
  Ein oder zwei neue, ähnlich kleine Primitiven dort ergänzen (z. B. ein
  synchroner `feedkeys`-Wrapper, ein Screen-Grid-Reader) passt zu diesem
  Muster und sollte tatsächlich in `lib.nvim` landen — konsistent mit allem,
  was in §A.4 bereits dort ist.
- Was **nicht** nach `lib.nvim` gehört, ist die **Orchestrierung** — also
  genau das, was ein "Testkit" faktisch wäre: Discovery, Suite/Case-Modell,
  Ergebnis-IR, Reporting. Das ist exakt die Aufgabe, die `spec.nvim`
  (Teil A) für sich beansprucht. Ein zweites, konkurrierendes
  Orchestrierungs-Modul in `lib.nvim` würde denselben Fehler wiederholen,
  den §A.1–§A.2 gerade an den 16 divergierten Test-Harnessen kritisieren —
  nur diesmal mit `lib.nvim` als 17. Variante.
- **Konkrete Antwort:** Synthetische Tests sind laut [§A.11](#a11-fortgeschrittene-testarten)
  eine fünfte Testart neben Property/Mutation/Snapshot/Flaky, mit eigenem
  Ordner `advanced/synthetic/` (§A.6). Die drei Tier-3-Backends
  (VHS/Playwright/tauri-driver) sind laut [§A.7](#a7-multilang) einfach
  weitere `lang/`-Backends mit demselben Vier-Funktionen-Interface
  (`detect`/`discover`/`run`/`parse`) wie Go oder Python — kein
  Sonderfall. Damit fügt sich Teil C **ohne neue Infrastruktur-Ebene** in
  Teil A ein; `lib.nvim` liefert nur die kleinen Primitiven, `spec.nvim`
  bleibt der einzige Ort, der sie zu Tests zusammensetzt.
- **Zeitliche Konsequenz:** Da Tier-1-Tests am stärksten von Isolation
  (Phase 3) und Cache/Affected-Selection (Phase 4) profitieren — sie sind
  die teuerste Testart im Alltagslauf —, gehört Teil C laut
  [§A.13](#a13-migrationsplan) als **Phase 10** ans Ende des
  Migrationsplans, nicht an den Anfang.

### C.6 Strukturvorschlag

Kein neuer, konkurrierender Ordner nötig. Innerhalb der bestehenden
`TESTS/`-Konvention (bzw. künftig `spec.nvim`s Discovery) ein Unterordner
pro Plugin, z. B. `TESTS/features/<feature>_spec.lua` — ein File pro
Feature/Binding, wie in der Ausgangsidee vorgeschlagen. Die Helper
(`a.feedkeys`, `a.screen`, `a.notify`) leben in `spec.nvim/advanced/synthetic/`
(§A.6) und rufen die kleinen `lib.nvim`-Primitiven auf (§C.5) — dieselbe
Aufteilung, die `ui.kit`/`ui.contextmenu` bereits vorleben (geteiltes
Toolkit in `ui.nvim`, konsumiert von vielen).

### C.7 Existierende Bausteine — nicht neu erfinden

| Baustein | Wofür | Bereits im Ökosystem relevant? |
|---|---|---|
| **plenary.nvim** | Dialekt E, aktuell in elf Repos (Liste in §B.11-Update 2026-09-22) | Ja (§A.2), wird laut §A.13 Phase 5 / §D.10 aktiv abgelöst |
| **mini.test** (echasnovski) | Kindprozess-nvim + Text-Screen-Snapshots — härtester Konkurrent zu `spec.nvim`, s. §A.5 | Bisher nicht genutzt; Referenz-Verfahren für Tier 2 |
| **Neovim-Core `test/functional/ui/screen.lua`** | Grid-basierte Screen-Assertions — Vorbild für Tier 2 | Kein eigenes Plugin, nur Vorlage |
| **VHS** (charmbracelet) | Skriptbare Terminal-Sessions, Screenshot-diffbar — Tier 3 für images/media/pdfport | Neu einzuführen als `spec.nvim`-`lang`-Backend |
| **Playwright** | Headless Chromium, Konsole+DOM+Screenshot — Tier 3 für mdview.nvim | Neu einzuführen als `spec.nvim`-`lang`-Backend |
| **`tauri-driver`** | WebDriver-Protokoll für Tauri-Apps — Tier 3 für docmap-desktop | Neu einzuführen; deutlich leichter als eine volle VM |

Kein Framework im Ökosystem deckt exakt "ein synthetischer Test pro
Feature/Binding" ab — die Bausteine dafür existieren aber fertig, wie oben.

### C.8 Ökosystem-Bezug: welcher Tier für wen

Ergänzt [§A.12](#a12-ökosystem-integration) um die Testobjekt-Perspektive:

| Plugin(-gruppe) | Tier | Begründung |
|---|---|---|
| filetree, spotlight, pickers, reposcope, color_my_ascii, ai, buffer-ctx, cascade, casedesk, cmdlog, data, dap, debugging, diff, documentation, emojis, fileops, github_stats, gopath, hover, insights, language, lib, lsp, markdown, open, recommender, replacer, runtime-analysis, sandbox, sessions | 1 (+ 2 für visuell auffällige Floats/Toasts) | reines Buffer/Float-UI, per RPC vollständig erreichbar |
| images.nvim, media.nvim, pdfport.nvim | 3 (Terminal) | echtes Terminal-Grafikprotokoll (OSC 1337), RPC sieht nur den Steuerbefehl, nicht das gerenderte Bild |
| mdview.nvim | 3 (Browser) | Rendering läuft clientseitig im Browser, serverseitig nichts zu prüfen |
| docmap-desktop | 3 (WebDriver) bzw. 4 für OS-Dialoge (`tauri-plugin-dialog`) | natives Fenster, kein nvim-RPC verfügbar |
| Cross-Plugin: Clipboard, Drag&Drop, Fenstermanager | 4 | einzige Fälle mit echtem VM-Bedarf |

### C.9 Empfehlung / nächste Schritte

1. Tier 1 zuerst pilotieren, an einem Plugin mit vorhandenem
   Runner-Muster und `lib.nvim`-Abhängigkeit (`sessions.nvim` oder
   `pickers.nvim`, s. §A.1) — bevor `spec.nvim` überhaupt existiert, reicht
   dafür der heutige Dialekt-A-Runner plus ein `vim.notify`-Monkeypatch und
   `nvim_input`.
2. Die zwei bis drei kleinen `lib.nvim`-Primitiven (synchroner
   Feedkeys-Wrapper, Screen-Grid-Reader) parallel zu Phase 0 von `spec.nvim`
   ergänzen, nicht als eigenständiges "Testkit".
3. Tier 3 (VHS/Playwright/tauri-driver) erst nach `spec.nvim`-Phase 4
   angehen (§A.13 Phase 10) — vorher lohnt sich der Aufwand nicht, weil
   ohne Cache/Affected-Selection jeder Lauf die teuren Backends komplett
   durchläuft.
4. Tier 4 (VM) bewusst zurückstellen, bis konkrete OS-Integrations-Bugs
   das rechtfertigen — kein Vorab-Investment in VMware-Infrastruktur.

### C.10 Offene Fragen / Risiken

- **Golden-Image-Drift (Tier 2/3):** Font-, Theme- oder DPI-Änderungen auf
  der Testmaschine brechen Screenshot-Vergleiche unabhängig vom
  Plugin-Code. Gegenmittel: feste Testumgebung (Docker-Image mit
  gepinnter Font/Terminal-Version) für Tier 3, nie auf der
  Entwickler-Maschine golden-file-vergleichen.
- **Flakiness bei Tier 3:** echte Browser/Terminal-Prozesse sind
  langsamer und nichtdeterministischer als RPC-Calls — Timeouts/Retries
  wie in [§A.10](#a10-safety--determinismus) beschrieben nötig, plus die
  Flaky-Erkennung aus [§A.11](#a11-fortgeschrittene-testarten).
- **Wartungskosten proportional zur Tier-Höhe:** Tier 1 ist praktisch
  wartungsfrei (Assertions auf Text/State), Tier 3 braucht laufende Pflege
  bei UI-Änderungen. Deshalb Tier 1 als Standard, Tier 3 nur für die vier
  echten Ausreißer, nicht großzügig ausweiten.
- **docmap-desktop hat noch keinerlei E2E-Infra** — `tauri-driver`-Setup
  ist Vorarbeit, kein bestehender Baustein zum Wiederverwenden (anders als
  bei den Neovim-Plugins, wo zumindest ein Runner-Muster existiert).
- **14 Repos ohne jede Spec** (§A.1) bekommen durch Teil C nicht
  automatisch Tests — dieselbe Einschränkung wie in §A.15 zuletzt
  vermerkt.

---

## Teil D — Überarbeitung v2 (2026-09-20): Analyse, Zielarchitektur, Features, Performance, Security, Plan

Grundlage: Teile A–C plus eine Verifikationsrunde am 2026-09-20 gegen die
echten Repos (`lib.nvim`, `sandbox.nvim`, `dap.nvim`, `debugging.nvim`,
`runtime-analysis.nvim`, `documentation.nvim`, `sessions.nvim`,
`pickers.nvim`, `filetree.nvim`, die CI-Workflows, `nvim-config/scripts/`,
`plugins/personal/init.lua`) und die verbindlichen Gates in
`wkdbook-Lua/Checklists/gates/` (`NEW_PROJECT.md`, `RELEASE.md`,
`REVIEW.md`). Alles, was hier als Fakt steht, ist dort nachgelesen; alles,
was Schätzung ist, ist als solche markiert.

### Inhalt Teil D

- [D.1 Analyse des bisherigen Konzepts](#d1-analyse-des-bisherigen-konzepts)
- [D.2 Leitplanken](#d2-leitplanken)
- [D.3 Zielarchitektur v2](#d3-zielarchitektur-v2)
- [D.4 Feature-Katalog mit Herkunft](#d4-feature-katalog-mit-herkunft)
- [D.5 Synthetische Tests konkret (Tier 1 bis 4, v2)](#d5-synthetische-tests-konkret-tier-1-bis-4-v2)
- [D.6 Konformitäts-Suite: Regeln, die laufen](#d6-konformitäts-suite-regeln-die-laufen)
- [D.7 Performance](#d7-performance)
- [D.8 Security-Modell](#d8-security-modell)
- [D.9 Konkreter Plan (M0 bis M9)](#d9-konkreter-plan-m0-bis-m9)
- [D.10 Entscheidungen vor M0](#d10-entscheidungen-vor-m0)
- [D.11 Offene Fragen und Risiken v2](#d11-offene-fragen-und-risiken-v2)

### D.1 Analyse des bisherigen Konzepts

**Was trägt und bleibt:**

- **IR-first** (§A.6): richtig, alles andere hängt daran. Wird in §D.3.2
  zum verbindlichen JSON-Vertrag ausformuliert.
- **Dialekt-Kompatibilität** (K1) als Migrationspfad ohne Big Bang.
- **Phase 0 als Falsifikationstest** — bleibt M0.
- **Affected-Selection** (F2): jetzt verifiziert statt vermutet.
  `documentation.nvim/lua/documentation/core/deps.lua` hat `M.impact(ir, id)`
  („every node that would be affected by changing this one: the transitive
  dependents"), `docs/map/module_map.json` existiert samt Schema
  (`docs/docmap.schema.json`), Cross-Repo-Umkehrindex in
  `core/consumers.lua` (`M.index`). F2 ist damit ein Feldmapping, kein
  Forschungsprojekt.
- **Ehrliche Sidecar-Analyse** (F4) — und sie wird noch einfacher:
  `vim.fn.sha256()` ist nativ, ein Hasher-Sidecar entfällt endgültig.
- Teil B: die vier Inkonsistenzen (§B.2) gelten unabhängig von allem hier.
- Teil C: das Tier-Modell bleibt, Tier 3 wird in §D.5 präzisiert.

**Verifizierte Korrekturen** (Behauptungen in A–C, die falsch oder unbelegt
waren):

| Stelle | Behauptung | Befund 2026-09-20 | Konsequenz |
|---|---|---|---|
| §A.7 | `documentation.nvim/docs/ROADMAP/MULTILANG.md` als Vorlage | existiert nicht; das Repo hat kein `docs/ROADMAP/` | Vier-Funktionen-Interface steht für sich |
| §A.12 | sandbox.nvim für isolierte Kind-nvim-Läufe | sandbox.nvim = Container-Engine-Frontend (`:Sandbox`-Baum für Podman/Docker/nerdctl); 0 Treffer für `NVIM_APPNAME`/`XDG_*`; keine Spawn-API außer `run_container`/`exec_in_container` | Kind-nvim-Treiber ist Eigenleistung (§D.3.4); sandbox.nvim bleibt für Container-Läufe in Tier 3 und als Sicherheitsgrenze (§D.8) |
| §A.4 | `lib.lua.time.diff` | kein `lib/lua/time` vorhanden | `vim.uv.hrtime()` |
| §A.4 | `lib.nvim.async.Semaphore`, `lib.lua.error.safe_call` | Namespaces existieren, die Symbole sind nicht verifiziert | in M0 prüfen, sonst bauen |
| §A.12 | runtime-analysis liefert Coverage-Näherung | bestätigt, aber **Funktionsebene**: Exports werden gewrappt (kein `debug.sethook`, README lehnt das für den Laufzeitfall ab); `coverage()` → `{ called, uncalled }` nur für gewrappte Funktionen; kein JSON-Report, nur Markdown/HTML + Roh-Store | Zeilen-Coverage muss spec.nvim selbst liefern (§D.4, §D.7) |
| §A.1 | Ablageorte `docs/TESTS/` (9×), `tests/`, `scripts/` | verstößt gegen **NEW-48** (kritisch): `TESTS/` im Root, nirgends `docs/TESTS/`, `tests/`, `test/` | Discovery kennt Legacy-Orte, meldet sie als Regelverstoß; der Umzug ist Gate-Arbeit, kein Runner-Feature |
| §A.5 | „CI-Exit-Code plenary flaky" als Kernproblem | CI-Realität: 3-OS-Matrix (`ubuntu/windows/macos`, `rhysd/action-setup-vim@v1`, `stable`, `shell: bash`), **keine `timeout-minutes`, keine Artefakte, kein JUnit**; Verdikt = Exit-Code + stdout; `run_all_tests.sh` sucht den Runner heuristisch (4 Dateinamen, dann „genau eine Datei in TESTS/") und parst Verdikte per `grep` auf Sentinels (`LIB_TESTS_OK`, `N spec(s) failed`) | die Lücke ist das fehlende IR, nicht plenary; Sofortmaßnahmen in §D.9.0 |
| §C.4 | Tier 3 für images.nvim per VHS | VHS rendert über ttyd + headless Chromium (xterm.js); iTerm2-Bilder (OSC 1337) werden dort nach heutigem Stand nicht gezeichnet (vor Einsatz verifizieren) | images/media/pdfport: Protokoll-Capture in einer PTY (Tier 2.5, §D.5.3); Pixel-Smoke nur in WezTerm |
| §A.13 | Reporter/UI erst Phase 7 | ein neotest-Adapter liefert Summary, Output, Inline-Diagnostics, Jump, Watch und DAP-Strategie sofort | UI nach vorn (M3); eigene UI wird optional |
| §B.4/§B.7 | `docs/COMMANDS.md` | real: `docs/commands.md` + `docs/BINDINGS.md`, **generiert** von `lib.nvim` (`bindings/usercmd/docs.lua`, Composer-Docgen) — konsistent in sessions/pickers/filetree | Oberfläche ist maschinenlesbar; Binding-Coverage (§D.6) liest die Registry, nicht die Doku |
| §A.12 | debugging.nvim liefert DAP-Einstieg für Specs | 0 Treffer für `osv`/`nlua` dort; der Adapter lebt in **dap.nvim** (`lua/wkddap/languages/lua.lua`: `dap.adapters.nlua`, Port 8086, `M.launch_server(port)` — an keinen Command gebunden) | `--debug` startet osv im Kind, Attach über dap.nvims vorhandene Konfiguration (§D.4) |

**Strukturelle Lücken** (was A–C nicht hatten):

1. **Kein Bezug zu den Gates.** `NEW-39` (TESTS/ + `scripts/test.sh`),
   `NEW-40` (Runner scheitert laut: drei Suchorte nennen, Exit 1),
   `NEW-43` (kein Test überspringt sich selbst), `NEW-47` (keine Async-API
   synchron — Fehler reißen fremde Dateien mit), `NEW-48`, `NEW-49`
   (busted-`std`), `REVIEW §6/§9`, `REL-16..24`. Der Runner muss sie
   erfüllen — und kann einen Teil davon **automatisieren** (§D.6).
2. **Kein Sicherheitsmodell.** Specs laufen mit den Rechten des Users; das
   Kind erbt `$NVIM` (den RPC-Socket des Eltern-Editors) und alle Secrets
   (`GITHUB_TOKEN` für github_stats, Provider-Keys für ai.nvim, pdfports
   `claude_api_key`).
3. **Keine `stdpath()`-Isolation.** sessions.nvim schreibt nach
   `stdpath("data")/sessions` (`config/DEFAULTS.lua:16`); ein Feature-Test
   ohne XDG-Umlenkung überschreibt echte Sessions.
4. **Main-Loop-Fehler unsichtbar.** Fehler in `vim.schedule`-Callbacks und
   Timern landen nur in `:messages` — genau der NEW-47-Fall.
5. **Prompt-Falle.** `vim.fn.input/getchar/confirm/inputlist`,
   `vim.ui.input/select` blockieren headless still.
6. **Keine Debug-Story** trotz vorhandenem `nlua`-Adapter.
7. **Kein Maß für „Feature getestet?"** — obwohl
   `lib.nvim.bindings.keymap.registered(plugin)`, `usercmd.registered()`,
   `composer.registry()` und `autocmd.registered()` die gesamte Oberfläche
   maschinell liefern.
8. **Keine generischen Tests**, obwohl 35 Plugins dieselben Konventionen
   teilen (`setup()`, abschaltbare Keymaps, `:checkhealth`, `desc`).
9. **Keine Determinismus-Hygiene** für Snapshots (Pfade, Usernamen, TZ,
   Locale, CRLF).
10. **Kein Trace** für synthetische Tests (was wurde getippt, was stand am
    Bildschirm, was wurde notified).

### D.2 Leitplanken

| # | Leitplanke | Konkret |
|---|---|---|
| L1 | **IR-first** | Reporter, Cache, UI, neotest-Adapter kennen nur `Spec.Result` (§D.3.2) |
| L2 | **Der Runner lügt nie** (NEW-40) | Exit-Codes `0` grün · `1` Fehlschläge · `2` Konfig/Usage · `3` Infrastruktur (Dependency fehlt, Kind stirbt, Timeout); Skips sind nie grün; kein Sentinel-Grep mehr |
| L3 | **RPC vor VM** | Tier 1/2 Standard, Tier 3 gezielt, Tier 4 Ausnahme (§D.5) |
| L4 | **Borrow, don't build** | Semantik von busted/luassert, mini.test, neotest, pytest, vitest, Playwright übernehmen; Eigenleistung nur, wo das Ökosystem etwas Exklusives hat (Graph, Registry, Regeln) |
| L5 | **lib.nvim = Primitiven, spec.nvim = Orchestrierung** (§C.5) | spec.nvim ist publizierbar und weiß nichts von `$REPOS_DIR` (TOOL-PLACEMENT Fall 5); die Flotten-Schleife bleibt `nvim-config/scripts/run_all_tests.sh` |
| L6 | **Windows-first** | `-n -i NONE`, CRLF-Normalisierung, argv statt Shell (SEC-01/02, HEREDOC.md), Prozessbäume beenden, `TEMP`/`TMP` umlenken |
| L7 | **Gates sind Spezifikation** | automatisierbare NEW/REL/REVIEW-Regeln werden Konformitäts-Checks; manuelle bleiben manuell, stehen aber im Report als „manuell" |
| L8 | **Sichere Defaults** | kein Netz, kein Schreiben außerhalb tmp, keine Secrets, kein `$NVIM` im Kind — Abweichung nur per Tag/Flag |

### D.3 Zielarchitektur v2

#### D.3.1 Schichten

```
┌──────────────── Oberflächen ─────────────────────────────────────┐
│ CLI (nvim -l) · :Spec-Commands · neotest-spec-Adapter            │
│ ui.nvim-Statusline-Modul · :checkhealth spec · GitHub-Annotations│
├──────────────── Consumer (Event-Bus) ────────────────────────────┤
│ term · github · junit · json · html · markdown · pdf(pdfport)    │
│ diagnostics (vim.diagnostic) · history · trace · fleet           │
├──────────────── Kernel ──────────────────────────────────────────┤
│ result (IR) · assert (sammelnd) · suite/case · discover (TS)     │
│ config (.spec.lua) · child (Kind-nvim-Treiber) · guard · cache   │
├──────────────── Erweiterungen ───────────────────────────────────┤
│ dialect/  A B C D busted                                         │
│ lang/     lua · jsts · go · python · rust · sh · luals · pty     │
│           vhs · playwright · webdriver                           │
│ advanced/ property · mutation · snapshot · flaky · synthetic     │
│           conformance · coverage · bench                         │
├──────────────── Primitiven (lib.nvim, verifiziert vorhanden) ────┤
│ async · system.job · fs.watch · fs.project_key · fs.path.object  │
│ diff.myers · json · strings.width · bindings.* · notify          │
│ context_manager · class · debounce · logger · cross              │
└──────────────────────────────────────────────────────────────────┘
```

Consumer abonnieren Events (`run:start`, `file:start`, `case:result`,
`file:end`, `run:end`) — das neotest-Muster (Consumer statt Reporter-Liste),
damit UI und Diagnostics **während** des Laufs füllen, nicht erst danach.

#### D.3.2 Das IR — der verbindliche Vertrag

```json
{
  "schema_version": 1,
  "run": {
    "id": "2026-09-20T18:04:11Z-3f9c",
    "root": "<REPO>",
    "project_key": "sessions.nvim@a1b2",
    "nvim": "0.12.0", "os": "windows", "arch": "x86_64",
    "git": { "sha": "7ec32e0", "dirty": false },
    "seed": 42, "jobs": 6, "duration_ms": 1830,
    "argv": ["--affected", "--isolated=file"]
  },
  "cases": [{
    "id": "TESTS/features/session_save_spec.lua::sessions: save current session",
    "file": "TESTS/features/session_save_spec.lua", "line": 3,
    "tags": ["feature", "binding:<leader>ssa", "command:Session save"],
    "status": "fail", "duration_ms": 212, "retries": 0,
    "assertions": [
      { "ok": true,  "msg": "exactly one session file written", "line": 17 },
      { "ok": false, "msg": "screen matches session_saved", "line": 18,
        "expected_ref": "TESTS/__snapshots__/session_save_spec/session_saved.snap",
        "diff": "@@ -3,1 +3,1 @@\n-Session saved: notes\n+Session saved: notes.md" }
    ],
    "effects": { "spawned": [], "network": [], "fs_outside_tmp": [] },
    "artifacts": [{ "kind": "trace", "path": "<STATE>/spec/sessions.nvim@a1b2/traces/2026-09-20T18-04-11Z-3f9c/case-12.json" }],
    "notes": []
  }],
  "summary": { "pass": 41, "fail": 1, "error": 0, "skip": 2, "xfail": 1, "xpass": 0, "timeout": 0, "crash": 0 }
}
```

Festlegungen:

- **Stabile IDs** `file::describe::case[#param]` — Schlüssel für Cache,
  History (`--lf/--ff`), Quarantäne und Flaky-Statistik.
- **Status-Enum** `pass | fail | error | skip | xfail | xpass | timeout |
  crash`. `skip` ist ein eigener Zähler und **nie grün** (NEW-43 bleibt
  intakt: ein Guard *im* Testkörper ist weiterhin verboten; ein Skip ist
  eine explizite, gemeldete Aussage mit Grund). `xpass` (erwarteter
  Fehlschlag, der plötzlich grün ist) ist ein Fehler — pytest `strict`.
- **`effects`** ist Pflicht: jeder gestartete Prozess, jeder
  Netzwerkversuch, jeder Schreibzugriff außerhalb tmp — das
  Playwright-Netzwerklog, übertragen auf Neovim.
- **Pfad-Platzhalter** `<REPO>`, `<HOME>`, `<TMP>`, `<STATE>` überall im IR
  und in Snapshots: deterministisch über Maschinen und ohne Usernamen in
  Artefakten.
- Aus dem IR werden JUnit, TAP, GitHub-Annotations (`::error
  file=…,line=…::`), `$GITHUB_STEP_SUMMARY`-Markdown, HTML und der
  pdfport-Report abgeleitet — kein Reporter parst je Testausgabe.

#### D.3.3 Konfiguration `.spec.lua` und Dependency-Auflösung

```lua
-- .spec.lua (repo root; typed via lua/spec/@types/config.lua)
return {
  plugin = "sessions",                 -- lua module root: conformance + coverage need it
  roots = { "TESTS" },                 -- legacy roots are discovered but reported (NEW-48)
  dialect = "spec",                    -- "spec" | "a" | "b" | "c" | "d" | "busted"
  minit = "TESTS/minimal_init.lua",
  deps = { "lib.nvim" },               -- each resolved: $<NAME>_DIR, .deps/, ../, stdpath('data')/lazy/
  setup = { keymaps = { save = "<leader>ssa" } },   -- opts the conformance suite calls setup() with
  conformance = { load_budget_ms = 40 },
  coverage = { bindings = 1.0, commands = 1.0 },    -- gate thresholds (0 = report only)
  timeouts = { case_ms = 10000, file_ms = 60000 },
  snapshots = { dir = "TESTS/__snapshots__" },
  backends = { luals = true, pty = false, playwright = false, webdriver = false },
}
```

- **Auflösung wie NEW-40 verlangt**, für jede Dependency und für spec.nvim
  selbst: `$SPEC_NVIM_DIR` → `.deps/spec.nvim` (CI, gepinnt auf
  `ci-verified`, wie lib.nvim es heute für runtime-analysis tut) →
  `../spec.nvim` → `stdpath('data')/lazy/spec.nvim`. Beim Scheitern werden
  **alle vier** genannt, Exit `3`.
- `scripts/test.sh` und `TESTS/minimal_init.lua` bleiben (NEW-39); `spec
  init` generiert beide (20 Zeilen, machen nur die Auflösung und rufen
  `require("spec.cli").main(arg)`). `nvim -l` reicht die Argumente nach dem
  Skript in `_G.arg` durch — keine `-c`-Strings mit Nutzertext (SEC-34/35).
- Cross-Repo-Wissen (Repo-Liste, lokale Checkouts) kommt **nicht** aus
  spec.nvim, sondern vom Aufrufer: `plugins.personal.export.projects()`
  liefert `{ name, repo, dir }` für alle aktiven Personal-Plugins — genau
  das, was `run_all_tests.sh` heute per Verzeichnis-Glob nachbaut.

#### D.3.4 Kind-nvim-Treiber `spec.child`

Der Kern von Tier 1–2 und der einzige Teil, den kein bestehendes Plugin
liefert (§D.1: sandbox.nvim ist Container, nicht Kind-nvim). Vorbild:
`mini.test`s `child` und Neovim-Cores `testnvim.lua`, ergänzt um Isolation
und Erfassung.

```lua
-- lua/spec/child/init.lua (sketch)
local Child = {}

--- Spawn an embedded, headless, fully isolated Neovim.
---@param opts Spec.Child.Opts  # minit, rtp, env overrides, size
function Child.spawn(opts)
  local run_dir = opts.run_dir -- private per run, under vim.fn.tempname()'s parent
  local env = spec_env.allowlist(vim.fn.environ(), {
    -- redirect every stdpath() into the run dir; works on Windows too
    XDG_CONFIG_HOME = run_dir .. "/xdg/config",
    XDG_DATA_HOME = run_dir .. "/xdg/data",
    XDG_STATE_HOME = run_dir .. "/xdg/state",
    XDG_CACHE_HOME = run_dir .. "/xdg/cache",
    NVIM_APPNAME = "spec",
    NVIM_LOG_FILE = run_dir .. "/nvim.log",
    TMPDIR = run_dir .. "/tmp", TEMP = run_dir .. "/tmp", TMP = run_dir .. "/tmp",
    LANG = "C.UTF-8", LC_ALL = "C.UTF-8", TZ = "UTC",
    -- never inherited: NVIM, NVIM_LISTEN_ADDRESS, *_TOKEN, *_KEY, *_SECRET, ANTHROPIC_*, OPENAI_*, GITHUB_*
  })
  local argv = { "nvim", "--embed", "--headless", "--clean", "-n", "-i", "NONE", "-u", opts.minit }
  local chan = vim.fn.jobstart(argv, { rpc = true, env = env, clear_env = true, cwd = opts.cwd })
  -- ...
end
```

Oberfläche (Namen an mini.test angelehnt, damit Wissen übertragbar ist):

| Methode | Zweck |
|---|---|
| `child.lua(code, args)`, `child.lua_get(expr)` | Code im Kind ausführen / Wert holen (`nvim_exec_lua`) |
| `child.api`, `child.fn`, `child.cmd`, `child.o/g/b/w` | Proxies wie bei mini.test |
| `child.input(keys)` | `nvim_input` (asynchron, wie echtes Tippen); `child.feed(keys)` = `nvim_feedkeys(..., "x")` synchron |
| `child.mouse(button, action, mods, row, col)` | `nvim_input_mouse` — der eigentliche „Klick-Simulator" für Floats, Statusline, Tabline, Kontextmenüs |
| `child.settle(timeout_ms)` | Poke (`nvim_eval("1")`), dann warten bis Typeahead leer (`getchar(1) == 0`) und keine plugin-eigenen Handles mehr aktiv sind (`vim.uv.walk`-Zählung gegen Baseline) — das Playwright-„networkidle" für Neovim |
| `child.screen()` | Text-Grid + Attribut-Form via `screenstring()/screenattr()` (Attribute sind nur vergleichbar, nicht auflösbar → Buchstabenkodierung wie mini.test); Highlight-Namen an einer Position per `vim.inspect_pos()` |
| `child.notifies()`, `child.messages()`, `child.prompts()` | Puffer, die ein Bootstrap-Modul im Kind füllt (Monkeypatch von `vim.notify`, `nvim_echo`-Mitschnitt via `:messages`, Prompt-Guard) |
| `child.effects()` | Prozess-/Netz-/FS-Ledger des Guards |
| `child.ensure_alive()` | nach jedem Schritt: lebt der Prozess noch? Ein Absturz (z. B. Treesitter) wird `crash`, nicht Hänger |
| `child.reset()` / `child.restart()` | Warm-Pool-Reset (Buffers, Autocmds, Keymaps, `package.loaded` des Plugins) mit Leak-Guard-Verifikation; bei Verdacht Neustart |
| `child.kill()` | Prozess**baum** beenden (Windows `taskkill /T /F`, POSIX Prozessgruppe) — ein von einem Spec gestartetes `ffmpeg` überlebt sonst |

Timeouts pro Fall (`case_ms`) und Datei (`file_ms`) enden hart im Kill,
Status `timeout`, mit dem Trace des Falls als Artefakt.

#### D.3.5 Guards v2

| Guard | Fängt | Mechanik | Modus |
|---|---|---|---|
| **FS** | Schreiben außerhalb `run_dir`/Repo-tmp | `lib.nvim.fs.watch` auf Repo-Root + Wrapper um `io.open("w")`, `vim.fn.writefile`, `uv.fs_open`; Pfade **aufgelöst** vergleichen (Symlinks, SEC-40) | fail |
| **State-Leak** | zurückgelassene Autocmds/Keymaps/Buffers/`vim.g`/Highlights | Snapshot vor/nach Fall, Diff via `lib.lua.diff` | fail, benannt („hinterlässt Autocmd X in Gruppe Y") |
| **Scheduled-Error** | Fehler in `vim.schedule`/Timern/Jobs (NEW-47) | `:messages`-Scan nach `E5108`/`Error executing vim.schedule lua callback`/`Error executing luv callback` nach jedem Fall + `vim.notify(ERROR)` | fail |
| **Prompt** | blockierende Eingabeaufforderungen | `vim.fn.input/inputlist/confirm/getchar/getcharstr`, `vim.ui.input/select` im Kind ersetzt: scripted answers per `a.answer_prompts{...}`, sonst sofortiger Fehler mit Stack | fail |
| **Deprecation** | `vim.deprecate`-Meldungen (0.12-Migration) | Monkeypatch im Kind | warn, `--strict` → fail |
| **Netz/Prozess** | `vim.system`, `jobstart`, `vim.fn.system`, `io.popen`, `os.execute`, `uv.spawn`, `uv.tcp_connect`, `vim.net.*` | blockiert und geloggt; `@network`/`@spawn`-Tag oder `--allow-…` gibt frei; Ledger landet in `effects` | fail |
| **Timeout** | hängende Fälle | Timer im Elternprozess + Kill | timeout |
| **Clock/Seed** | Zeit-/Zufalls-Flakes | `os.time/os.date/uv.now/hrtime/fn.localtime/strftime` virtualisiert (`a.clock.advance(ms)`), `math.randomseed(seed)`, `srand(seed)`; echte Timer bleiben echt (ehrliche Grenze) | opt-in pro Fall |
| **Env** | Secrets und `$NVIM` im Kind | Allowlist statt Blacklist (SEC-41) | immer |

Guards sind **Sicherheitsnetze, keine Sandbox** — Lua-Code kann jeden
Monkeypatch umgehen. Die echte Grenze ist der Prozess plus OS: Container
(sandbox.nvim) oder VM (Tier 4), siehe §D.8.

#### D.3.6 Discovery und Dialekte

- Positionen (`describe`/`it`/`t.test`/`spec.feature`) per tree-sitter-Query
  über den in Neovim gebündelten Lua-Parser — dieselbe Query nutzt der
  neotest-Adapter für `discover_positions` und `:Spec nearest`. Fallback bei
  Parser-Problemen (0.12: `language.add` meldet Parser, die nicht laden):
  Regex-Discovery auf Dateiebene.
- Dialekt-Erkennung per Signatur-Sniffing, überschreibbar in `.spec.lua`.
  Dialekt A (`return function(H) ... end`, `H.eq(actual, expected, msg)`)
  bekommt einen Shim, dessen `H.eq/ok` **sammeln** statt werfen und den Ort
  über `debug.getinfo(2)` erfassen — P1 ist damit für 16 Repos ohne eine
  Zeile Änderung erledigt. Der Sentinel (`LIB_TESTS_OK`) wird in einer
  Übergangszeit weiter ausgegeben, damit `run_all_tests.sh` alt und neu
  parallel versteht.
- Legacy-Orte (`docs/TESTS/`, `tests/`) werden gefunden, aber als
  NEW-48-Befund im Report geführt.

#### D.3.7 Speicherorte

| Was | Wo | Warum |
|---|---|---|
| History (`runs.jsonl`, Dauer, Flaky-Statistik, letzter Status je ID) | `stdpath("state")/spec/<project_key>/` | nie im Repo; `lib.nvim.fs.project_key` liefert den Schlüssel |
| Cache (Hash → Ergebnis) | `stdpath("cache")/spec/<project_key>/` | löschbar ohne Verlust |
| Traces, Screenshots, Logs | `stdpath("state")/spec/<project_key>/traces/<run>/` | Aufräumen per `spec gc --keep 10` |
| Snapshots | `TESTS/__snapshots__/<spec>/<name>.snap` | committed, textuell, git-diffbar (jest-Konvention) |
| Quarantäne | `.spec.lua` → `quarantine = { { id = "...", until = "2026-10-31", reason = "..." } }` | mit Ablaufdatum, sonst rottet sie |

#### D.3.8 Modulname

`spec`: Flotten-Grep findet kein `lua/spec/` in einem Sibling; busteds
`spec/`-Verzeichniskonvention ist kein Lua-Modul auf dem `runtimepath`. Der
`dap.nvim → wkddap`-Präzedenzfall (§B.10) galt einer **realen** Kollision
mit `nvim-dap`; ohne eine solche bleibt der kurze Name. Entscheidung in
§D.10.

### D.4 Feature-Katalog mit Herkunft

Was übernommen wird, von wem, und was das Ökosystem exklusiv beisteuert.
„Ö" = nur hier möglich, weil Graph/Registry/Regeln existieren.

**Ausführung und Selektion**

| Feature | Herkunft | Anmerkung |
|---|---|---|
| `--filter <expr>`, `--file`, `--tags`/`--exclude-tags` | busted, pytest `-k`/`-m` | Tags im Spec (`t.test("…", { tags = {"slow"} })`) und als Kommentar für Dialekt A |
| `--lf` / `--ff` (last failed / failed first) | pytest | aus der History |
| `-x` / `--maxfail N` | pytest, busted `--no-keep-going` | |
| `--shuffle --seed N`, Seed steht in jedem Fehler-Report | busted, pytest-randomly | Reproduzierbarkeit |
| `--repeat N`, `--flaky N` | busted `--repeat`, vitest `retry` | Flaky-Statistik in History |
| `--isolated=file\|case`, Default in-process mit Soft-Isolation | mini.test (Kind pro Fall), busted `insulate` | Soft-Isolation = `package.loaded`/Globals/Autocmd-Diff + Restore zwischen Dateien |
| `--jobs N`, `--shard i/n` | pytest-xdist, Playwright `--shard` | Worker-Pool über `lib.nvim.async` |
| `--affected [rev]`, `--changed` (git dirty), `--since <rev>` | Bazel/Nx, vitest `--changed`, Playwright `--only-changed` | Ö: über `deps.impact()` statt Dateinamen-Heuristik |
| `--cached` / `--no-cache` | Turborepo/Nx | `vim.fn.sha256` über Spec + Abhängigkeits-Hülle + Runner-Version + nvim-Version + relevante Env |
| `--watch` (failed first, Debounce, affected) | vitest, neotest watch | `lib.nvim.fs.watch` + `lib.nvim.debounce` |
| `--list`, `--dry-run`, `--durations N` | pytest `--collect-only`/`--durations` | |
| `--timeout <ms>` pro Fall/Datei | pytest-timeout, Playwright | hart, mit Kill |
| `--strict` | pytest `strict` xfail, vitest `bail` | Skips, `xpass`, Deprecations, `notify(ERROR)` werden Fehler — Standard in CI |
| Exit-Codes 0/1/2/3 | GoogleTest/pytest-Konvention | L2 |

**Assertions, Doubles, Fixtures**

| Feature | Herkunft | Anmerkung |
|---|---|---|
| sammelnde `a.eq/neq/ok/matches/same/error/no_error` mit Myers-Diff | luassert (Formen), vitest `expect.soft` (Semantik) | P1, P8 |
| `a.defer(fn)` (garantiert), `a.tmpdir()`, `a.tmpfile()`, `a.write()`, `a.ls()` | Go `t.Cleanup`/`t.TempDir`, busted `finally` | `lib.lua.context_manager` |
| `a.eventually(fn, opts)`, `a.await(fn, ...)` | Neovim-Core `retry`, Playwright auto-wait | P9 |
| `a.spy/a.stub/a.mock` auf Tabellenfeldern und Modulen, Aufruf-Assertions | luassert `spy`/`stub`/`mock` | `H.with_patched` aus lib.nvims Harness ist der Keim |
| `a.mock_module("lib.nvim.net.curl", fake)` | vitest `vi.mock` | `package.loaded`/`package.preload`-Tausch mit Restore |
| `a.record_system("ffmpeg")` — Aufzeichnen/Abspielen externer Kommandos | VCR/Betamax, Playwright HAR | Fixtures unter `TESTS/fixtures/system/`; CI ohne ffmpeg spielt ab |
| `a.fake_lsp{...}` — In-Process-LSP-Server | Neovim-Core-Tests | `vim.lsp.start{ cmd = function(dispatchers) … end }` (Lua-Funktion als `cmd`) — kein Binary; für lsp.nvim, hover.nvim, language.nvim |
| `a.answer_prompts{ input = "yes", select = 2 }` | — (Prompt-Guard, §D.3.5) | |
| `a.clock.freeze()/advance(ms)` | vitest `useFakeTimers` (teilweise) | ehrliche Grenze: echte `uv`-Timer bleiben echt |
| `t.each({...}, fn)` / `parametrize` | vitest `test.each`, mini.test `parametrize` | IDs mit `#param` |
| `t.todo`, `t.xfail(reason)`, `t.skip(reason)` | vitest `test.todo`, pytest `xfail`/`skipif` | nie still (NEW-43): jeder Skip mit Grund im Report |
| Hooks `before_all/after_all/before_each/after_each`, `lazy` | busted, mini.test `pre_once/post_once/pre_case/post_case` | |
| `TESTS/spec_helper.lua` je Verzeichnis | pytest `conftest.py`, busted `--helper` | Fixtures teilen ohne globalen State |

**Isolation, Screen, Snapshots**

| Feature | Herkunft | Anmerkung |
|---|---|---|
| `spec.child` (§D.3.4) | mini.test `child`, Neovim-Core `testnvim` | plus XDG/Env-Isolation, Effekte, Prompt-Guard |
| `a.screen(name)` — Text-Grid-Snapshot mit Attribut-Form | mini.test `expect.reference_screenshot`, Neovim-Core `Screen:expect` | Masken (Regex/Rechteck), Platzhalter, CRLF-Normalisierung |
| `a.snapshot(name, value)`, `--update-snapshots` | jest, insta | Review-UI: `:Spec review` mit diff.nvim, accept/reject je Datei (insta `cargo insta review`) |
| Inline-Snapshots (`a.snapshot_inline(value, [[…]])`) | vitest `toMatchInlineSnapshot` | später, optional |
| `a.hl_at(row, col)` → Highlight-Gruppen | `vim.inspect_pos()` | für color_my_ascii, markdown.nvim |
| Trace-on-failure (Eingaben, Screen je Schritt, Notifies, Effekte) | Playwright trace viewer | `:Spec trace <id>` rendert per `ui.kit` |

**UI, Workflow, Debugging**

| Feature | Herkunft | Anmerkung |
|---|---|---|
| `:Spec run\|nearest\|file\|last\|failed\|watch\|review\|trace\|coverage\|surface` | vim-test (`:TestNearest/File/Suite/Last/Visit`), neotest | Composer-Usercmd mit Completion (REL-22) |
| `neotest-spec`-Adapter (`root`, `is_test_file`, `discover_positions`, `build_spec`, `results`) | neotest | liefert Summary-Baum, Output-Panel, Inline-Diagnostics, Status-Zeichen, Jump, Watch, Quickfix **ohne eigene UI**; Teil B (`test.nvim`) registriert ihn nur |
| `--debug`: osv im Kind (`require("osv").launch{ port = P, blocking = true }`), Attach über dap.nvims `nlua`-Konfiguration | neotest `strategy = "dap"`, neotest-plenary | Port nur `127.0.0.1`, nur mit `--debug` |
| Inline-Diagnostics an der fehlenden Assertion | neotest `diagnostic`-Consumer | `vim.diagnostic`-Namespace `spec` |
| Statusline-Modul (letzter Lauf, Watch aktiv, Fehlerzahl) | — | ui.nvim-Statusline-Katalog; erledigt B.9 „Watch-Statusanzeige" |
| `:checkhealth spec` + `spec.health.last_run(plugin)` für fremde `health.lua` | REL-16, REL-18 | Testergebnisse fließen in `:checkhealth <plugin>` ein |
| GitHub-Annotations + Step-Summary, JUnit, HTML (self-contained), PDF via pdfport | Playwright `github`/`html`-Reporter, busted `junit` | alles aus dem IR |
| `spec init` (Scaffold: `.spec.lua`, `TESTS/minimal_init.lua`, `scripts/test.sh`, CI-Job) | lazy.minit, `create-*`-Generatoren | erfüllt NEW-39/40/45/49 per Vorlage |

**Qualität**

| Feature | Herkunft | Anmerkung |
|---|---|---|
| Property-Tests mit Shrinking und **Korpus** (fehlgeschlagene Eingaben unter `TESTS/corpus/` als Regressionen) | QuickCheck, Go `-fuzz` (`testdata/fuzz`) | PRIN-34 des Review-Gates |
| Mutation-Testing per tree-sitter (`>=`→`>`, `and`→`or`, Literal-Flip, Zweig weg), Mutation-Score mit Schwelle | Stryker/mutmut (Idee) | nur unter allen Guards (§D.8), nur mit Cache/Affected (§D.7) |
| Flaky-Erkennung + Quarantäne **mit Ablaufdatum** | vitest `retry`, Playwright `flaky`-Status | P6 an der Wurzel |
| Coverage: Funktionsebene über runtime-analysis (`instance.coverage()`), Zeilenebene opt-in per `debug.sethook("l")` im Kind → lcov | luacov, nvim-coverage (Anzeige) | Schwellen in `.spec.lua` (vitest `coverage.thresholds`) |
| `luals`-Backend: `lua-language-server --check --check_format=json` als Testart | vitest `typecheck` | NEW-44 „Null halten" wird ein roter Test statt einer Erhebung |
| `t.bench(name, fn)` mit Baseline-JSON und Regressions-Schwelle | vitest `bench`, Go `-bench` | `vim.uv.hrtime`, Warmup, Median; `scripts/bench_dispatcher.lua` in lib.nvim ist der erste Kandidat |
| `--profile` (LuaJIT `jit.p`) je Fall | — | für „warum dauert dieser Spec 2 s" |

**Ökosystem-exklusiv (Ö)**

| Feature | Baustein | Nutzen |
|---|---|---|
| Affected-Selection | `documentation.core.deps.impact(ir, id)`, `module_map.json`, Cross-Repo `consumers.index` | 2 statt 27 Dateien im Alltag; Cross-Repo: `lib.nvim`-Änderung → betroffene Specs in Konsumenten |
| **Binding-Coverage** (§D.6) | `bindings.keymap.registered(plugin)`, `usercmd.registered()`, `composer.registry()`, `autocmd.registered()` | „jedes Feature/Binding hat einen Test" wird messbar; Schwelle als Gate |
| **Konformitäts-Suite** (§D.6) | Gates NEW/REL/REVIEW, `bindings.audit.gaps/key_risks/prefix_ambiguities`, `composer.check_all()` | 35 Plugins, null Spec-Code |
| Regel-Brücke | rules.nvim-`check`-Prädikate (`lua_predicate`, `file_exists`) als Fälle | die heute manuellen Regeln bekommen einen laufenden Verdikt-Pfad |
| Telemetrie-Coverage | runtime-analysis `wrap_loaded`/`coverage()` | „diese 23 Exports ruft keine Spec auf" — Einstieg für die 14 Repos ohne Specs |
| Flotten-Sicht | JSON-IR je Repo → `report/fleet.lua`; `run_all_tests.sh` wird zur 10-Zeilen-Schleife | ersetzt Sentinel-Grep; `ci_status.sh` bleibt für GitHub-Verdikte |

**Vergleichsmatrix — was von wem**

| | plenary.busted | mini.test | neotest | busted/luassert | vim-test | lazy.minit | Playwright |
|---|---|---|---|---|---|---|---|
| **Übernommen** | Dialekt E (Shim) | `child`-API, Screen-Snapshots, Parametrize, Hooks | Consumer-Bus, Adapter-Interface, Diagnostics, DAP-Strategie | CLI-Flags, Output-Formate, spy/stub/mock, `insulate` | die fünf Commands | Scaffold-Idee | trace, `effects`-Ledger, Screenshot-Masken/Threshold, `--shard`, `--last-failed` |
| **Nicht übernommen** | Runner (P6) | eigenes Framework (K1) | eigene Ausführung (kein IR) | LuaRocks-Pflicht | Strategien (tmux/dispatch) | lazy als Laufzeit-Dep | Node als Pflicht (nur Tier 3) |

### D.5 Synthetische Tests konkret (Tier 1 bis 4, v2)

#### D.5.1 Tier 1 — Feature/Binding-Test

Ein Test pro Binding/Command. Die DSL erweitert §A.8 um `spec.feature`, das
den Fall an einen Registry-Eintrag koppelt (Binding-Coverage) und einen
frischen, isolierten Kind-Prozess liefert. Beispiel gegen die echte
sessions.nvim-Oberfläche (Keys sind dort standardmäßig aus; `save` ist ein
Config-Key, Speicherort `stdpath("data")/sessions`):

```lua
-- TESTS/features/session_save_spec.lua
local spec = require("spec")

return spec.feature("sessions: save current session", {
  binding = "<leader>ssa",              -- ties the case to the keymap registry entry
  command = "Session save",             -- and to the usercmd route
  child = {
    setup = function()                  -- runs inside the child after minit
      require("sessions").setup({ keymaps = { save = "<leader>ssa" } })
    end,
  },
}, function(a, nvim)
  nvim.edit(a.tmpfile("notes.md"))
  nvim.input("<leader>ssa")
  nvim.settle()

  a.notified({ level = "info", match = "saved" })
  local root = nvim.stdpath("data") .. "/sessions"   -- redirected into the run dir
  a.eq(#a.ls(root), 1, "exactly one session file written")
  a.screen("session_saved")           -- text grid, paths masked
  a.no_errors()                       -- :messages, scheduled callbacks, notify(ERROR)
end)
```

Was der Fall implizit prüft, ohne dass es dasteht: kein Schreiben außerhalb
des Run-Verzeichnisses (FS-Guard), kein Prozess, kein Netz (Ledger), kein
zurückgelassener State (Leak-Guard), keine Deprecation, kein Prompt.

**Maus**: `nvim.mouse("left", "press", "", row, col)` über
`nvim_input_mouse` — damit sind Klicks in Floats (ui.kit-Picker,
Kontextmenü von filetree.nvim), Statusline-Segmente und Tabline testbar,
ohne OS-Level-Input.

#### D.5.2 Tier 2 — Screen-Snapshots

- Format textuell wie mini.test: Zeilen des Grids, darunter Attribut-Zeilen
  mit Buchstaben pro unterschiedlicher Attribut-ID; ein `.snap` pro Name.
- **Masken** pro Snapshot: Regex (`%d%d:%d%d`, Pfade) und Rechtecke
  (Statusline-Uhr); Platzhalter `<TMP>`/`<HOME>`/`<REPO>`.
- **Normalisierung**: CRLF → LF, feste `lines`/`columns` (z. B. 80×24 und
  160×48), feste Locale/TZ (Env, §D.3.4), `termguicolors` fix, Farbschema
  `default`.
- Update: `--update-snapshots`; Review: `:Spec review` (diff.nvim, je Datei
  accept/reject). Veraltete Snapshots (kein Fall referenziert sie mehr)
  werden gemeldet (`--prune-snapshots`).
- Für Highlight-Aussagen (color_my_ascii, markdown.nvim) nicht das Grid,
  sondern `a.hl_at(row, col)` über `vim.inspect_pos()` — stabil gegen
  Layout, präzise in der Gruppe.

#### D.5.3 Tier 2.5 — PTY-/Protokoll-Capture (images.nvim, media.nvim, pdfport.nvim)

Korrektur zu §C.4: Diese Plugins schreiben Escape-Sequenzen (OSC 1337,
iTerm2-Protokoll) direkt ans Terminal. Man braucht **kein Pixelbild**, um
das zu prüfen — man braucht den rohen Bytestrom:

1. Neovim in einer echten PTY starten (Linux/WSL2: `tmux`/`script`/Python
   `pty`; Windows-nativ: ConPTY über einen kleinen Node-/Python-Wrapper —
   Empfehlung: **WSL2**, weil `tmux capture-pane -p -e` und PTY-Recorder dort
   fertig sind).
2. Rohausgabe mitschneiden, OSC-1337-Sequenzen parsen: `File=…;inline=1;
   width=…;height=…:<base64>`.
3. Assertions: Payload ist ein PNG (Header), Dimensionen passen zum
   Cell-Budget, Hash entspricht dem Fixture, Sequenz erscheint genau einmal
   pro Anzeige, nach `:Image clear` folgt das Lösch-Kommando.

Deterministisch, ohne Font-/DPI-Drift, in CI lauffähig. Als
`lang/pty.lua`-Backend mit demselben Vier-Funktionen-Interface. Pixel-Smoke
(„sieht es in WezTerm wirklich richtig aus") bleibt Tier 3, manuell oder in
der VM — WezTerm hat keinen Screenshot-CLI, unter Windows geht
`System.Drawing`-Capture per PowerShell.

#### D.5.4 Tier 3 — echter Browser, echte App

- **mdview.nvim → Playwright.** Fixture: Kind-nvim startet den mdview-Server
  auf einem freien Port (Port aus dem Kind auslesen), Playwright öffnet die
  Seite. Fehler in der Browser-Konsole = Fehlschlag; DOM-Assertions für
  Rendering und Cursor-Marker; `toHaveScreenshot` mit
  `maxDiffPixelRatio` und Masken; `--trace on-first-retry`. Läuft als
  `lang/playwright.lua` (`npx playwright test --reporter=json`), Ergebnis
  → IR. Browser-Binaries gepinnt, `PLAYWRIGHT_BROWSERS_PATH` im Cache
  (SEC-20/21). Determinismus: Docker-Image mit gepinnten Fonts für
  Screenshot-Vergleiche (sandbox.nvim-Engines starten es).
- **docmap-desktop → `tauri-driver` + WebdriverIO.** Tauri 2 unterstützt
  WebDriver auf **Windows** (braucht `msedgedriver` passend zur
  WebView2-Version) und **Linux** (`webkit2gtk-driver`); **macOS nicht**.
  Tests als `*.spec.ts`, JSON-Reporter → dieselbe Parse-Logik wie
  `lang/jsts`. Das Repo hat heute nur Rust-Unit-Tests mit
  `tauri::test::mock_app()` — kein echtes Fenster; das ist echte Vorarbeit,
  kein Umbau.
- **Terminal-Pixel (WezTerm)** nur als Smoke, siehe D.5.3.

#### D.5.5 Tier 4 — VM

Nur für OS-Integration (Clipboard nvim↔OS, Drag&Drop in filetree.nvim,
Fenstermanager/Fokus, Windows-Eigenheiten) **und** als einzige echte
Vertrauensgrenze für fremden Code (§D.8). Workflow: Snapshot → Lauf →
Rollback; Ergebnisse als IR-JSON zurück. Nicht vor M9, und nur wenn ein
konkreter Bug es rechtfertigt.

#### D.5.6 Trace-on-failure

Bei jedem fehlgeschlagenen Tier-1/2-Fall: Eingabesequenz, Screen nach jedem
Schritt, Notifies, `:messages`, Effekte, Zeitstempel → eine JSON-Datei +
`.snap`s. `:Spec trace <id>` spielt sie in einem ui.kit-Float ab (vor/zurück
pro Schritt). Das ist der Unterschied zwischen „fällt in CI" und „ich sehe,
was passiert ist".

### D.6 Konformitäts-Suite: Regeln, die laufen

Generische Fälle, die **jedes** Plugin mit `.spec.lua` bekommt, ohne eine
Zeile Spec — Regeln aus den Gates, die heute manuell sind, werden
Verdikte. Läuft immer im isolierten Kind.

| # | Check | Regel | Mechanik |
|---|---|---|---|
| K1 | Jedes Modul unter `lua/<plugin>/**` lässt sich einzeln `require`n | NEW-47, XP-06 | frischer Kind pro Modul-Batch; fängt fehlende Requires, Top-Level-Seiteneffekte, Case-Fehler (Linux-CI) |
| K2 | `setup()` zweimal = idempotent | — | Registry-Diff (Keymaps/Autocmds/Commands) nach 2. Aufruf leer |
| K3 | `setup({ keymaps = false })` registriert keine Keymaps | REL-20 | `keymap.registered(plugin)` leer |
| K4 | Jede Keymap hat `desc` | REL-21 | Registry |
| K5 | Jeder Usercmd hat Completion | REL-22 | `composer.check_all()` + `nvim_get_commands` |
| K6 | `:checkhealth <plugin>` läuft fehlerfrei | REL-16 | im Kind, Output geparst |
| K7 | Jede `pcall(require, …)`-Soft-Dependency hat einen Health-Check | REL-17 | statisch (Grep) vs. `health.lua` |
| K8 | Keine `vim.deprecate`-Meldung bei Laden/Setup | — | Deprecation-Guard |
| K9 | Kein Schreiben außerhalb tmp, kein Prozess, kein Netz beim Setup | SEC-22 | Guards/Ledger |
| K10 | Ladezeit-Budget (`require` + `setup()` ≤ `load_budget_ms`) | PERF-* | `vim.uv.hrtime`, Median aus 3 |
| K11 | Keine neuen Globals | LUA-* | `_G`-Diff |
| K12 | Keymap-Aktion ohne Command-Pendant | REL-22 (Kandidat) | `bindings.audit.gaps()` — nur Report |
| K13 | Fragile Keys / Präfix-Kollisionen | — | `bindings.audit.key_risks()`, `prefix_ambiguities()` — nur Report |
| K14 | `docs/BINDINGS.md`/`docs/commands.md` == Registry | REL-* Doku | Docgen erneut rendern, Diff leer |
| K15 | Statische Regeln mit `check` (`NEW-36/48/49/45`, `REL-16`) | rules.nvim | Prädikate als Fälle ausführen; rules.nvim bleibt Quelle |

**Binding-Coverage** ergänzt die Suite um das Maß aus der Ausgangsfrage:
Registry (Keymaps, Commands, ggf. Autocmd-Features) × Fälle mit
`binding:`/`command:`-Tags. Report je Plugin („`<leader>slt` — kein
Feature-Test"), Schwelle in `.spec.lua` (`coverage.bindings`), `:Spec
surface` zeigt die Matrix. Für die Piloten (M6) ist die Schwelle 1.0.

Auch die **nvim-config selbst** ist ein Testobjekt: `plugins/personal/init.lua`
pflegt `keys`-Listen, die „MÜSSEN `wkddap.bindings.keymaps` spiegeln"
(dap.nvim, ai.nvim) — ein Konfig-Spec, der `keys` gegen die Registry des
geladenen Plugins prüft, ersetzt den Kommentar durch ein Verdikt.

### D.7 Performance

**Budgets** (Ziele, in M0/M5 zu messen — Schätzungen):

| Lauf | Ziel |
|---|---|
| lib.nvim komplett, in-process | < 3 s |
| lib.nvim komplett, `--isolated=file --jobs 8` | < 15 s |
| Inkrementell (`--cached --affected`) nach einer Modul-Änderung | < 1 s Median |
| Konformitäts-Suite je Plugin | < 2 s |
| Ein Tier-1-Feature-Test (Warm-Pool) | 50–200 ms |
| Flotte: ~35 Plugins × ~30 Features ≈ 1 000 Tier-1-Fälle | 2–3 min voll, Sekunden inkrementell |

**Mechanismen, in Reihenfolge des Hebels:**

1. **Nicht laufen lassen** — Cache (`vim.fn.sha256` über Spec-Datei +
   `impact()`-Hülle + Runner-/nvim-Version + relevante Env) und
   Affected-Selection. Vorprüfung per `getftime/getfsize`, bevor gehasht
   wird.
2. **Nicht neu starten** — in-process mit Soft-Isolation als Default; Kind
   pro Datei nur bei `--isolated`; **Warm-Pool** mit `reset()` statt Respawn
   (Prozess-Start ist der Flaschenhals, unter Windows durch AV/EDR-Scans
   pro Spawn noch mehr — die personal-Config dokumentiert genau diesen
   Effekt bei github_stats). Neustart nur bei Leak-Verdacht.
3. **Parallel** — Worker-Pool (`lib.nvim.async`, `system.job`), `--jobs` =
   Kerne − 1, `--shard` für CI-Matrix.
4. **Billig messen** — `--durations`, `--profile` (`jit.p`), Zeiten in der
   History → langsame Fälle sichtbar.
5. **Lazy Backends** — `lang/*` werden nur geladen, wenn `.spec.lua` sie
   aktiviert; kein Node-/Playwright-Start ohne Tier 3.
6. **`vim.loader.enable()`** im Kind (Bytecode-Cache), `-i NONE -n`.
7. **Watch** mit Debounce, failed-first, affected — Feedback in
   Sub-Sekunden beim Editieren.

**Anti-Ziele:** kein nativer Sidecar (F4 bleibt), keine Prozess-Wiederver-
wendung ohne Leak-Guard (Korrektheit vor Geschwindigkeit), `--affected`
nie Default in CI (§A.15).

### D.8 Security-Modell

**Bedrohungsmodell**

| Asset | Bedrohung | Kontrolle |
|---|---|---|
| Der laufende Editor des Users | Kind erbt `$NVIM` und spricht per `sockconnect` zurück; ein Spec (oder ein Mutant) führt Code im Elternprozess aus | `$NVIM`/`NVIM_LISTEN_ADDRESS` nie vererben; Kind nur über `--embed`/stdio, kein `--listen` (Named Pipes sind unter Windows für lokale Nutzer erreichbar) |
| Echte Nutzerdaten (`stdpath`, `~`) | Spec schreibt Sessions/Logs/Caches in echte Verzeichnisse | XDG-Umlenkung + `NVIM_APPNAME` + `TEMP/TMP/TMPDIR` in den Run-Ordner; FS-Guard mit aufgelösten Pfaden (SEC-40); `HOME` bleibt echt (Git braucht es), `--isolate-home` opt-in |
| Secrets | `GITHUB_TOKEN`, `ANTHROPIC_*`, `OPENAI_*`, `GEMINI_*`, pdfport-Key im Env; Specs lösen bezahlte API-Calls aus | Env-**Allowlist** (`PATH`, `SYSTEMROOT`, `ComSpec`, `HOME/USERPROFILE`, `LANG`, `TZ`, `VIMRUNTIME`), Rest gestrichen (SEC-41); Netz-Guard blockiert ohnehin |
| Netz | unbeabsichtigte Requests, Datenabfluss | Netz-/Prozess-Guard default an; Freigabe nur per Tag/Flag; Ledger im IR (SEC-22) |
| Shell | Testnamen/Pfade in Shell-Strings | ausschließlich argv (`vim.system({...})`, `cwd` gesetzt) — SEC-01/02; Filter/Argumente nie via `-c`/`vim.cmd` (SEC-34/35) |
| Reports | Injection in JUnit-XML/HTML/Markdown/PDF durch Testausgaben | Escaping je Format; pdfport bekommt eine Datei, keinen String durch die Shell (HEREDOC.md) |
| Artefakte | Usernamen/Pfade in Snapshots und Traces | Platzhalter (§D.3.2); Traces unter `stdpath("state")` mit User-Rechten; `spec gc` |
| Cache | vergiftete Ergebnisse | nur lokaler Cache pro User; Hash enthält Runner-/nvim-Version; `--no-cache` immer möglich; nie zwischen Vertrauensgrenzen teilen |
| Tier 3 | Browser-/Driver-Downloads | Versionen gepinnt, Checksums, Byte-Limits, Timeouts (SEC-20/21); Container-Image für CI |
| Debugging | osv-Port offen | `127.0.0.1`, nur `--debug`, zufälliger Port, Token in der Attach-Konfiguration |
| Mutation-Testing | mutierter Code tut Unvorhersehbares (Pfadprüfung `~=`→`==` und ein `rm`) | nur mit allen Guards, nur im Kind, nur mit umgeleitetem `HOME`, nie mit Netz |
| Fremde Repos | „Tests laufen lassen" = Code ausführen | `--trust` für Repos außerhalb der eigenen Liste (`plugins.personal.export.projects()`), Entscheidung in `stdpath("state")` gespeichert — VS-Code-Workspace-Trust |

**Ehrliche Grenze:** Monkeypatch-Guards halten Unfälle auf, keine
Angreifer. Wer fremden Code testet, tut das im Container (sandbox.nvim
startet ihn) oder in der VM (Tier 4). Genau das ist das zweite, legitime
Argument für VMware neben der OS-Integration.

**Selbstverpflichtung des Runners:** spec.nvim erfüllt die SEC-Regeln
des Review-Gates selbst und führt sie als eigene Konformitäts-Fälle
(Dogfood, §A.14).

### D.9 Konkreter Plan (M0 bis M9)

Ersetzt §A.13 in der Reihenfolge; Inhalte bleiben, UI und Konformität
rücken nach vorn. Aufwände sind grobe Personentage für einen Entwickler mit
Ökosystem-Kenntnis; „Produkt" im Sinne von §A.15 sind **M0–M5**.

#### D.9.0 Sofortmaßnahmen (ohne spec.nvim, je < 1 Tag)

> **Stand:** alle sechs Maßnahmen sind seit 2026-09-21 in der Flotte umgesetzt,
> Protokoll seit 2026-09-25 in WKDBooks
> `Development/wkdbook-myplugins/ALL/Backlog/TASKS/Handover_ERLEDIGT/ci-sofortmassnahmen-rollout.md`
> (anderes Repo, kein relativer Link von hier aus möglich).

1. `timeout-minutes: 15` in allen 38 `ci.yml` — heute hängt ein toter
   Runner bis GitHubs 6-Stunden-Limit.
2. `-n -i NONE` in allen Runner-Aufrufen (Swap-/Shada-Freiheit; ~2 000
   Swap-Leichen haben bereits Suiten mit E326 gebrochen).
3. `actions/upload-artifact` bei Fehlschlag (Log, später Traces).
4. `docs/TESTS/` → `TESTS/` für die neun NEW-48-Verstöße.
5. `.deps/`-Refs überall auf `ci-verified` pinnen (lib.nvim publiziert den
   Ref bereits).
6. `run_all_tests.sh`: `NVIM`/`NVIM_LISTEN_ADDRESS` aus dem Env der Kinder
   streichen — Defense in Depth, bis spec.nvim das übernimmt.

#### Meilensteine

| M | Ziel | Inhalt | Übernommen von | Exit-Kriterium | Aufwand |
|---|---|---|---|---|---|
| **M0** | Falsifikation | Kernel-IR, sammelnde Assertions, Dialekt-A-Shim; lib.nvims Suite (61 Dateien, run.lua) unverändert; Baseline-Zeiten; JSON-Ausgabe; Prüfung der unverifizierten lib.nvim-Symbole | busted (Semantik), Neovim-Core (`eq/ok`) | identisches Verdikt wie `TESTS/run.lua`, alle Fehler einer Datei sichtbar, Zeiten protokolliert — sonst Konzept kippen | 1–2 d |
| **M1** | Runner, der nicht lügt | CLI + Exit-Codes, `.spec.lua`, Discovery (TESTS/ + Legacy mit Befund), NEW-40-Auflösung, Dialekte B/C/D/busted, Filter/Tags/`--lf`/`--ff`/`-x`/`--durations`/`--list`, Seed/Shuffle, Timeouts, term-Reporter mit Diff, GitHub-Annotations, JUnit, `spec init`, CI-Vorlage, `run_all_tests.sh` → Schleife über `--json` | busted, pytest, Playwright `github` | alle 19 Repos mit Specs laufen unter spec mit identischem Verdikt; plenary aus dap/sandbox/github_stats-CI entfernt | 5–8 d |
| **M2** | Isolation & Guards | `spec.child` v1 (Env-Allowlist, XDG, `$NVIM` weg, Prozessbaum-Kill), `--isolated=file\|case`, Soft-Isolation, Warm-Pool, State-Leak-, FS-, Scheduled-Error-, Deprecation-, Prompt-, Netz-/Prozess-Guard, `settle()`, Notify-/Messages-Capture | mini.test `child`, Neovim-Core `testnvim` | Guards finden ≥ 1 echten Leak in der Flotte (erwartet), Suiten danach grün; keine Datei reißt mehr eine andere mit | 5–7 d |
| **M3** | UI & Debug ohne eigene UI | `neotest-spec`-Adapter (tree-sitter-Positionen, `build_spec`, `results` inkl. Diagnostics), `--debug` (osv im Kind + dap.nvim-Attach), `:Spec run\|nearest\|file\|last\|failed\|watch`, Statusline-Modul, `:checkhealth spec`, `spec.health.last_run()` | neotest, vim-test, neotest-plenary (DAP) | „run nearest" aus dem Buffer mit Inline-Diagnostic; Breakpoint in einem Spec trifft | 3–5 d |
| **M4** | Konformität & Binding-Coverage | K1–K15, Registry-basierte Coverage, `:Spec surface`, rules.nvim-Brücke, nvim-config-Spec für `keys`-Listen | Gates NEW/REL/REVIEW, `bindings.audit` | Report für alle 35 Plugins; Befunde triagiert; Coverage-Schwelle konfigurierbar | 3–5 d |
| **M5** | Schnell | Cache (`sha256` + `impact()`), `--affected/--changed/--since`, Worker-Pool, `--shard`, Watch (failed-first), `--profile` | Turborepo/Nx, pytest-xdist, vitest watch | inkrementeller Lauf < 1 s Median auf lib.nvim; Cross-Repo-affected für eine lib.nvim-Änderung demonstriert | 4–6 d |
| **M6** | Snapshots & Tier 1 | `a.snapshot`, `a.screen` mit Masken/Normalisierung, `:Spec review`, `spec.feature`, Maus, Trace-on-failure, Piloten **sessions.nvim** und **pickers.nvim** mit 100 % Binding-Coverage | mini.test, jest/insta, Playwright trace | Piloten bei 1.0; ≥ 1 realer Bug gefunden (wahrscheinlich); Snapshots auf Windows und Linux identisch | 6–10 d |
| **M7** | Qualität | Property + Shrinking + Korpus, Flaky/Quarantäne mit Ablauf, Coverage (Funktion via runtime-analysis, Zeile via sethook → lcov, nvim-coverage), `luals`-Backend, `t.bench` mit Baseline | QuickCheck/Go fuzz, luacov, vitest typecheck/bench | Mutation noch nicht; Coverage-Schwellen in 3 Repos aktiv | 6–10 d |
| **M8** | Multilang & Tier 2.5/3 | `lang/jsts`, `go`, `python`, `rust`, `sh`; `lang/pty` (images/media/pdfport), `lang/playwright` (mdview), `lang/webdriver` (docmap-desktop); Container-Image via sandbox.nvim für Screenshot-Determinismus | neotest-Adapter-Landschaft, Playwright, tauri-driver | mdview: Konsolenfehler = rot; images.nvim: OSC-1337-Payload verifiziert in CI; docmap-desktop: ein wdio-Smoke unter Windows | 8–12 d |
| **M9** | Cutting edge | Mutation-Testing mit Score, Flotten-Dashboard (`report/fleet.lua`, ui.kit + pdfport-PDF), HTML-Report, Tier-4-Evaluation nur bei konkretem Bedarf | Stryker (Idee), insta | Mutation-Score für lib.nvim gemessen; Dashboard über alle Repos | 8+ d |

**Definition of Done je Meilenstein** (aus den Gates): luacheck/stylua
grün, `lua-language-server --check` bei 0, README + `doc/spec.txt` +
`docs/commands.md`/`docs/BINDINGS.md` (generiert) aktualisiert,
`:checkhealth spec` grün, CI 3-OS mit Timeouts und Artefakten, `ci-verified`
publiziert, spec.nvim testet sich mit sich selbst.

**Repo-Scaffold** für `spec.nvim` (NEW-Gate): `lua/spec/` mit `@types/`,
`README.md` (deutsch), `doc/spec.txt`, `docs/{commands.md,BINDINGS.md,
ROADMAP.md,FEATURES/}`, `lua/spec/health.lua`, `.luarc.json` (ohne
`workspace.library`, mit `ignoreDir`), `stylua.toml` (`line_endings` =
`.gitattributes`), `.luacheckrc`, `TESTS/` + `scripts/test.sh`,
`.github/workflows/ci.yml` (Matrix, `timeout-minutes`, Artefakte, JUnit,
`publish-ci-verified`).

### D.10 Entscheidungen vor M0

| Frage | Empfehlung | Warum | Alternative |
|---|---|---|---|
| Modulname | `spec` | keine Kollision im Flotten-Grep; B.10-Präzedenz galt einer echten | `wkdspec` (sicher, hässlich) |
| DSL | eigene (`spec.describe`, `t.test`, `a.eq`) **plus** busted-Shim | keine Globals → luacheck ohne `std` (NEW-49 gegenstandslos), Kontextobjekt `a` ermöglicht Sammeln/Defer/Effekte; Shim hält Dialekt E am Leben | busted-kompatible Globals als Hauptdialekt |
| Konfig | `.spec.lua` im Root | Lua, typisiert, neben `.luarc.json`/`.luacheckrc`/`stylua.toml` | `TESTS/config.lua` |
| Isolation-Default | in-process + Soft-Isolation; Kind bei `--isolated`, Konformität und `spec.feature` immer Kind | Geschwindigkeit dort, wo es sicher ist; Korrektheit dort, wo State entsteht | immer Kind (mini.test) — zu langsam unter Windows |
| Speicherorte | `stdpath("state"/"cache")/spec/<project_key>/`, Snapshots im Repo | Repo bleibt sauber; History überlebt Checkout-Wechsel | `.spec/` im Repo (gitignored) |
| Snapshot-Format | textuell, mini.test-nah, mit Masken | git-diffbar, Review ohne Tooling möglich | Binär/PNG (nur Tier 3) |
| Coverage | Funktion via runtime-analysis (Default), Zeile via `sethook` (opt-in) | billig vs. genau; beides lcov-kompatibel für nvim-coverage | nur luacov (LuaRocks-Pflicht) |
| Tier-2.5/3-Host | WSL2 für PTY/tmux und Playwright; WezTerm nur Smoke; Container für CI-Determinismus | fertige Werkzeuge, keine ConPTY-Eigenbauten | Windows-nativ mit node-pty |
| Bootstrap-Zirkel | lib.nvim behält `TESTS/harness.lua` für `error/async/fs/system` (§A.15) | ein lib.nvim-Bug darf seinen Test nicht verstecken | alles auf spec.nvim |
| Release-Policy | `ci-verified`-Ref wie lib.nvim; Konsumenten pinnen in `.deps/` | bewährt, kein Registry-Zwang | Tags/Semver |
| UI | neotest-Adapter zuerst, eigene UI später optional | Scope-Explosion (§A.15) begrenzen | eigene UI in M3 |
| Skips | erlaubt, aber nie still, nie grün, `--strict` in CI | NEW-43 bleibt; fehlende Tier-3-Tools sind ein gemeldeter Zustand, kein Pass | Skips verbieten (bricht Tier 3 auf Maschinen ohne Tools) |
| `plenary.nvim` (Test-Harness) | **aktiv ersetzen**, nicht nur bis Dialekt E lauffähig bleibt (§B.11-Update 2026-09-22) | Nutzerentscheidung; echte `plenary.nvim`-Dependency in allen elf betroffenen Repos (Liste in §B.11) entfernen, sobald deren busted-Shim (Zeile "DSL" oben) sie ersetzt — nicht nur für `dap`/`sandbox`/`github_stats` (alter §A.13-Phase-5-Stand) | plenary als Dauerzustand für Dialekt E belassen (verworfen) |

### D.11 Offene Fragen und Risiken v2

- **Scope** bleibt das Hauptrisiko. Gegenmittel sind die Exit-Kriterien
  je Meilenstein und die Regel: Nichts ab M6 ist Bedingung für den Nutzen
  von M0–M5.
- **Windows-Prozesskosten.** Warm-Pool ist Pflicht, kein Nice-to-have; M0
  misst Spawn-Zeiten auf dieser Maschine explizit.
- **Guard-Fehlalarme** (Plugins, die legitim in `stdpath("data")`
  schreiben — sessions, cmdlog, images-Kalibrierung). Antwort: das ist
  kein Fehlalarm, sondern genau der Grund für die XDG-Umlenkung; echte
  Ausnahmen per Allowlist in `.spec.lua`, sichtbar im Report.
- **Snapshot-Churn** bei UI-Änderungen. Masken, Normalisierung, Review-UI,
  und Snapshots nur dort, wo Layout das Feature ist.
- **neotest als UI-Abhängigkeit.** Der Adapter ist optional; CLI und
  `:Spec` bleiben unabhängig. Teil B (`test.nvim`) entscheidet, ob neotest
  überhaupt bleibt — spec.nvim funktioniert so oder so.
- **tree-sitter unter 0.12** (`language.add` meldet Parser, die nicht
  laden — bekannt aus der Flotte). Discovery hat einen Regex-Fallback;
  Mutation-Testing braucht den Parser wirklich und bleibt deshalb M9.
- **Tier 3 auf dieser Maschine.** WSL2, msedgedriver und ein
  Container-Engine sind Voraussetzungen; ohne sie sind Tier-2.5/3-Fälle
  **gemeldete Skips**, keine grünen Läufe.
- **VHS-Annahme prüfen** (kein OSC 1337 in xterm.js/ttyd) bevor irgendwo
  „VHS" als Backend eingeplant wird; falls doch möglich, ist es ein
  zusätzlicher, kein ersetzender Pfad zu D.5.3.
- **`documentation.nvim`-Graph** muss aktuell sein, sonst lässt
  `--affected` Fälle aus — deshalb nie Default in CI (§A.15) und
  `spec doctor` warnt, wenn `module_map.json` älter ist als der letzte
  Commit.
