# testing.nvim in der Flotte: Testabdeckung und Extraktionskandidaten

Audit vom 09.10.2026 · Messbasis: die 42 eigenen `*.nvim`-Repos auf `main` (alle sauber), testing.nvim `41a3e1f3` · Nur lesend: gemessen wurde in lokalen Klonen,
**kein Repo wurde verändert.** Werkzeuge und Rohdaten: `TOOLS/scripts/fleet-test-audit/` (§8).

## Kurzfassung

**(a) Passt die Testabdeckung?** Als Niveau ja, als Verteilung nicht.

- **Zeilenabdeckung:** Median 85,4 % (Spanne 58,1–97,7 %), flottenweit 81,9 % von 226.345 ausführbaren Zeilen, gemessen für 41 von 42 Repos.
  22 Repos liegen bei ≥ 85 %; **unter 70 %:** media 58,1, images 61,9, my 65,5, recommender 67,5, mdview 67,6, markdown 69,5, lib 69,99.
- **Die Lücke liegt auf wenigen Repos, aber verteilt über viele Dateien:** zehn Repos halten 62 % aller offenen Zeilen, keine einzelne Datei mehr als 3 %. Zu 45 % ist es **Kernlogik**, nicht Oberfläche
  (UI 21 %, Kommandoschicht 15 %, Health 4 %).
- **Die Einstiegspunkte werden kaum ausgeführt:** `plugin/` in 25 von 26 Repos nie; Binding-Coverage Keymaps 10 %, Commands 32 %, Autocmds 54 % (sieben Repos: 0 %).
- **Die Struktur verdeckt viel:** 64 % der Spec-Dateien sind genau ein Fall; `filetree`, `pickers`, `cmdlog` laufen als Skript-Monolithe (eine Assertion je Datei); der
  `state`-Guard steht in 20 von 39 Repos nicht auf `error`; Konformität: 1 pass, 29 warn, 9 fail, 1 error.
- **Pflege:** 18,4 % der Verhaltens-Commits der letzten 30 Tage ohne Teständerung; > 30 % bei my, images, mdview, color_my_ascii, lib, markdown.
- **Betrieb:** 35 von 43 Repos in der CI grün; rot sind **testing.nvim selbst** (F-1), ui, replacer, lib und die zwei privaten (Billing); lokal rot: gitsuite, lib, ui.

**(b) Was baut die Flotte von Hand nach?** testing.nvim ist als **Runner** überall eingeführt, als **Bibliothek** nirgends: **kein** Repo nutzt eine Spec-API.

- Rund **22.800 Zeilen Setup-Kopien** (CI 42×, `test.sh` 40×, `minimal_init` 40×, `harness.lua` 23×, `run.lua` 10×), fast alle voneinander abweichend; die Vier-Orte-Dependency-Suche
  gibt es dreifach.
- **806 Hilfsfunktionen (6,8 KLOC) in acht Familien** im Testcode plus ≈ 300 Inline-Stubs; `scratch` hat fünf Signaturen, `capture_notify` 11 Bodies, `eq` 7 Varianten.
- Gleichnamige Specs (`config_spec` ×30, `health_spec` ×24, `usrcmds_help_spec` ×24) prüfen denselben Vertrag mit nur 7–29 % gemeinsamem Text.
- **16 Kandidaten (§4):** sechs P1 — **E-06 `testing.kit`** (Standard-`H`), **E-02** (Dependencies nur im Runner), **E-03 `testing sync`**, **E-01** (wiederverwendbare CI),
  **E-11** (Skript → Einzelfälle), **E-13** (Zeilenabdeckung; der Prototyp liegt vor).

**Sofort zu tun** (§7.1): testing.nvim-CI (F-1) und replacer-CI (F-12) wieder grün, ui↔lib-Kit-Drift (F-8), `vim` aus allen `.luarc.json` (eine Zeile, 38 Warnungen).

## Inhalt

1. Grundlage und Methode · 2. Einführungsstand · 3. **Frage (a): Passt die Testabdeckung?** · 4. **Frage (b): Was lohnt sich als Modul?** · 5. Befunde am Werkzeug (F-1 … F-13) ·
6. Nicht geprüft · 7. Empfohlene nächste Schritte · 8. Reproduktion und Werkzeuge · Anhang A–E (Zahlen je Repo)

## 1. Grundlage und Methode

Alles in diesem Bericht ist **gemessen**, nicht geschätzt; wo ein Wert eine Näherung ist, steht es dabei. Eine Ausnahme sind die
Aufwandsangaben in §4 und §7 — das sind Schätzungen.

| Was | Wie | Werkzeug (alle unter `TOOLS/scripts/fleet-test-audit/`, §8) |
|---|---|---|
| **Bestand** | die 42 eigenen `*.nvim`-Repos unter `E:\repos` (ohne `plenary.nvim`, das ist Upstream); alle auf `main`, **0 geänderte und 0 ungetrackte Dateien**, SHAs im Anhang D | `repo_state.sh` |
| **Messumgebung** | lokale Git-Klone (volle Historie, `origin`-URL erhalten, Push abgeschaltet) unter `C:\tnf\fleet`, nicht in den echten Repos; kurzer Pfad, weil der Scratchpad-Pfad (≈175 Zeichen) `MAX_PATH` sprengte; Windows 11, 12 Threads, Neovim 0.12.2, **testing.nvim `41a3e1f3`** | `make_clones.sh`, `fix_remotes.sh` |
| **Statische Inventur** | eigener Lua-Scanner (Kommentare und String-Inhalte maskiert, Funktionsgrenzen über `function/if/do/repeat … end/until`), je Repo: Module, Code-LOC, Spec-Dateien, Verweise der Tests auf Module und exportierte Funktionen, alle Hilfsfunktionen des Testcodes (Name, Zeilen, Body-Hash), 48 Idiome (Stubs, Fixtures, Warten, Gates …), gelesene Umgebungsvariablen | `inventory.js`, `lualex.js`, `census.js`, `funcs.js`, `families.js` |
| **Läufe** | die Suite jedes Repos über **sein eigenes `scripts/test.sh`** (wie CI und Entwickler), `--json`, `--jobs 4`; lib.nvim wie im `lib-suite`-Job von testing.nvim (`--first-run --rtp …/runtime-analysis.nvim`) | `run_suites.sh`, `irstats.js` |
| **Zeilenabdeckung** | ein Zeilen-Hook (`debug.sethook`) wird als erste Zeile jeder `TESTS/minimal_init.lua` geladen und schreibt je Prozess jede ausgeführte Zeile von `lua/ plugin/ after/ ftplugin/ autoload/` in eine Datei; die Nenner (Zeilen mit Bytecode) kommen aus `jit.util`; Zeilen, die nur `end` enthalten, zählen nicht. Der Hook fügt sich in den In-Process-Timeout-Guard von testing.nvim ein (§3.1) | `covprelude.lua`, `covreport.lua`, `prep_cov.sh`, `run_cov.sh`, `covagg.js` |
| **Binding-Coverage** | `surface = { track = true }` über eine Wrapper-Config (`--config`), danach `testing surface . --from ir.json` | `run_surface.sh` |
| **Konformität** | `testing conformance . --json` (K1–K15, report-only) | `run_conformance.sh`, `confagg.js` |
| **Pflege der Tests** | `git log --numstat` aller Repos: gehört zu einem `feat/fix/perf/refactor`-Commit, der Code ändert, auch eine Test-Änderung? (alle Historie und die letzten 30 Tage) | `churn.js` |
| **CI-Stand** | `scripts/ci_status.sh` der nvim-Config (lesende `gh`-Abfragen) und `gh run view` für die roten Läufe | — |
| **Boilerplate-Drift** | Zeilen-Diff jeder Kopie gegen den Medoid (die Kopie mit der kleinsten Summe der Abstände), Repo-Namen normalisiert | `drift.js`, `drift2.js`, `contract_specs.js` |

**Grenzen, ehrlich:**

- **Ein Lauf je Repo, eine Maschine, ein Betriebssystem (Windows).** Was auf Linux/macOS anders läuft (Skips, Pfade), sagt die CI;
  deren Stand steht in §3.7.
- **Die Hook-Messung kostet Laufzeit** (JIT aus, eine Funktion je Zeile): im Median das 1,8-Fache der normalen Zeit, im oberen Viertel ≥ 2,9×, im
  Maximum 7,2× (`language`). Dadurch waren **69 Fälle in 8 Repos nur mit Hook rot** — Skalierungs-Specs („stays fast", „stays linear") und Dateien, die
  das Limit von 60 s rissen (lsp `env_links_spec.lua`: 46 Fälle als `error`). Ihr Code läuft trotzdem; die zehn betroffenen Dateien wurden **einzeln
  mit großen Limits wiederholt** und die Treffer mit den bisherigen vereinigt, sodass die Abdeckung dort nicht abgeschnitten ist (Zahlen in §3.1).
- **Nicht gezählt** wird Code, der nur in Editoren läuft, die ein Spec selbst startet (`jobstart nvim …` ohne Hook), und Code in
  `vim.uv.new_thread`-Threads.
- **Umgebungsabhängige Specs** laufen auf dieser Maschine so, wie diese Maschine ist: fehlt ein Tree-sitter-Parser, wird der
  zugehörige Block nicht ausgeführt (§3.4). Die Zahlen sind „Abdeckung auf einer Entwickler-Maschine mit den Parsern von heute".
- **Ausführbare Zeilen enthalten Konstanten-Tabellen und Funktionsköpfe**, die beim Laden ausgeführt werden: Zeilenabdeckung
  überschätzt die Prüfung von Verhalten. Sie ist eine **untere Schranke für „ungetestet"** (was nie läuft, ist es sicher), keine Garantie
  für „getestet".
- **Binding-Coverage** gilt nur für das, was das Default-`setup()` registriert (in keinem Repo ist `setup` in `.testing.lua` gesetzt).
- Die **Abdeckungswerte von `lib.nvim` und `testing.nvim`** stehen unter §3.2 gesondert (Besonderheiten dort).

## 2. Einführungsstand: wer nutzt testing.nvim wie

**testing.nvim ist als Runner flächendeckend eingeführt — als Bibliothek wird es von keinem Repo genutzt.** Die README sagt noch
„Moving the fleet's repositories over has not happened" (`README.md`, Zeilen 40–41); das ist seit den Migrationen vom 06.–08.10. überholt.

| Baustein | Repos (von 41 ohne testing.nvim) | Anmerkung |
|---|---:|---|
| `.testing.lua` | 39 | fehlt: `lib.nvim` (dokumentierte Ausnahme, Entscheidung A vom 06.10.), `replacer.nvim` (**nicht migriert**) |
| `scripts/test.sh` | 39 | dieselben zwei fehlen |
| CI führt `scripts/test.sh` aus (Matrix Ubuntu/Windows/macOS) | 39 | `lib` und `replacer` ohne testing.nvim; `color_my_ascii` hat die CI unter dem Dateinamen `lint.yml` (Name „CI") |
| Lint-Jobs in der CI (stylua + luacheck) | 41 von 41 | |
| `TESTS/README.md` | 34 | fehlt: documentation, gitsuite, media, my, rules, runtime-analysis, tasks |
| Hooks (pre-push/pre-commit/Claude-Stop) installiert | **0** | nur als Rezepte in `docs/HOOKS.md` |
| **Spec-seitige testing.nvim-API genutzt** (`require("testing…")` in `TESTS/` oder `scripts/`) | **0** | auch kein Erwähnen von `testing.rpc/guard/surface/core/deps` in Code, Doku oder CI anderer Repos |
| `surface.track` / `coverage.*`-Schwellen / `setup` für K2–K14 | **0 / 0 / 0** | |
| `conformance` konfiguriert (Waiver, `keymaps_off`) | 3 | testing.nvim selbst (2 Waiver), zwei `keymaps_off` |
| `jobs` / `pool` / `cache.enabled` | **0 / 0 / 0** | alle Läufe seriell, kein Pool, kein Cache; `--cached` steht in **keiner** anderen CI, `actions/cache` nur bei `mdview` |
| Guards (39 Repos) | `fs`: `error` 36 · `warn` 2 · Default 1 — `state`: `error` 19 · `warn` 13 · `off` 5 · Default 2 — `scheduled_error`/`prompt`: `error` 37 — `deprecation`: `error` 37 · `warn` 1 — `process_net`: `error` 34 · `warn` 1 · `off` 1 · Default 3 | `state` ist in **20 von 39** nicht auf `error` |
| `isolated` | `file` 32 · `none` 7 (cmdlog, documentation, fileops, filetree, language, pickers, recommender) | |
| `guard_allow` nicht leer | 29 | `git` 13×, `nvim` 7×, `python3` + 8 Versionsnamen 3×, `curl` 4× … |

**Spec-Stile der 1.623 Spec-Dateien:** 965 `return function(H)` (22 Repos), 601 busted (13 Repos), 55 sonstige (spotlight 34 im
`M.run()`-Stil, filetree 18 Skripte, cmdlog/pickers je 1, lsp 1), 2 Skripte.

### 2.1 Sonderfälle

- **`lib.nvim`**: eigener Runner (`TESTS/run.lua`, `TESTS/harness.lua`), bewusst (Bootstrap-Zirkel). Die Dokumentation der
  Ausnahme in `lib.nvim/TESTS/README.md` fehlt weiter (Task `lib-harness-bootstrap`). `ci-verified` von lib.nvim steht auf `18d24b3`,
  `main` auf `67d9e89d` — die testing.nvim-CI (`lib-suite`) hat also zwei neuere Specs nie gesehen (§3.7).
- **`replacer.nvim`**: kein `.testing.lua`, kein `test.sh`, kein `minimal_init`; 15 Test-Skripte + 3 Helfer (4.505 Zeilen) laufen in der CI
  über einen **selbstgebauten Wrapper** (`TESTS/ci_guard.lua`: „Absturz → FAIL-Zeile + Exit 1") und eine eigene Dependency-Suche
  (`resolve_lib_nvim.lua`, `resolve_ui_nvim.lua`) — beides kann der Runner schon. `testing migrate` würde nur **4 der 11** in der CI
  gestarteten Skripte als Specs erkennen (§5, F-3).
- **`filetree.nvim`, `pickers.nvim`, `cmdlog.nvim`**: laufen als **Skript-Monolithe** (`dialect = "script"` bzw. eine einzige `_spec`-Datei,
  die sich selbst zählt). Für testing.nvim sind das 18 / 1 / 1 Fälle mit je **einer** Assertion (dem Exit-Code) — obwohl in den Skripten
  nach statischer Zählung etwa 2.500 / 1.200 / 300 Prüfaufrufe stehen. Es gibt dort keine Einzelfall-Auswahl (`--filter`), kein Retry,
  keinen Cache-Treffer pro Fall und kein Surface-Tracking (§3.4). Die Guards arbeiten nur teilweise: bei `filetree` kommt aus **keinem**
  Skript ein Guard-Protokoll an (die Skripte beenden den Editor selbst, die IR-Notiz sagt es), bei `pickers`/`cmdlog` laufen
  `scheduled_error`/`deprecation`, aber nicht `state`. Die Kommentare in den drei `.testing.lua` („testing.nvim installs no guard at all")
  stimmen damit nicht mehr; `pickers` hat obendrein `fs`/`state`/`deprecation` auf `warn` und `process_net` auf `off`.
- **`casedesk.nvim`, `my.nvim`** sind **privat**: ihre CI-Jobs starten nicht („recent account payments have failed or your spending limit
  needs to be increased", Job nach 2 s ohne Schritt). Dort gibt es zurzeit **keine** Matrix-Aussage; `ci-verified` kann nicht vorrücken.
- **`runtime-analysis.nvim`**: kein CI-Lauf zum aktuellen Commit.

## 3. Frage (a): Passt die Testabdeckung?

**Kurz:** Im Großen ja, im Einzelnen nicht überall — und nicht dort, wo es am meisten zählt. Die Zeilenabdeckung ist hoch (Median 85,4 %), und es gibt
keine Flotten-weite Logik-Wüste. Aber (1) die Lücken sitzen zu 45 % in Kernlogik und liegen auf wenigen Repos, (2) die **Einstiegspunkte** — `plugin/`,
Keymaps, `:Cmd` — werden fast nirgends durchlaufen, (3) die Struktur der Tests (eine Datei = ein Fall, drei Skript-Monolithe) verdeckt, *was* rot wäre,
und (4) rund jede fünfte Verhaltensänderung kommt ohne Teständerung. Die Zahlen im Einzelnen:

### 3.1 Zeilenabdeckung

Gemessen für **41 von 42 Repos** (nicht: `testing.nvim`, §3.2); Hook, Nenner und Grenzen stehen in §1 und §5.1.

| Kennzahl | Wert |
|---|---|
| ausführbare Zeilen (Code in `lua/ plugin/ after/ ftplugin/ autoload/`) | 226.345 |
| davon ausgeführt | 185.299 = **81,9 %** (flottenweit, zeilengewichtet) |
| je Repo: Minimum · Q1 · **Median** · Q3 · Maximum | 58,1 · 77,1 · **85,4** · 90,9 · 97,7 % |
| ≥ 85 % · ≥ 90 % | 22 · 12 Repos |
| unter 70 % | media 58,1, images 61,9, my 65,5, recommender 67,5, mdview 67,6, markdown 69,5, lib 69,99 |
| 70–85 % | debugging 72,6, gitsuite 74,7, rules 74,9, filetree 77,1, replacer 77,6, buffer-ctx 78,1, runtime-analysis 78,3, hover 80,2, open 81,0, sessions 83,9, language 84,2, lsp 84,4 |
| Dateien ohne einen einzigen Treffer | 356 von 3.205 (= 5.171 Zeilen) |

**Die Lücke liegt auf wenigen Repos, aber verteilt über viele Dateien.** Die zehn Repos mit den meisten offenen Zeilen (lib, filetree, documentation, markdown, casedesk, lsp, mdview, ui, images, gitsuite) halten 62 % aller nicht ausgeführten Zeilen; 17 Dateien mit
je ≥ 200 offenen Zeilen zusammen nur 12 % — es sind also **nicht ein paar große Dateien**: wer sie schließen will, muss viele mittlere
Module anfassen (Tabelle der 45 größten Einzeldateien: Anhang C).

**Mehr Test heißt nicht automatisch mehr Abdeckung.** Verhältnis Test-LOC zu Code-LOC korreliert mit der Abdeckung nur mit
r = 0,52; Assertions je Code-Zeile mit r = 0,16 (Pearson, 41 Repos). Der Teststil sagt ebenso wenig:
busted-artige Repos (≥ 5 Fälle je Datei) liegen im Mittel bei 84 %, die `h`-Repos mit einem Fall je Datei bei 82 %. Was die Abdeckung
bestimmt, ist, **ob ein Spec das Modul überhaupt erreicht**: Module, die ein Test beim Namen nennt, laufen zu 85 %; Module, die nur mittelbar
geladen werden, zu 57 %; Module, zu denen die statische Analyse keinen Weg findet, zu 59 %. (Das Proxy-Maß ist unscharf: es kennt nur direkte
`require`-Ketten, dynamische Ladewege — Dispatcher, Registries — sieht es nicht. Belastbar ist nur der Unterschied zwischen *direkt genannt* und *nur mittelbar geladen*.)

### 3.2 `lib.nvim`, `testing.nvim`, `ui.nvim` und `replacer.nvim`

- **`lib.nvim`**: 70,0 % (16.861 von 24.090 Zeilen in 508 Dateien; genau 69,99 %) — **knapp unter 70 %, mit den meisten offenen Zeilen der Flotte (7.229)**. 165 Dateien
  (1.749 Zeilen) laufen nie; kein Test nennt sie, z. B. `buf_win_tab/windows_utils.lua` (205 Zeilen), `strategies/lazy.lua`, `treesitter/parser_policy/init.lua`.
  Der Wert ist eine **untere Schranke**: `lib` hat einen eigenen Runner (`TESTS/run.lua`, bewusst, §2.1), der Hook hängt in seiner `minimal_init.lua`; unter dem Hook
  scheitern zusätzlich `strings_trim_spec` und `git_log_spec` (Laufzeit-Limits). Die Suite ist schon im Basislauf rot (drei Dateien): `harness_spec.lua:31` (F-1, dieselbe
  Ursache wie die testing.nvim-CI), `run_argv_spec.lua:366` (Windows, F-9) und `git_spec.lua:106` — letzteres ist ein **Artefakt dieses Audits** (der Klon hat die
  Push-URL abgeschaltet, `git.remote_url("origin")` liefert deshalb `nil`), kein Befund.
- **`testing.nvim`**: die eigene Suite (167 Dateien, 20.274 Assertions) läuft 771 s und ist der Prüfling des Audits; **keine Abdeckungszahl** (der Hook würde das Werkzeug
  messen, das ihn trägt). `testing conformance` bewertet es mit `pass`.
- **`ui.nvim`**: 89,2 % (13.323 von 14.930 Zeilen), ebenfalls eine **untere Schranke**: unter dem Hook gibt es 1 Fehlschlag, 3 Fehler und 25 Timeouts (Skalierungs-Specs,
  `slots_bar_spec`); im Basislauf ist nur `kit_drift_spec` rot (F-8).
- **`replacer.nvim`** ist nicht migriert. Gemessen wurde ein **migrierter Klon** (`testing migrate apply`, alle 14 Skripte als Specs): 14 von 14 grün,
  77,6 % — in der Tabelle mit ¹ markiert. Die echte CI des Repos ist rot (§3.7).

### 3.3 Wo die offenen Zeilen sitzen

Nach der Rolle der Datei (Pfadheuristik, `gapclass.js`):

| Klasse der Datei | Dateien | ausführbare Zeilen | Abd. % | nicht ausgeführt | Anteil an allen offenen % |
| --- | ---: | ---: | ---: | ---: | ---: |
| Kernlogik (alles übrige) | 1760 | 118.602 | 84,6 | 18.283 | 44,5 |
| UI: Fenster, Dashboards, Menüs, Previews | 484 | 44.117 | 80,4 | 8.654 | 21,1 |
| Kommandoschicht (:Cmd, Dispatcher, CLI) | 201 | 21.561 | 72,4 | 5.959 | 14,5 |
| Adapter / Integrationen / Backends | 379 | 15.004 | 78,7 | 3.198 | 7,8 |
| health | 47 | 6.097 | 70,4 | 1.804 | 4,4 |
| Keymaps / Autocmds (bindings) | 147 | 7.753 | 80,9 | 1.478 | 3,6 |
| Einstieg (init, plugin/) | 69 | 5.148 | 77,0 | 1.183 | 2,9 |
| Konfiguration | 118 | 8.063 | 94,0 | 487 | 1,2 |

- **Kernlogik** macht mit 45 % den größten Teil der Lücke aus (18.283 Zeilen) bei einer Abdeckung von 85 % — ein hoher Durchschnitt
  verdeckt hier einzelne Module: `markdown/core/table_wrap.lua` (306 ausführbare Zeilen, 6 %) ist Logik ohne jedes Netz.
- **UI** (Fenster, Dashboards, Menüs, Previews) 21 %, **Kommandoschicht** (`:Cmd`, Dispatcher, CLI) 15 %, **Health** 4 %.
  Der Abdeckungsgrad nimmt zu den Rändern der Anwendung hin ab:

| Modulrolle | Repos | Dateien | ausführbare Zeilen | Abd. % |
| --- | ---: | ---: | ---: | ---: |
| plugin-entry | 26 | 30 | 120 | 4,2 |
| health | 41 | 46 | 6.094 | 70,4 |
| bindings.usrcmds | 36 | 108 | 11.370 | 75,8 |
| bindings.autocmds | 35 | 47 | 1.775 | 77,2 |
| init | 41 | 41 | 5.032 | 78,7 |
| integrations | 17 | 323 | 12.353 | 79,3 |
| bindings.other | 27 | 84 | 5.310 | 80,9 |
| ui | 37 | 428 | 39.906 | 81,1 |
| core | 40 | 1924 | 132.783 | 82,8 |
| bindings.keymaps | 36 | 38 | 2.823 | 86,6 |
| config | 41 | 136 | 8.779 | 93,8 |

  (Konfiguration 94 %, Keymaps 87 %, Kern 83 % — aber `health` 70 %, `:Cmd`-Verdrahtung 76 %, Autocmd-Verdrahtung 77 %, UI 81 % und die
  Einstiegsdateien unter `plugin/` bei **4 %**.) Die `plugin/`-Dateien sind klein (30 Dateien in 26 Repos, 120 Zeilen), aber sie sind das, was ein Nutzer als Erstes
  ausführt: Nur im migrierten `replacer`-Klon läuft ein Spec durch sie (5 Zeilen); in den übrigen 25 Repos läuft **keine einzige** `plugin/`-Zeile.
- Von den 29 Dateien mit ≥ 150 offenen Zeilen (`gapinfo.js`, Heuristik nach Aufrufen im Quelltext) sind 24 reine Logik, 3 Prozess-/Werkzeug-Code
  (`replacer/rg.lua`, `filetree/.../trash/platform.lua`, `documentation/editor/health.lua`), 1 Netz und 1 UI (`tasks_nvim/ui/cmd.lua`) — **die größten Lücken sind keine „schwer testbaren Fenster", sondern
  Kommando-Handler und Parser** (`markdown/commands/mdtable.lua`, `casedesk/ui/lifecycle.lua`, `filetree/commands.lua`, `images/init.lua`).
- **Zwei Ausnahmen, die keine Lücke sind:** `debugging/views/debug_helper.lua` (166 Zeilen, 0 %) ist nach der eigenen Doku des Plugins toter Code;
  `lsp/core/env_links_server.lua` (im ersten Lauf 14 %) war ein Mess-Artefakt — der Spec ist da, riss aber mit Hook sein Limit; nach der Wiederholung mit großen
  Limits (§1) sind es 98 %.

### 3.4 Struktur der Tests: Granularität, stilles Auslassen, Bindungen

**Granularität.** 12.960 Fälle in 1.637 Spec-Dateien; **1.049 Dateien (64 %) enthalten genau einen Fall** — der `h`-Stil (`return function(H)`) legt in einer
Datei viele Prüfungen ab (379.432 Assertions insgesamt). Das ist an sich kein Fehler, hat aber Folgen: Ein Fall *ist* eine Datei — Fallzahlen, `--filter` und Retry arbeiten auf der Datei, ein roter Fall nennt
die erste fehlgeschlagene Prüfung, nicht alle. Schärfer ist es bei den **drei Skript-Monolithen**: `filetree` (18 Fälle für
etwa 2.500 Prüfaufrufe), `pickers` (1 Fall für 1.200), `cmdlog` (1 für 300) liefern dem Runner nur den Exit-Code — **eine Assertion je Datei** (E-11 behebt das
ohne Spec-Änderung). Dazu kommen 14 Fälle ohne eine Assertion (casedesk 5, github_stats 4, lsp 2, mdview 2, ui 1).

**Stilles Auslassen.** Specs, die einen Block nur ausführen, wenn eine Fähigkeit da ist (`if has_parser("javascript") then …`), bleiben grün, wenn sie
fehlt: Auf dieser Maschine fehlen deshalb 38 ausführbare Zeilen in `cascade/strings/init.lua`; Parser-Gates gibt es in 8 Repos (`documentation` allein 45), Werkzeug-Gates in 17 (41 Stellen), `win32`-Gates in 29 (291 Stellen). Nur drei Repos haben einen eigenen „fehlt es, schlage fehl"-Schalter (E-07). **Die Abdeckungszahlen dieses Berichts
gelten für diese Maschine mit den Parsern von heute.**

**Bindungen (Binding-Coverage, `surface.track`).** Das ist die Antwort auf „wird die Bedienoberfläche getestet?" — und sie fällt am schlechtesten aus:

| Art | getroffen | von | Quote |
|---|---:|---:|---:|
| Keymaps (`binding`) | 14 | 134 | 10 % |
| Commands | 288 | 906 | 32 % |
| Autocmds | 78 | 144 | 54 % |
| **alle** | 380 | 1.184 | **32 %** |

Gerechnet über die 35 Repos, deren Standard-`setup()` überhaupt etwas registriert; **leer** (nichts zu messen) sind `filetree`, `lib`, `pickers`,
`ui`. **Sieben Repos haben 0 %** (dap, documentation, images, mdview, recommender, rules, tasks): ihre Tests rufen Funktionen auf, nie die
Bindung. Bei Keymaps ist das die Regel (nennenswerte Treffer nur `gopath` 10 von 11 und `terminal` 2 von 8; `insights` 1 von 3, `diff` 1 von 1). Die Zeilenabdeckung der Handler kann trotzdem hoch sein —
die Verdrahtung (Name, Argumente, Completion, `desc`) ist das, was ungeprüft bleibt; K3/K4/K5/K12 decken davon nur den Rahmen. Nicht im Surface-Lauf auswertbar:
`ai` hatte dort einen zusätzlichen roten Fall (`state`-Guard, Tastenbelegung `<Tab>` im Insert-Modus), im Basislauf war er grün — Wechselwirkung des Trackings
mit dem Guard oder Flakiness; nicht weiter verfolgt.

### 3.5 Hygiene: Guards und Konformität

- **Guards:** `fs` steht in 36 von 39 Repos auf `error`, `scheduled_error`, `prompt` und `deprecation` in je 37, `process_net` in 34. Der **`state`-Guard** — der Wächter
  gegen Specs, die Zustand hinterlassen — steht nur in 19 auf `error`; 13 `warn`, 5 `off`, 2 Default. Im Messlauf meldete er in **15 Repos** Funde
  (lsp 3.198, casedesk 3.078, sandbox 1.134, gitsuite 924, mdview 915, terminal 814, ai 627, github_stats 575): auf `warn` sind sie sichtbar, aber folgenlos.
  `guard_allow` ist in 29 Repos nicht leer (`git` 13×, `nvim` 7×, die `python3.x`-Liste 3×).
- **Konformität (K1–K15, report-only):** Ergebnis je Repo: **1 pass** (testing.nvim selbst), 29 warn, 9 fail, 1 error. Am 08.10. standen 27 / 9 / 3 (warn / fail / error) und kein pass; die Triage ist nicht vorangekommen (F-5). **K15 warnt in 38 von 40 Repos wegen einer einzigen Zeile** (`vim` in `diagnostics.globals` der
  `.luarc.json`). Ursachen der 9 `fail`-Repos (10 Befunde): K6 (Health meldet fehlende Dependencies, 7×), K9 (`my` startet `pwsh` beim Laden), K14 (zwei Befehle undokumentiert).

| Check | Prüft | pass | warn | fail | n/a | error |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| K1 | `every module can be required on its own` | 26 | 14 | 0 | 0 | 0 |
| K2 | `setup() twice is idempotent` | 36 | 4 | 0 | 0 | 0 |
| K3 | `setup({ keymaps = false }) registers no keymaps` | 18 | 0 | 0 | 22 | 0 |
| K4 | `every keymap has a desc` | 18 | 0 | 0 | 22 | 0 |
| K5 | `every user command has completion` | 36 | 3 | 0 | 1 | 0 |
| K6 | `:checkhealth <plugin> runs without an error` | 24 | 8 | 7 | 0 | 1 |
| K7 | `every soft dependency has a health check` | 24 | 16 | 0 | 0 | 0 |
| K8 | `no vim.deprecate message and no scheduled error on load and setup` | 40 | 0 | 0 | 0 | 0 |
| K9 | `no write outside tmp, no process, no network on load and setup` | 39 | 0 | 1 | 0 | 0 |
| K10 | `require + setup() within the load budget` | 35 | 5 | 0 | 0 | 0 |
| K11 | `no new global` | 40 | 0 | 0 | 0 | 0 |
| K12 | `keymap actions have a command counterpart` | 19 | 3 | 0 | 18 | 0 |
| K13 | `no fragile keys, no command-name prefix collisions` | 28 | 11 | 0 | 1 | 0 |
| K14 | `binding documentation matches the registry` | 32 | 6 | 2 | 0 | 0 |
| K15 | `static gate rules (NEW-36/45/48/49, REL-16 and the file rules)` | 2 | 38 | 0 | 0 | 0 |

### 3.6 Pflege: kommt zu jeder Verhaltensänderung ein Test?

Gezählt werden `feat`/`fix`/`perf`/`refactor`-Commits, die Code ändern (`churn.js`). In den **letzten 30 Tagen** haben **448 von 2.436 (18,4 %)** keine
Teständerung; Median je Repo 17,5 %, drittes Quartil 23,2 %. Über die gesamte Historie liegt der Median bei 48,3 % — es wird also **besser**, ist
aber nicht gut. **Über 30 %:** my 43 % (19/44), images 41 % (14/34), mdview 37 % (16/43), color_my_ascii 33 % (7/21), lib 32 % (98/305), markdown 30 % (14/46). Das sind zu großen Teilen dieselben Repos, die unter oder knapp um 70 % Abdeckung liegen (my, images, mdview, markdown, lib): Dort
wächst die Lücke weiter. Hooks, die das verhindern könnten, gibt es nur als Rezept (`docs/HOOKS.md`), installiert sind sie in **0** Repos.

### 3.7 Betrieb: Läufe und CI

- **Lokaler Lauf** (Windows, `scripts/test.sh`): 36 grün (darunter `testing.nvim` und der migrierte `replacer`-Klon), 3 grün mit Skip (fileops, hover, lsp), **3 rot** (gitsuite, lib, ui). 12.960 Fälle,
  379.432 Assertions.
  - `gitsuite`: in allen drei Läufen (Basis, Abdeckung, Surface) dieselben **zwei Timeouts** bei echten `git merge`-Konflikten (`conflict_git_spec.lua`, „zdiff3" und „diff3").
  - `ui`: `kit_drift_spec` (`message_log.lua` weicht von lib.nvims Kopie ab, F-8).
  - `lib`: siehe §3.2.
- **CI heute** (`scripts/ci_status.sh`, 3 Systeme): **35 von 43 grün.** Nicht grün:

| Repo | Stand | Ursache |
|---|---|---|
| `testing.nvim` | rot (alle 3) seit 09.10. 19:39 UTC | F-1: `lib.nvim`s `harness_spec.lua` vs. `h`-Wrapper |
| `ui.nvim` | rot (alle 3) | F-8: Kit-Drift |
| `replacer.nvim` | rot (alle 3) seit 08.10. | F-12: zwei neue Fälle scheitern auf Ubuntu/macOS, Windows Exit 127 |
| `lib.nvim` | rot auf Ubuntu und macOS, Windows grün | `git_run_spec.lua:449` (git-Version), F-9 |
| `casedesk.nvim`, `my.nvim` | rot (alle 3) | privat, Billing: Jobs starten nicht; dazu luacheck/stylua/docs rot |
| `runtime-analysis.nvim` | kein Lauf zum aktuellen Commit | – |

  (`plenary.nvim` ist Upstream und nicht Teil der Zählung.)
- Die Zeit, die der Hook kostet, steht in §1; **69 Fälle in 8 Repos** sind nur mit Hook rot.

### 3.8 Gesamtbild je Repo

Fünf Ampeln, jede aus einer Zahl berechnet (keine Einzelfall-Bewertung):

| Spalte | grün | gelb | rot |
|---|---|---|---|
| **Abdeckung** | Zeilenabdeckung ≥ 85 % | ≥ 70 % | darunter; „·" = nicht gemessen |
| **Granularität** | Median ≥ 5 Fälle je Datei | ≥ 3 Assertions je Fall | sonst (Skript-Monolith) |
| **Hygiene** | `state` = `error` und `fs` = `error` | alles dazwischen | `state` = `off` oder undurchsichtiger Lauf |
| **Pflege** | ≤ 15 % der Verhaltens-Commits ohne Test (30 Tage) | ≤ 30 % | darüber |
| **Betrieb** | lokal grün und CI auf 3 Systemen grün | CI unbekannt, oder privates Repo mit Billing-Sperre | lokal rot oder CI rot |

| Plugin | Abdeckung | Granularität | Hygiene | Pflege | Betrieb |
| --- | :---: | :---: | :---: | :---: | :---: |
| lib | 🔴 | 🟡 | 🟡 | 🔴 | 🔴 |
| replacer ¹ | 🟡 | 🔴 | 🔴 | 🟡 | 🔴 |
| my | 🔴 | 🟢 | 🔴 | 🔴 | 🟡 |
| images | 🔴 | 🟡 | 🟢 | 🔴 | 🟢 |
| recommender | 🔴 | 🟡 | 🟡 | 🟡 | 🟢 |
| mdview | 🔴 | 🟢 | 🟡 | 🔴 | 🟢 |
| markdown | 🔴 | 🟡 | 🟢 | 🔴 | 🟢 |
| gitsuite | 🟡 | 🟢 | 🟡 | 🟡 | 🔴 |
| filetree | 🟡 | 🔴 | 🔴 | 🟢 | 🟢 |
| pickers | 🟢 | 🔴 | 🔴 | 🟡 | 🟢 |
| media | 🔴 | 🟡 | 🟢 | 🟡 | 🟢 |
| cmdlog | 🟢 | 🔴 | 🔴 | 🟢 | 🟢 |
| ui | 🟢 | 🟢 | 🔴 | 🟢 | 🔴 |
| debugging | 🟡 | 🟡 | 🟢 | 🟡 | 🟢 |
| buffer-ctx | 🟡 | 🟡 | 🟢 | 🟡 | 🟢 |
| runtime-analysis | 🟡 | 🟡 | 🟢 | 🟢 | 🟡 |
| hover | 🟡 | 🟢 | 🔴 | 🟢 | 🟢 |
| sessions | 🟡 | 🟡 | 🟢 | 🟡 | 🟢 |
| language | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 |
| documentation | 🟢 | 🟡 | 🟡 | 🟡 | 🟢 |
| color_my_ascii | 🟢 | 🟡 | 🟢 | 🔴 | 🟢 |
| fileops | 🟢 | 🟡 | 🟡 | 🟡 | 🟢 |
| dap | 🟢 | 🟢 | 🔴 | 🟡 | 🟢 |
| rules | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 |
| open | 🟡 | 🟡 | 🟢 | 🟢 | 🟢 |
| lsp | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 |
| casedesk | 🟢 | 🟢 | 🟡 | 🟢 | 🟡 |
| insights | 🟢 | 🟡 | 🟢 | 🟡 | 🟢 |
| reposcope | 🟢 | 🟡 | 🟢 | 🟡 | 🟢 |
| gopath | 🟢 | 🟡 | 🟢 | 🟡 | 🟢 |
| tasks | 🟢 | 🟡 | 🟢 | 🟡 | 🟢 |
| emojis | 🟢 | 🟡 | 🟡 | 🟢 | 🟢 |
| pdfport | 🟢 | 🟡 | 🟢 | 🟡 | 🟢 |
| diff | 🟢 | 🟡 | 🟢 | 🟡 | 🟢 |
| data | 🟢 | 🟢 | 🔴 | 🟢 | 🟢 |
| sandbox | 🟢 | 🟢 | 🟡 | 🟢 | 🟢 |
| cascade | 🟢 | 🟡 | 🟢 | 🟢 | 🟢 |
| spotlight | 🟢 | 🟡 | 🟢 | 🟢 | 🟢 |
| terminal | 🟢 | 🟢 | 🟡 | 🟢 | 🟢 |
| github_stats | 🟢 | 🟢 | 🟡 | 🟢 | 🟢 |
| ai | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |

(Sortiert nach der Summe der Punkte — rot 2, gelb 1 —, bei Gleichstand nach Abdeckung. `testing.nvim` ist als Prüfling nicht aufgeführt.)

**Antwort auf (a):** Die Abdeckung **passt als Niveau** (Median 85,4 %, 22 von 41 Repos ≥ 85 %), **nicht als Verteilung**. Fünf Handgriffe bringen am meisten:
die sieben Repos unter 70 % (und dort die Pflege-Quote), die Kernlogik-Lücken in den zehn Repos mit den meisten offenen Zeilen, die Bindungen (Keymaps 10 %), den
`state`-Guard auf `error`, und die drei Skript-Monolithe sichtbar machen. Das konkrete Vorgehen steht in §7.

## 4. Frage (b): Was wird in vielen Plugins von Hand nachgebaut — und was lohnt sich als Modul?

### 4.1 Der Befund in einem Satz

testing.nvim ist ein Runner geworden, aber **die Flotte baut an ihren Specs weiter alles selbst**: kein einziges der 41 Repos ruft eine
testing.nvim-Funktion aus einem Spec auf, während in den Repos rund **22 KLOC Setup-Kopien** (CI, `test.sh`, `minimal_init`, Harness, Linter-
Konfiguration), **806 Helfer-Definitionen (6,8 KLOC)** im Testcode und **≈ 300 Inline-Stubs** liegen — und die Dialekte `a/b/c` von testing.nvim
bilden einzelne dieser Helfer nachträglich als Shims nach, statt sie als API anzubieten.

| Schicht | Volumen in der Flotte | Kopien | davon gleich |
|---|---:|---:|---|
| CI-Workflow (`ci.yml`, bei color_my_ascii `lint.yml`) | 5.915 Zeilen | 42 | 1 (Medoid); 41 weichen um 15–305 Zeilen ab |
| `scripts/test.sh` | 4.650 | 40 | 6 gleich; 24 ≤ 6 Zeilen; 10 weichen um 9–146 ab |
| `TESTS/minimal_init.lua` | 3.580 | 40 | 8 gleich; 11 ≤ 6; 21 weichen um 7–128 ab |
| `TESTS/harness.lua` (+ gopaths `scripts/ci/harness.lua`) | 2.883 | 23 | 1 Paar byte-gleich (insights/language), sonst 22 Varianten |
| `TESTS/run.lua` (Reihenfolge-Manifeste, inkl. lib) | 1.441 | 10 | – |
| `.testing.lua` | 1.754 | 40 | Kommentartext identisch, Werte je Repo |
| `.luacheckrc`, `.luarc.json`, `.gitattributes`, `stylua.toml` | 966 / 614 / 674 / 327 | 42 je Datei | `.luacheckrc`: 41 von 42 weichen um 8–55 Zeilen ab |
| **Summe Setup-Boilerplate (ohne `.gitignore`)** | **≈ 22.800 Zeilen** in den 42 Repos | | |
| Helfer im Testcode (8 Familien, §4.3 E-06) | 806 Definitionen / 6.819 LOC | 19–37 Repos je Familie | meist < 2 Repos mit identischem Body |
| Contract-Specs gleichen Themas (`config_spec` ×30, `health_spec` ×24, `usrcmds_help_spec` ×24, `bindings_spec` ×13, `usrcmds_spec`, `keymaps_spec`, `registry_spec` ×10, `init_spec` ×14) | ≈ 23 KLOC | – | Text nur 7–29 % gleich (unabhängig geschrieben, gleiches Thema) |
| Config-Validierung im Plugin-Code (`config/init.lua`) | 8.886 LOC | 40 | 27 mit eigener `issues`-Maschine, 25 mit Levenshtein-„did you mean" |

### 4.2 Kandidatenliste

Priorität: **P1** = hoher Nutzen bei überschaubarem Aufwand oder blockiert andere Punkte, **P2** = danach, **P3** = später/optional.
Aufwand grob: S ≤ 1 Tag, M 2–4 Tage, L 5–10 Tage (Schätzung, ohne Rollout in die Repos).

| ID | Mechanismus | Beleg (Repos · Stellen · Zeilen) | Ziel | Aufw. | Prio |
|---|---|---|---|:-:|:-:|
| **E-01** | wiederverwendbare CI (Reusable Workflow + Composite Action) | 42 Kopien · 5.915 Z. · 41 von 42 weichen ab · nvim `stable` 36×, Template pinnt `v0.12.2` 0× · `actions/cache` 1× (mdview) | testing.nvim | M (+Rollout L) | **P1** |
| **E-02** | Dependency-Auflösung nur im Runner; `test.sh` und `minimal_init` schrumpfen; `optional_deps` | 4-Stufen-Suche in sh (40×), Lua-minit (40×, `valid`/`env_name` 35–36×) **und** Runner · optionale Deps in 5 Repos unter 3 Namen · Env-Namen `LIB_NVIM_PATH` 7 / `LIB_NVIM_DIR` 6 / `REPOS_DIR` 11 | testing.nvim | M | **P1** |
| **E-03** | `testing sync`: Drift der Boilerplate erkennen/angleichen | 42 Kopien je Datei · Scaffold überschreibt nie (`skipped`) → kein Rückweg | testing.nvim | M | **P1** |
| **E-06** | **`testing.kit`**: der Standard-`H` (Fixtures, Puffer, Patch/Restore, Module, Capture, Fakes, Warten) | 806 Defs · 6.819 LOC · 8 Familien · 19–37 Repos je Familie · `scratch` mit ≥ 5 Argumentreihenfolgen, `capture_notify` 11 Bodies | testing.nvim | L | **P1** |
| **E-11** | Skript-Dialekt: aus `ok   <Name>`/`FAIL …`-Zeilen echte Fälle machen | filetree 2.545 / pickers 1.179 / cmdlog 305 Prüfaufrufe = je 1 Fall | testing.nvim | S–M | **P1** |
| **E-13** | Zeilenabdeckung (M7) vorziehen, Prototyp liegt vor | 0 Repos können ihre Zeilenabdeckung nennen · M7 „blocked, Prio 3, verzichtbar" | testing.nvim | M | **P1** |
| E-04 | `.testing.lua`: Presets, `allow_exec_patterns`, Fixture-Verzeichnis automatisch erlaubt | 29/39 mit `guard_allow` · `python3.9…3.15` einzeln in 3 Repos · reposcope 8× `TESTS/.fixture-*` · `git` 13×, `nvim` 7× | testing.nvim | S–M | P2 |
| E-05 | `order`/Schichten in `.testing.lua` statt `run.lua`-Manifest | 10 Manifeste · 1.441 Z. | testing.nvim | S | P2 |
| E-07 | Capability-Gate `kit.need{…}` mit CI-Modus „fehlt es, schlägt es fehl" | Parser-Gates in 8 Repos (documentation 45×), eigene REQUIRE-Schalter in 3 Repos, Tool-Gates in 17 Repos (41 Stellen), `win32`-Gates in 29 Repos (291 Stellen) | testing.nvim | S–M | P2 |
| E-08 | plattformneutrale Testprogramme und Prozess-Recorder (`kit.proc`, `kit.fake`) | `vim.system/…` überschrieben in 27 Repos (245 Stellen) · terminal `jobs.lua`, sandbox `fake_run_argv`, pdfport `spawn_recorder`, lib `run_argv_spec` (`nvim -l` als Fremdprogramm) | testing.nvim | M | P2 |
| E-10 | Vertrags-Checks K16+ aus den Registries: Config-Vertrag, `usrcmd`-Hilfe, Health | `config_spec` 30× (5,7 KLOC) · `health_spec` 24× · `usrcmds_help_spec` 24× | testing.nvim (Check) + lib.nvim (Laufzeit, s. u.) | M–L | P2 |
| E-12 | `migrate`/`doctor`: `ci_guard`-Wrapper erkennen, `deps` aus Health-Prüfung ableiten | replacer 4 von 11 Skripten erkannt · K6-Fehler: ai/insights/spotlight brauchen `ui.nvim`, deklarieren es nicht | testing.nvim | S | P2 |
| E-09 | `kit.perf`: CPU-Zeit-Messung und Skalierungs-Spec | 15 Repos mit „stays fast/linear/quadratic"-Specs, casedesk `cpu_time.lua`, 15 Repos messen mit `hrtime`/`os.clock`/`getrusage` | testing.nvim (neben `testing budget`) | S | P3 |
| E-14 | CI/Scaffold: `--jobs auto`, `--cached` und die CI-Cache-Rezeptur tatsächlich einsetzen | `jobs` in 0 von 39 Repos, `--cached` in 0 anderen CIs | testing.nvim (Template) | S | P3 |
| E-15 | `dialect = "testing"` implementieren **oder** aus dem Schema nehmen; README-Stand korrigieren | Name ist im Schema reserviert, aber ohne Modul; README „has not happened" | testing.nvim | S | P3 |
| E-16 | gemeinsames Config-Schema-Modul für Plugins (`lib.nvim.config.schema`) | 40 Config-Module · 8.886 LOC · 27 Eigenbauten der `issues`-Maschine | **lib.nvim** (Laufzeit!) | L | P3 (eigene Entscheidung) |

### 4.3 Die Kandidaten im Einzelnen

#### E-06 — `testing.kit`: der Standard-`H`

**Befund.** 23 Harness-Dateien (22 in `TESTS/`, eine in `gopath/scripts/ci/`) definieren dieselben Dinge mit leicht verschiedener
Bedeutung; die 13 busted-Repos haben gar keinen Harness und bauen dieselben Helfer als `local function` in die einzelnen Specs.
Die Verteilung (nur Namen, die in ≥ 2 Harnessen stehen):

| `H.`-Funktion | Harness-Dateien | Varianten (verschiedene Bodies) |
|---|---:|---:|
| `eq` | 23 | **7** (`%q` vs. `vim.inspect`, `tostring`, strikt `==` vs. deep-equal) |
| `ok` | 22 | 5 |
| `falsy` · `scratch` | je 10 | 2 · **5** |
| `contains` · `tmpdir` | 8 · 6 | 3 · **5** |
| `fixture` · `match` · `read` · `write` | 5 · 5 · 5 · 5 | 3 · 2 · 2 · 3 |
| `excludes` · `tmpfile` · `with_modules` | 4 · 4 · 4 | 1 · 2 · **4** |
| `eq_list` · `index_of` · `notify` · `read_lines` | 3 je | 2 · 3 · 3 · 1 |

Dazu die Familien im ganzen Testcode (Definitionen · LOC · Repos), ohne Inline-Stubs:

| Familie | Definitionen | LOC | Repos | verschiedene Bodies | häufigste Namen |
| --- | ---: | ---: | ---: | ---: | --- |
| module substitution | 144 | 1.973 | 22 | 135 | freshx82 reloadx52 with_modulesx4 unloadx3 reload_prefixx1 without_modulesx1 |
| assertions | 204 | 1.406 | 37 | 95 | checkx61 eqx36 hasx24 okx23 falsyx11 containsx9 |
| fixtures (files, dirs) | 204 | 1.401 | 34 | 141 | writex72 write_filex20 tmpdirx17 lines_ofx14 fixturex14 readx13 |
| capture / recorders | 80 | 746 | 27 | 61 | recordx21 saidx16 capture_notifyx16 noticesx7 recorderx6 notifiedx4 |
| patch / restore | 58 | 575 | 23 | 50 | stubx20 restorex20 with_stubsx7 with_fieldx2 with_stdpath_configx2 snapshot_mapsx1 |
| buffers, cursor | 47 | 304 | 23 | 36 | scratchx19 line_ofx10 make_bufx5 set_linesx3 line_atx2 get_linesx2 |
| waiting | 59 | 297 | 19 | 46 | wait_forx22 flushx16 settlex11 awaitx6 waitx3 wait_untilx1 |
| fake process / platform | 10 | 117 | 4 | 10 | is_windowsx1 fake_systemx1 fake_platformx1 fake_backendx1 fake_producerx1 sleeperx1 |

Inline-Stubs (`vim.x = function …`): 298 Stellen in 29 Repos.

**Warum die Varianten ein Problem sind** (alles im Quelltext belegt):

- `scratch` heißt in 15 Repos gleich, hat aber (mindestens) fünf Signaturen: `scratch(ft)` (cascade, diff, emojis, markdown), `scratch(name, ft)`
  (buffer-ctx, debugging), `scratch(lines, ft)` (images, open), `scratch(ft, lines)` (color_my_ascii), `scratch(lang, lines)` (ui, lokal).
  testing.nvims Dialekte `b` und `c` bilden davon nur **zwei** nach — und haben dafür hybride Überladungen in `harness_c.lua`
  (`scratch(lines?, ft?)` akzeptiert zusätzlich die Dialekt-B-Form `scratch(ft)`).
- `tmpdir` hat **vier Verträge**: gibt einen Pfad zurück und merkt sich ihn zum Aufräumen (lib `git_checkout_spec.lua:14`, gitsuite), nimmt
  einen Callback und löscht danach (images/open `harness.lua:54`), löst per `fs_realpath` auf (fileops, gopath — gegen macOS `/private/var`,
  das gopath im Kommentar ausführlich begründet), oder gibt nur `:p` zurück (diff). Ein Spec, der von einem Repo ins andere wandert, ändert
  still seine Semantik.
- `capture_notify` (16 Definitionen, 11 Bodies, 8 Repos) unterscheidet sich in Dingen, die Ergebnisse verändern: behält es `level`? ruft es
  `vim.wait(20/30)` auf, damit geplante Notifies ankommen (data)? setzt es `vim.notify` zurück **oder** das Modul `lib.nvim.notify`
  (lsp, gibt `said, restore` zurück)? re-raist es mit `error(err, 0)` oder mit `assert(ok, err)` (filetree; das stellt eine Position
  voran)? Der Test, der „Meldung erschien" prüft, ist damit je nach Variante mal strenger, mal laxer.
- `with_modules` gibt es in 4 Varianten (gopath, spotlight, pdfport, color_my_ascii): mit/ohne `unload`, mit „Modul fehlt"-Simulation über
  `package.preload` (gopath `false`, spotlight `without_modules`, pdfport `H.UNLOAD`), mit/ohne Wiederherstellen von `preload`.
  `fresh` (82 Definitionen) und `reload` (52) sind die Ein-Zeiler-Fassungen derselben Idee.
- **Der Auto-Restore ist mindestens fünffach nachgebaut**: lib `H.with_patched` und `H.with_stdpath_config` (der Kommentar dort: „three copies of
  one small helper is exactly the kind of thing that only takes one edit to the wrong copy to break"), gopath `H.with_field`, gitsuite
  `TESTS/gitsuite/spec_guard.lua` (`G.install({ {vim.ui,"select"}, … })` + `before_each/after_each` — im Kern das, was der State-Guard von
  testing.nvim auf Framework-Ebene tut), ai `snapshot_maps/restore_maps/isolate_install`, terminal `env.isolate()`. testing.nvim hat den
  robusteren Baustein schon: `testing.guard.patch` (`Patcher`: Rückbau in umgekehrter Reihenfolge, erkennt „jemand hat über uns gewrappt" und
  meldet es, statt still zu überschreiben, lässt lazy `vim.fn.*`-Slots wieder lazy). Die Spec-Varianten setzen schlicht `tbl[key] = saved`.

**Vorschlag (Skizze, keine fertige API).** Ein Modul `testing.kit`, das ein Spec per `require` bekommt und das der Dialekt `h` **automatisch als
`H` anbietet, wenn das Projekt keine `TESTS/harness.lua` hat**; hat es eine, bleibt sie maßgeblich und kann `return require("testing.kit").extend({ … })`
sein (nur die projektspezifischen Teile bleiben: `fake_backend`, `config_sandbox` …).

```lua
local K = require("testing.kit")

-- Dateien: alles kanonisch (fs_realpath, Vorwärtsstriche), Aufräumen am Fallende, auch bei Fehlern
local dir  = K.tmp.dir()
local root = K.tmp.tree({ ["lua/a/init.lua"] = "return {}", ["README.md"] = { "# x" } })
K.tmp.write(path, content)            -- legt Elternverzeichnisse an; string | string[]
K.tmp.read(path)  /  K.tmp.lines(path) -- CRLF-fest

-- Puffer (Tabellenform; die fünf alten Positionsformen laufen als Kompatibilität weiter)
local buf = K.buf.scratch({ lines = { "x" }, ft = "lua", name = "a.lua", cursor = { 1, "x" } })

-- Ersetzen und Zurücksetzen über testing.guard.patch (Fallende, Fehler, Abbruch)
K.patch.set(vim, "notify", fn)        K.patch.with(tbl, key, value, function() … end)
K.env.set({ TMUX = false })           K.cwd.with(dir, fn)

-- Module
K.mod.with({ ["lib.nvim.notify"] = fake }, fn, { unload = { "x.y" } })
K.mod.missing({ "ui.kit" }, fn)       -- require schlägt fehl wie bei fehlendem Plugin
K.mod.fresh("x.y")

-- Mitschneiden und Fälschen
local rec = K.capture.notify(fn, { flush = true })     -- { {msg=, level=} }
K.capture.ui_select(choice, fn)  K.capture.health(fn)
K.fake.system({ ["git rev-parse"] = { code = 0, stdout = "x\n" } }, fn)   -- rec.calls
K.fake.executables({ git = true, rg = false }, fn)  K.fake.platform("windows", fn)
K.proc.nvim_script("os.exit(3)")      -- Fremdprogramm, das es auf jedem OS gibt: nvim selbst

-- Warten, Fähigkeiten, Laufzeit
K.wait.until_(function() return done end, { timeout = 2000 })
K.need({ exe = { "git" }, parser = { "javascript" } })   -- skip mit Grund; TESTING_REQUIRE=… macht es zum Fehler (E-07)
K.perf.cpu(fn)  K.perf.linear(fn, { 1e3, 1e4, 1e5 })
```

**Zielort und die lib.nvim-Frage.** Vier Gründe sprechen für **testing.nvim** als Heimat: Es ist das erklärte Ziel („Standard-Harness der
Flotte", `fleet-standard-harness-goal`), es hat `testing.guard.patch` und die Dialekt-Integration, und testing-only-Code gehört nicht in die
Laufzeit-Namespace von lib.nvim. **Ausnahme/Bedingung:** `lib.nvim` darf wegen des Bootstrap-Zirkels (Entscheidung A) nichts davon in
seinen Kern-Specs benutzen — es behält `TESTS/harness.lua` (der Kit baut deshalb nur auf `vim.*`/`uv`, nicht auf lib-Modulen, damit er
später doch auch dort laufen könnte). Was **auch zur Laufzeit** gebraucht wird (kanonisches Temp-Verzeichnis: `tempname()` im Laufzeitcode
von 19 Repos / 74 Stellen, `fs_realpath` in 13 Repos / 68 Stellen), gehört als Primitive nach **lib.nvim** (`fs`), der Kit ruft es dann auf.

**Migrationsweg ohne Bruch.** (1) Kit bauen und mit den bestehenden Dialekt-Shims `a/b/c` gegenprüfen (ihre Specs bleiben die Konformitäts-Suite
des Kits). (2) Piloten: ein `h`-Repo mit kleinem Harness (`runtime-analysis` 48 Zeilen), ein busted-Repo (`rules`). (3) `testing migrate`
bekommt einen Schritt, der lokale Helfer **mit identischem Body** durch Kit-Aufrufe ersetzt (die Body-Hashes aus der Inventur sind die Vorlage).
(4) Erst danach `harness.lua` je Repo auf `extend` reduzieren. Das deckt auch das offene Akzeptanzkriterium von
`fleet-standard-harness-goal` („`harness.lua`/`run.lua` je Repo entfernt oder auf einen dünnen Einstieg reduziert").

#### E-01 — Wiederverwendbare CI

**Befund.** 42 CI-Workflows, Median 124 Zeilen, Summe 5.915; jede ist ein individuell gewachsenes Exemplar des Scaffold-Templates
(`ci.yml.tpl`, 60 Zeilen). Die Pins sind einheitlich (`checkout@v5`, `setup-vim@v1`, `upload-artifact@v7`, Matrix 3 OS, `luacheck 1.2.0` in 39 von 42),
**aber nicht die des Templates**: das Template pinnt Neovim `v0.12.2` und legt `actions/cache` an — **keine** Flotten-CI hat das (Neovim `stable`
in 36, ohne Angabe in 5, `actions/cache` nur bei `mdview`). Das ist die Folge von E-03: Es gibt keinen Rückweg vom Template in die Repos.

**Vorschlag.** `StefanBartl/testing.nvim/.github/workflows/plugin-ci.yml` (`on: workflow_call`) mit Eingaben `deps`, `tools` (z. B.
`ripgrep`), `nvim`, `os`, `lint`, `cache`; die Repo-`ci.yml` besteht aus ca. 15 Zeilen (`uses: …@ci-verified`). Die ci-verified-Logik (Checkout je
Dependency mit `ref: ci-verified`, Veröffentlichung der Branch) und die IR-/Log-Artefakte wandern in den gemeinsamen Teil. **Zwei Einschränkungen,
beide gemessen:** (1) Die zwei privaten Repos (`casedesk`, `my`) starten derzeit gar keine Jobs (Billing) — ein Reusable Workflow ändert daran nichts;
(2) `documentation.nvim` (346 Zeilen: `map`, `standalone`), `mdview.nvim` (338: `rust`, `node`, `go`, `release`), `lsp.nvim` (219: `smoke`) und
`runtime-analysis.nvim` (`map`) haben Zusatz-Jobs, die als eigene `jobs.<x>` neben dem Aufruf stehen bleiben. Der Job `publish-ci-verified`
(Branch `ci-verified` nur vorrücken lassen, wenn stylua, luacheck und die Matrix grün sind; mit Lease gegen Rückwärtsbewegung) steckt bisher in
9 CI-Dateien und gehört in den gemeinsamen Teil.

#### E-02 — Dependency-Auflösung nur im Runner

**Befund.** Die Vier-Orte-Suche (`$<NAME>_DIR`, `.deps/<name>`, `../<name>`, `stdpath('data')/lazy/<name>`) ist **dreifach** implementiert: im
Runner (`testing.deps`), in `scripts/test.sh` (Bash, typisch 117 Zeilen, 40 Kopien) und in `TESTS/minimal_init.lua` (Lua, typisch 80–90 Zeilen, Spanne
18–171, 40 Kopien).
Die Funktionen `valid` und `env_name` stehen in 36 bzw. 35 minit-Kopien. Der Runner **setzt `$<NAME>_DIR` für jede aufgelöste Dependency
selbst** und führt die `minit` vor jedem Spec aus; im Runner-Betrieb ist die Suche in der `minit` also toter Code. Nur 14 von 41 Repos
referenzieren die `minit` überhaupt noch außerhalb (CI 8, Specs, die Sub-Editoren damit starten: ai 5, casedesk 3, hover 4 …).
Dazu kommen die Wünsche, die der Runner (`deps` → bei Fehlen Exit 3) nicht abbildet: **optionale Dependencies** in 5 Repos unter drei Namen
(`add_optional` hover, `add_optional_dep` ai/data, `add_dep` casedesk, `OPTIONAL_DEPS` in tasks' `test.sh` samt Umbenennung der Variable).

**Vorschlag.** (a) `.testing.lua`: `optional_deps = { "snacks.nvim" }` (Runner exportiert `$SNACKS_NVIM_DIR`, meldet „nicht gefunden" als Hinweis,
nicht als Exit 3), `env_alias = { ["snacks.nvim"] = "SNACKS_DIR" }`. (b) `scripts/test.sh` reduziert sich auf: nvim finden, testing.nvim
finden (die einzige Dependency, die Bash selbst braucht), `exec nvim … testing.lua run . "$@"` samt Sandbox-Variablen — ca. 30 statt 117 Zeilen. (c) Die
`minit` wird optional (`minit = false` ist im Schema schon erlaubt) bzw. zu einer Zeile (neu: `require("testing.minit").setup()`). (d) Specs, die
heute `vim.env.LIB_NVIM_PATH` / `REPOS_DIR` lesen, bekommen `require("testing.deps").dir("lib.nvim")` (die Funktion in `lua/testing/deps.lua` gibt es
bereits für den Runner); `testing migrate` schreibt die Stellen um (der Census kennt sie: `LIB_NVIM_PATH` 7 Repos, `LIB_NVIM_DIR` 6, `REPOS_DIR` 11,
`UI_NVIM_PATH` 4).
**Einsparung:** rund 6.500 Zeilen Boilerplate (`test.sh` 40 × ≈ 85 Zeilen, `minimal_init` ≈ 3.200) und ein Gedankengang weniger pro neuem Plugin;
E-01 spart weitere ≈ 5.300 (42 × ≈ 125 Zeilen).

#### E-03 — `testing sync`: Drift sichtbar machen und beheben

**Befund** (Medoid-Vergleich, Namen normalisiert): `.luacheckrc` 1 von 42 gleich, 41 weichen um 8–55 Zeilen ab (`sandbox` 55, `casedesk` 50,
`lsp` 38); `.luarc.json` 3 gleich, 27 > 6 Zeilen; `.gitattributes` 20 gleich, 21 weichen ab (documentation 67, runtime-analysis 60);
CI-Workflow 1 / 41; `test.sh` 6 gleich, 10 > 6 Zeilen (testing 146, tasks 56); `minimal_init` 8 gleich, 21 > 6. Ein Teil davon ist echte
Anpassung (Globals, Dependencies, Zusatz-Jobs), ein Teil ist Stand des Templates: `rules`, `ui` u. a. haben die `show_path`/`cygpath`-Logik des
heutigen `test.sh.tpl` nicht, keine CI hat die gepinnte Neovim-Version oder den Cache-Schritt des heutigen `ci.yml.tpl`. Der Scaffold überschreibt
prinzipiell nichts (`skipped`), `migrate` schreibt `.testing.lua` „never overwritten".

**Vorschlag.** `testing sync [--check|--diff|--apply] [--only luacheckrc,ci,test.sh,…]`: rendert die Templates mit den Werten des Repos (Name,
`deps`) und vergleicht Zeile für Zeile; `--check` ist ein CI-Schritt (Exit 1 bei Drift), bewusste Abweichungen werden mit einem Marker im Repo
begründet (`-- testing:sync keep: <Grund>`), wie die Waiver der Konformität. Das beseitigt die Drift als Klasse und macht E-01/E-02 sicher
ausrollbar.

#### E-11 — Skript-Dialekt: Einzelfälle aus den Ausgabezeilen

**Befund.** Die drei Skript-Monolithe (`filetree` 18 Dateien bis 295 KB, `pickers_spec.lua` 343 KB, `cmdlog` `smoke_spec.lua` 125 KB) und die
Skripte von `replacer`/`gopath` melden ihre Prüfungen als Zeilen — **in drei verschiedenen Formaten**: `    ok   <Name>` / `    FAIL <Name>` (filetree,
pickers, cmdlog), `PASS  <Name>` / `FAIL  <Name>` (replacer), `[ OK ] <Name>` / `[FAIL] <Name>` (gopath). testing.nvim wertet bisher nur den
Exit-Code und `[FAIL]`-Zeilen aus und macht **eine Datei zu einem Fall mit einer Assertion**.
**Vorschlag.** Der `script`-Dialekt erkennt diese drei Formate und erzeugt aus den Zeilen Fälle (Name = Zeile, Status = ok/FAIL, gruppiert nach
Datei; `skip`-Zeilen werden `skip`); ein unbekanntes Format bleibt beim heutigen Verhalten. Gewinn ohne eine Zeile Spec-Änderung: Fallzahlen,
Anzeige *welche* Prüfung rot ist, `--filter`-Treffer, Zählung im Verdikt („2.500 pass" statt „18 pass"). Beschränkung: die Guards bleiben datei-,
nicht fallbezogen, und `file:line` einer Prüfung ist nicht bekannt. Langfristig ersetzt der Kit (E-06) die drei Zeilenformate durch einen.

#### E-13 — Zeilenabdeckung (M7) vorziehen

Siehe §3.1 und §5.1: Der Prototyp dieses Audits (Hook + Auswertung, gut 250 Zeilen Lua) hat alle Suiten vermessen. M7 plant dasselbe
(„Zeilenebene opt-in per `debug.sethook("l")` im Kind, lcov-kompatibel") als `blocked`, Prio 3, „verzichtbar". Die Messung zeigt, dass es das
Mittel ist, um die Frage (a) für **Funktionen** in einer Zahl zu beantworten (die Binding-Coverage deckt nur die Bedienoberfläche ab), und sie nennt die
Stolpersteine, die ein Produkt-Modul beachten muss: der Timeout-Guard (`run/timeout.lua`) bindet `debug.sethook` beim Laden und überschreibt jeden
anderen Hook (der Prototyp wickelt `sethook/gethook` und leitet Count-Events weiter), Coroutinen brauchen den Hook einzeln (`coroutine.create/wrap`
wickeln), und die Laufzeit steigt im Median auf das 1,8-Fache (Q3 2,9×, Maximum 7,2× bei `language.nvim`; JIT aus). **69 Fälle in 8 Repos waren nur
mit Hook rot** — Skalierungs-Specs („stays fast", „linear": casedesk, lsp, terminal) und Timeouts schwerer Dateien (lsp `env_links_spec.lua`:
46 Fälle als `error: file exceeded 60000 ms`, gitsuite, hover, language, tasks). Für das Produkt: Abdeckung nur auf Anfrage (`--coverage`), Hook nur im Kind
bzw. nur für die Pfade des Projekts, Limits automatisch um einen Faktor anheben, Ausgabe als LCOV, Schwellen in `.testing.lua` (`coverage.lines`), und
Performance-Specs für den Lauf mit Hook als `skip` markieren statt rot.

#### Kurzbeschreibung der übrigen Punkte

- **E-04 Guard-Konfiguration.** `process_net.allow_exec` kennt nur exakte Namen (gopath im Kommentar: „allow_exec matches exact names, so it cannot be
  listed"), `fs` hat `allow_patterns`. → `allow_exec_patterns` (`^python3?[%d.]*$`), ein Preset `guards = "strict"` (16 von 39 Repos setzen alle
  sechs Guards auf `error`, 35 haben mindestens `fs`, `scheduled_error`, `prompt` und `deprecation` darauf), und das **Fixture-Verzeichnis** (`TESTS/.fixture*`) automatisch erlaubt, sobald der Kit es anlegt (reposcope listet acht
  Pfade einzeln, recommender zwei).
- **E-05 `order`.** Die zehn `run.lua` sind geordnete Spec-Listen mit der immer gleichen Begründung („kleinste Schicht zuerst: Units → Features
  → Facade → Wiring → Health"). Der Runner liest sie bereits als Manifest (Ausgabe „on disk but not in TESTS/run.lua (run last)"); als
  `order = { "units", "feature", … }` (Muster oder Präfixe) in `.testing.lua` wären sie überflüssig.
- **E-07 Capability-Gate.** Beispiel `cascade/TESTS/strings_spec.lua:161`: `if has_parser("javascript") then …` — fehlt der Parser, läuft der
  Block **still nicht**, der Fall bleibt grün (auf dieser Maschine fehlen 38 ausführbare Zeilen von `template_string`, §3.4). Drei Repos haben
  deshalb einen eigenen „fail statt skip"-Schalter (`PICKERS_REQUIRE_TOOLS`, `TASKS_REQUIRE_SNACKS`, documentation `REQUIRED`). → `K.need{…}`: ohne
  Fähigkeit ein **sichtbarer `skip` mit Grund**, mit `TESTING_REQUIRE=…` oder in der CI ein Fehler.
- **E-08 Testprogramme/Recorder.** Für „ein Programm, das es auf jedem OS gibt" ist `nvim -l skript.lua` die elegante Lösung (lib `run_argv_spec.lua`
  tut es seit langem; terminal baut `sleeper()` mit `ping -n 60` für Windows und `sleep 60` sonst). Die Recorder (`state.calls`, canned
  Antworten) gibt es in terminal (`fakes.lua`: wezterm/tmux als In-Memory-Modell), sandbox, pdfport, language (`markdown_helpers.fake`).
  Die **Domänenmodelle bleiben in den Repos** (wezterm/tmux, Übersetzungs-Provider); extrahiert wird nur das Gerüst „argv aufzeichnen,
  Antwort liefern, am Ende zurücksetzen".
- **E-09 `kit.perf`.** `casedesk/TESTS/cpu_time.lua` begründet, warum CPU-Zeit statt Wall-Clock („die ganze Suite läuft parallel, Wall-Clock
  ist um den Faktor zehn falsch, CPU-Zeit nicht") — und genau diese Specs sind es, die unter dem Abdeckungs-Hook zuerst scheitern (casedesk 10,
  lsp 4, terminal 1 Fall).
- **E-10 Vertrags-Checks.** Die gleichnamigen Specs sind keine Kopien (7–29 % gemeinsame Zeilen), prüfen aber denselben Vertrag: Config
  (`get()` vor `setup()` = Defaults; Nutzerwert gewinnt; `DEFAULTS` wird nie mutiert; `setup({})` stellt wieder her; unbekannter oder falsch
  typisierter Schlüssel → Eintrag in `issues()`, Wert bleibt Default), Health (`:checkhealth` läuft, nennt fehlende Soft-Dependencies),
  `:Cmd`-Hilfe. K2/K5/K6/K14 decken Teile ab; **der Config-Vertrag (30 Repos)** und die Hilfe (24) nicht. Weil `config.DEFAULTS` typisiert ist
  und die Surface-Lesung ihn schon einliest, lässt sich ein **K16** („Config-Vertrag") generisch erzeugen: jeder Schlüssel wird einmal falsch
  typisiert gesetzt. Die Plugin-Specs behielten nur die plugin-spezifischen Werte (Enumerationen, Wertebereiche).
- **E-12 `migrate`/`doctor`.** Zwei beobachtete Lücken: das Skript-Erkennen scheitert an `dofile('TESTS/ci_guard.lua')('TESTS/x.lua')`
  (replacer: 4 von 11), und `deps` in `.testing.lua` bleiben unvollständig, wenn die **Health-Prüfung** des Plugins mehr verlangt (K6-Fehler
  bei ai, insights, spotlight: `ui.nvim`/`ui.kit` fehlt) — `doctor` könnte K6-Fehlermeldungen dieser Art als „Dependency fehlt in `deps`" benennen.
- **E-14 `jobs`/`--cached`.** Alle Läufe sind seriell (kein Repo setzt `jobs`); `--jobs auto` ist im Scaffold-`ci.yml` nicht vorgesehen,
  `--cached` steht im Template, aber in keiner Flotten-CI. Das ist ohne Messung nicht zu bewerten (die README selbst sagt: der Cache zahlt sich bei
  reinen, kleinen Specs aus und bei Prozess-Specs kaum); sinnvoll ist ein Wert pro Repo, den `testing doctor` vorschlägt.
- **E-16 Config-Schema (lib.nvim).** Außerhalb der Frage „Testeinrichtung", aber der größte einzelne Duplikationsblock: 40 `config/init.lua`
  (8.886 LOC, Median 174), 27 mit eigener `issues`-Maschine (`describe_unknown`, „must be a X, got Y — using the default"), 25 nutzen
  `lib.lua.strings.distance.levenshtein` für „did you mean". `lib.nvim/lua/lib/nvim/config/` enthält nur `repo_file/`. Ein
  `lib.nvim.config.schema` (aus `DEFAULTS` abgeleitet: Typen, Enumerationen, Unbekanntes, Herkunft) würde die 30 `config_spec` auf das
  Plugin-Spezifische schrumpfen und E-10 zum einmaligen Test in lib machen. Das ist eine Architekturentscheidung (LUA-02: Primitive nach
  unten) und gehört in eine eigene Aufgabe, nicht in dieses Audit.

### 4.4 Was bewusst im Plugin bleiben soll

Domänenmodelle der Fremdprogramme (terminal: wezterm/tmux/Shell-Quoting-Modelle `shells.lua`; language: Übersetzungs-Provider-Fake;
pdfport: `fake_platform/fake_backend/fake_producer`; media: `ffprobe_video`), plugin-spezifische Fixtures (`TESTS/**/fixtures/`), die Sandbox-Wrapper um die Config des Plugins (`config_sandbox` in gopath), und Specs zu **dokumentierten Beispielen** (ai
`docs_support.lua`, casedesk `docs_markdown_spec`; nur 2–3 Repos, K14 deckt den Kern ab). Ein Helfer gehört nur dann in den Kit, wenn mindestens
drei Repos ihn unabhängig geschrieben haben **und** seine Semantik ohne Plugin-Wissen beschreibbar ist.

### 4.5 Reihenfolge

1. **Sofort, risikoarm und mit sichtbarem Ergebnis:** E-11 (Skript → Fälle), E-12 (zwei Erkennungslücken), README-Korrektur (E-15).
2. **Der Kern:** E-06 (Kit) mit zwei Piloten, parallel E-02 (Runner-seitige Deps) — beide haben denselben Nutzen im Rollout: dünnere `harness.lua`,
   `test.sh`, `minit`.
3. **Absichern des Rollouts:** E-03 (`sync`) vor E-01 (gemeinsame CI), weil es verhindert, dass die Repos wieder auseinanderlaufen.
4. **Messung:** E-13 (Abdeckung) — kann unabhängig davon laufen; liefert die Zahl, an der sich E-06 bis E-11 messen lassen.
5. **Danach** E-04/E-05/E-07/E-08/E-10, schließlich E-09/E-14/E-16.

## 5. Befunde am Werkzeug selbst (testing.nvim) — beim Messen aufgefallen

Reihenfolge nach Dringlichkeit. „Beleg" nennt die Stelle, an der man es nachprüft.

| ID | Befund | Beleg | Vorschlag |
|---|---|---|---|
| **F-1** | **testing.nvims CI ist seit heute 19:39 UTC rot**: der Job „lib.nvim suite via testing.nvim" scheitert auf allen drei Systemen (Läufe `37981737670`, `37982426076`, `37983909819`). Ursache: `lib.nvim/TESTS/harness_spec.lua` (Commit `c2581aa`, 08.10.) ist seit der Verschiebung von `lib.nvim`s `ci-verified` auf `18d24b3` (heute 13:38 UTC) in der geprüften Version enthalten. Das Spec prüft, dass `H.eq` bei Fehlschlag **wirft** (`pcall(H.with_patched, …, function() H.eq(1, 2) end)`); der Dialekt-`h`-Wrapper wandelt einen `FAIL …`-Fehler aber in „aufgezeichnet, `false` zurückgegeben" um (DIALECTS.md, „Dialect `h`") — das Spec bekommt `nil` statt der Fehlermeldung und scheitert in Zeile 31. Lokal reproduziert (lib `main`). Der letzte grüne Lauf war `41a3e1f` (08.10.) | `gh run view 37983909819 --log-failed`; `lib.nvim/TESTS/harness_spec.lua:23-33` | Zwei Wege: (a) im Wrapper eine Ausnahme für Specs, die das Verhalten des Harness selbst prüfen (Marker `-- @dialect h-raw` oder: solange innerhalb eines `pcall` aufgerufen, nicht aufzeichnen), (b) das Spec in lib auf `-- @testing skip` stellen. (a) ist die ehrlichere Lösung, weil jeder Harness ein solches Meta-Spec bekommen kann |
| **F-2** | **README ist an zwei Stellen überholt**: „Moving the fleet's repositories over has not happened" (Zeilen 40–41), und „Fleet status" ist der Stand vom 06.10. (39 von 41 Repos, damals ohne Migration). Heute: 39 Repos mit `.testing.lua`, 38 mit testing.nvim in der CI, alle Läufe grün bis auf drei (§3.7). Dazu die drei `.testing.lua`-Kommentare in `filetree`/`pickers`/`cmdlog` („testing.nvim installs no guard at all in a script file"), die nicht mehr stimmen | `README.md:40-41, 222-253`; `filetree.nvim/.testing.lua`, `pickers.nvim/.testing.lua`, `cmdlog.nvim/.testing.lua` | README-Absatz aktualisieren; die drei Kommentare korrigieren (Guards laufen in `pickers`/`cmdlog`, `state` entfällt; bei `filetree` kommt kein Protokoll an) |
| **F-3** | **`testing migrate` erkennt Skripte nicht, die die CI über einen Wrapper startet**: `replacer.nvim` ruft 11 Skripte als `dofile('TESTS/ci_guard.lua')('TESTS/<x>.lua')` auf; der Plan schlägt nur 4 als `spec_pattern` vor und meldet „specs: 0 (none)" | `testing migrate .` im Klon von `replacer.nvim`; `.github/workflows/ci.yml` dort | CI-Aufrufe der Form `dofile(…)('<datei>')`/`luafile` als Quelle der Spec-Liste erkennen; Wrapper (`ci_guard`) als „ersetzt durch Child-Isolation" melden |
| **F-4** | **`dialect = "testing"` ist im Schema erlaubt und reserviert, hat aber kein Modul**: `dialect/init.lua` nennt ihn ausdrücklich unter den Namen, die kein Dialekt sind („`unknown`, `testing`, typos"); in `DIALECTS.md` fehlt die Zeile. Eine native Spec-API (M6: `a.snapshot`, `a.screen`, `testing.feature(name, {…}, fn(a, nvim))`) ist geplant, aber nirgends nutzbar | `lua/testing/dialect/init.lua:117`; `lua/testing/config/project.lua:27, 461` | Entweder die Dialekt-Zeile entfernen, bis M6 steht, oder den Kit (E-06) als ersten Inhalt von `testing` liefern |
| **F-5** | **Die Konformitäts-Triage ist nicht vorangekommen**: heute 1 `pass` (testing.nvim), 29 `warn`, 9 `fail`, 1 `error` — am 08.10. waren es 27 / 9 / 3, kein `pass`. Die 9 `fail` sind **K6** (Health meldet fehlende Dependencies, 7×), **K9** (`my`: startet `pwsh` beim Laden), **K14** (`markdown`: `:Hover`, `sandbox`: `:LibLogger` nicht dokumentiert). **K15 warnt in 38 von 40 Repos** wegen *einer* Zeile: `diagnostics.globals` in `.luarc.json` führt `vim` (NEW-38) — eine Sammel-Änderung beseitigt 38 Warnungen. Sonst: K7 16×, K1 14×, K10 5× (`filetree` 227 ms gegen 40 ms Budget) | `testing conformance . --json` je Repo; Task `conformance-fleet-triage` | Eine Welle „`.luarc.json` ohne `vim`" (mit E-03 `sync` als Werkzeug); K6-Fehler entweder als Dependency-Lücke in `deps` (3×) oder als bewusste Waiver mit Grund |
| **F-6** | **K6 erzeugt für `sandbox.nvim` einen `error` (nicht `fail`)**: „the child editor could not run :checkhealth: child died … killed after a call timed out", Lauf 31 s; sandbox ist das einzige Repo mit Exit 3 der Suite | `conformance` `sandbox.nvim.json` | `:checkhealth sandbox` im Kind hängt (vermutlich ein Prozess-Aufruf ohne Timeout in `health.lua`); getrennt vom Audit zu untersuchen |
| **F-7** | **Guard-Konfiguration kennt nur exakte Namen für Prozesse**: `process_net.allow_exec` vs. `fs.allow_patterns`. Drei Repos führen `python3`, `python`, `python3.9` … `python3.15` einzeln auf; `gopath` begründet es im Kommentar („allow_exec matches exact names, so it cannot be listed") | `docs/GUARDS.md` (Tabelle der Tuning-Schlüssel); `mdview.nvim`, `my.nvim`, `insights.nvim` `.testing.lua` | `allow_exec_patterns` (E-04) |
| **F-8** | **Ein Cross-Repo-Drift-Spec ist rot**: `ui.nvim/TESTS/kit_drift_spec.lua` („ui.kit has not drifted from lib.nvim's copy") meldet `message_log.lua` — in der CI von `ui.nvim` rot auf allen 3 Systemen, lokal auch. Das Spec macht, was es soll: Der Spiegel ist veraltet. Das Spiegel-Werkzeug (`scripts/mirror_kit.lua --check`) existiert | `ui.nvim` CI-Lauf `37966137110`; Basis-Lauf dieses Audits | `mirror_kit.lua` laufen lassen, lib zuerst pushen (TOOLS: `ui.nvim/scripts`) |
| **F-9** | **`ci-verified` von `lib.nvim` ist 7 Commits hinter `main`** und enthält `harness_spec.lua`, nicht aber die neueren `run_argv_spec`-Änderungen (`0a7bab7`, `67d9e89`). Der Fehler, der lokal (Windows) auf `main` zusätzlich auftritt (`run_argv_spec.lua:366`: erwartet Exit 3, bekommt 1 — ein 400-KB-stderr-Test mit `os.exit(3)`), ist im CI-Bild von testing.nvim also noch nicht sichtbar. Davon getrennt: lib.nvims **eigene** CI ist auf Ubuntu und macOS rot (`git_run_spec.lua:449` „tags: a failing cat-file is an error", abhängig von der git-Version), auf Windows grün | `git rev-list --count origin/ci-verified..origin/main` in `lib.nvim`; Lauf `37955077319` | `run_argv_spec:366` auf Windows prüfen, bevor `ci-verified` vorrückt |
| F-10 | Die **eigene Suite von testing.nvim braucht 771 s** (13 min) lokal (`--jobs 4`, 167 Dateien, 20.274 Assertions), weil `isolated = auto` für die `h`-Dateien `none` bedeutet: ein Prozess, seriell, `--jobs` wirkungslos. Die CI-Matrix hat dafür 15 Minuten Timeout (`timeout-minutes: 15`) | `.testing.lua` von testing.nvim; Basis-Lauf | `isolated = "file"` mit `--jobs` für die prozessschweren Specs oder `--shard i/n` in der CI |
| F-11 | **Der Kit-Vorläufer in den Dialekt-Shims**: `harness_a/b/c.lua` enthalten hybride Überladungen (`scratch(lines?, ft?)` akzeptiert die Form des Dialekts B, `tmpdir(fn?)` beides), dokumentiert nur als Kompatibilität. Die API ist damit de facto vorhanden, aber nicht benannt | `lua/testing/dialect/harness_c.lua:35-68` | Kern von E-06 |
| **F-12** | **`replacer.nvim`-CI ist seit dem 08.10. rot**: der letzte Lauf (`37826813800`, Commit `518b149`) scheitert in der Matrix; auf Ubuntu und macOS an zwei im selben Commit neu angelegten Fällen (`cmd: quoted pattern with a flag-looking word is wrapped whole`, `cmd: :Replace takes a quoted pattern and a quoted replacement`, beide „-> say x --dry now", `=== 26 passed, 2 failed ===`), unter Windows bricht der Schritt vorher mit Exit 127 ab. Der Vorgänger `5f17b04` war grün. Der selbstgebaute Wrapper `ci_guard` macht den Fehler sichtbar (Zweck des Commits `400048a`); seitdem ist nichts behoben. Der migrierte Audit-Klon unter Windows lief 14 von 14 Skripten grün — die Ursache liegt also in der CI-Umgebung (Shell-Quoting der Testprogramme), nicht allein im Code | `gh run view 37826813800 --log-failed`; `replacer.nvim/.github/workflows/ci.yml` | beide Fälle unter Ubuntu/macOS nachstellen; Exit 127 heißt: ein von der CI aufgerufenes Programm fehlt unter Windows |
| F-13 | **Audit-Artefakt, kein Befund:** `lib.nvim/TESTS/git_spec.lua:106` scheitert im Klon, weil dessen Push-URL abgeschaltet ist (`git.remote_url("origin")` → `nil`). In den echten Repos läuft es. Gilt für jeden Spec, der den `origin` des Checkouts liest | `git remote -v` im Klon | – (nur für Wiederholungen des Audits wichtig: `fix_remotes.sh` setzt `remote.origin.pushurl` auf einen Platzhalter; ein `pre-push`-Hook, der immer scheitert, verhindert das Pushen, ohne die URL zu verändern) |

### 5.1 Zeilenabdeckung in testing.nvim — was der Prototyp lehrt (F-1 von §4: E-13)

Drei Dinge, die ein Produkt-Modul beachten muss und die man erst beim Messen sieht:

1. **`debug.sethook` hat pro Thread genau einen Haken.** `lua/testing/run/timeout.lua` ruft `sethook(check, "", 10000)` (Count-Hook) und stellt am Ende
   `saved.hook` wieder her. Ein Zeilen-Hook würde im In-Process-Lauf (`isolated = none`, 7 Repos) während jedes Specs überschrieben. Außerdem bindet das
   Modul `debug.sethook` **beim Laden** (`local sethook = debug.sethook`, Zeile 33): ein später gewickeltes `debug.sethook` sieht es nicht. Der Prototyp
   patcht diese zwei Zeilen in der Mess-Kopie auf Aufruf-Bindung und wickelt `sethook/gethook`, sodass Count-Events weiter zum Guard gehen.
2. **Coroutinen**: LuaJIT-Hooks sind pro `lua_State`; neu erzeugte Coroutinen (`lib.nvim.async`) laufen ohne Hook. `coroutine.create/wrap` müssen die
   Funktion vor dem Start mit `debug.sethook(co, …)` ausstatten.
3. **Nenner**: „ausführbare Zeilen" liefert `jit.util.funcinfo(f, pc).currentline` über alle Prototypen (`jit.util.funck(f, -i)` vom Typ `proto`),
   ohne den Code auszuführen; reine `end`-Zeilen (der `RET` einer Funktion, die immer früh zurückkehrt) gehören nicht in die Rechnung.

Messwerte des Prototyps: Laufzeit im Median 1,8× (Q1 1,6×, Q3 2,9×, Maximum 7,2×; JIT aus), Ausgabe je Prozess eine Datei mit „Datei⇥Zeile" (einmalig je Zeile; ungepuffert, damit ein
getöteter Prozess nichts verliert); zusammengeführt wird erst bei der Auswertung. Ein Spot-Check (`cascade.nvim`, `lua/cascade/strings/init.lua`: die
38 als „nicht ausgeführt" gemeldeten Zeilen von `template_string` liegen hinter `if has_parser("javascript")` im Spec — der Parser fehlt auf dieser
Maschine) und der Probelauf `rules.nvim` (die vier Module, die kein Spec benennt, haben 0 %; die Engine-Module 98–99 %) bestätigen die Messung.

## 7. Empfohlene nächste Schritte

Die Schritte sind nach **Nutzen je Aufwand** geordnet; Aufwand: S ≤ 1 Tag, M 2–4 Tage, L 5–10 Tage (Schätzung, nicht gemessen). Jeder Block ist
als eigene Task gedacht (`scripts/tasks.lua new …`); hier steht nur, was die Messung belegt.

### 7.1 Sofort — rote Ampeln und kaputte Zusagen (jeweils S)

| # | Schritt | Beleg | Wo |
|---|---|---|---|
| 1 | **testing.nvim-CI wieder grün** (F-1): Meta-Specs, die das Wurfverhalten von `H.eq` prüfen, vom `h`-Wrapper ausnehmen (`pcall`-Kontext nicht aufzeichnen) | §5 F-1; Läufe `37981737670`, `37982426076`, `37983909819` | testing.nvim |
| 2 | **replacer.nvim-CI wieder grün** (F-12): zwei im Commit `518b149` neu angelegte Fälle (`quoted pattern with a flag-looking word …`, `:Replace takes a quoted pattern …`) scheitern auf Ubuntu und macOS mit `say x --dry now`; auf Windows bricht der Schritt mit Exit 127 ab (Programm nicht gefunden). Rot seit 08.10., 20:45 | §5 F-12; Lauf `37826813800` | replacer.nvim |
| 3 | **ui↔lib-Kit-Drift** (F-8): `scripts/mirror_kit.lua` laufen lassen, lib **zuerst** pushen, auf `ci-verified` warten, dann ui | §5 F-8 | ui.nvim, lib.nvim |
| 4 | **lib.nvim lokal und in der CI rot** (F-9): `run_argv_spec.lua:366` (Windows, Exit 3 erwartet, 1 bekommen) und `git_run_spec.lua:449` (Ubuntu/macOS, git-Version) | §5 F-9 | lib.nvim |
| 5 | **README von testing.nvim** auf den heutigen Stand (F-2) und die drei überholten Kommentare in `.testing.lua` von filetree/pickers/cmdlog | §5 F-2 | testing.nvim, filetree, pickers, cmdlog |
| 6 | **Lint-Fehler in den privaten Repos** (`casedesk`: luacheck, docs; `my`: luacheck, stylua) beheben und die Billing-Sperre klären — beide haben derzeit keine CI-Aussage | §3.7 | casedesk.nvim, my.nvim |
| 7 | **`.luarc.json` ohne `vim` in `diagnostics.globals`** in einer Welle (K15 warnt in 38 von 40 Repos wegen dieser einen Zeile) | §3.5, F-5 | alle |
| 8 | `sandbox.nvim`: `:checkhealth` hängt im Kind-Editor (K6 `error`, einziges Repo mit Exit 3) untersuchen | §5 F-6 | sandbox.nvim |

### 7.2 Abdeckung gezielt schließen (je Repo M)

Reihenfolge nach „offene Zeilen × Kernlogik-Anteil", nicht nach Prozent: zehn Repos halten 62 % aller nicht ausgeführten Zeilen (§3.1).

1. **Die Kernlogik-Lücken zuerst** (45 % der offenen Zeilen, §3.3): `lib` (7.229 offene Zeilen, mehr als jedes andere Repo; 165 Dateien laufen nie, z. B.
   `buf_win_tab/windows_utils.lua`, `strategies/lazy.lua` — oder sind tot und gehören gelöscht), `markdown` (`commands/mdtable.lua` 8 %, `core/table_wrap.lua` 6 %),
   `casedesk` (`ui/lifecycle.lua` 7 %, `ui/cases.lua` 34 %), `lsp` (`core/env_links_server.lua`, siehe Messgrenze in §1), `filetree`
   (`commands.lua` 41 %, die Adapter `neotree`/`nvimtree` 45 % / 16 %), `images` (`init.lua` 13 %, `calibrate.lua`, `debug.lua` 0–15 %).
2. **Repos unter 70 %:** media 58,1, images 61,9, my 65,5, recommender 67,5, mdview 67,6, markdown 69,5, lib 69,99. Sie haben zugleich die
   höchste Quote von `feat/fix` ohne Teständerung (my 43 %, images 41 %, mdview 37 %): hier fehlt nicht nur Bestand, hier läuft die Lücke weiter auf.
3. **Totes zuerst entfernen, nicht testen:** `debugging/views/debug_helper.lua` (166 Zeilen, 0 %) ist nach `debugging.nvim/TESTS/README.md` bestätigter
   toter Code und wird von keinem Modul geladen (`docs/map/overview.md`: `unreferenced-module`). Danach `gitsuite/features/dashboard/view.lua` (723 Zeilen, 0 %,
   die größte Einzellücke der Flotte): Aufrufer suchen — entweder ebenfalls tot oder der wichtigste fehlende Spec.
4. **Bindungen testen, die heute keiner anfasst:** Keymaps 10 % (14 von 134), Commands 32 %, Autocmds 54 %; **`plugin/` läuft in keinem
   Repo**. Der billigste Anfang ist ein Spec je Repo, das `plugin/*.lua` lädt und `:Cmd` ohne Argument aufruft (Zusammenspiel mit K2/K5).
5. **Fünf Repos mit 0 % Binding-Coverage** (images, mdview, recommender, rules, tasks; dazu dap und documentation): `surface.track` in
   `.testing.lua` einschalten und die Liste der fehlenden Bindings als Arbeitsliste lesen.

### 7.3 Hygiene (S je Repo, als Welle)

- **`state`-Guard auf `error`** in den 20 von 39 Repos, in denen er es nicht ist. Reihenfolge nach Funden im Messlauf: lsp (3.198), casedesk
  (3.078), sandbox (1.134), gitsuite (924), mdview (915), terminal (814), ai (627), github_stats (575). Jeder Fund ist ein Spec, der Zustand
  hinterlässt; auf `warn` bleibt er sichtbar, aber folgenlos.
- **`surface.track`, `coverage.*` und `setup` in `.testing.lua`** setzen (heute in 0 von 39): ohne `setup` sind K3, K4, K12 und K13 in 22
  Repos `n/a`.
- **Skript-Monolithe** (filetree, pickers, cmdlog): E-11 liefert die Fälle ohne Spec-Änderung; danach schrittweise in Dateien nach
  Feature teilen (filetree: 18 Dateien, bis 295 KB).
- **replacer.nvim migrieren** (`testing migrate`, nach E-12): im migrierten Klon liefen 14 von 14 Skripten grün bei 77,6 % Abdeckung.
- **Hooks installieren:** pre-push/Claude-Stop-Hooks gibt es nur als Rezept (`docs/HOOKS.md`), in 0 Repos eingerichtet. Ein Hook, der bei
  `feat`/`fix` ohne Teständerung warnt, trifft die 18 % ungetesteter Verhaltensänderungen (448 von 2.436 Commits in 30 Tagen).

### 7.4 Extraktion (§4.5 in der Reihenfolge)

1. **E-11** (Skript → Fälle), **E-12** (zwei Erkennungslücken in `migrate`/`doctor`), **E-15** (README; `dialect = "testing"`) — S, risikoarm.
2. **E-06** (`testing.kit`) mit zwei Piloten (`runtime-analysis`, `rules`) und **E-02** (Dependency-Auflösung nur im Runner) — der Kern.
3. **E-03** (`testing sync`) **vor** **E-01** (wiederverwendbare CI), damit die Kopien nach dem Rollout nicht wieder auseinanderlaufen.
4. **E-13** (Zeilenabdeckung als Feature) parallel: Der Prototyp liegt vor (§5.1) und liefert die Zahl, an der sich alles andere messen lässt.
5. Danach E-04/E-05/E-07/E-08/E-10, zuletzt E-09/E-14/E-16.

### 7.5 Als eigene Entscheidung herausnehmen

- **E-16** (`lib.nvim.config.schema`, 8,9 KLOC Config-Validierung in 27 Eigenbauten): Architekturfrage (LUA-02), nicht Teil der Testwerkzeuge.
- **Mutationstest-Stichprobe** (`mutation_driver.lua`) an den drei Repos mit der höchsten Abdeckung und den wenigsten Assertions je Zeile: erst sie
  sagt, ob 90 % Zeilenabdeckung auch Fehler fängt (§6).
- **Wiederholbarkeit:** den Flotten-Lauf als wiederkehrenden Job (`TOOLS/scripts/fleet-test-audit/`; die Läufe selbst dauerten hier zusammen rund 1,7 Stunden: Basis 31, Abdeckung 34, Surface 36, Konformität 3 Minuten) mit
  Vergleich zum letzten Bericht; Ziel-Kennzahlen: Median-Abdeckung, Anteil `feat/fix` ohne Test, Zahl der Kopien je Boilerplate-Datei.

## 6. Nicht geprüft

- **Linux und macOS lokal.** Die Läufe und die Abdeckung stammen von einer Windows-Maschine; für die anderen Systeme gilt nur der CI-Stand (§3.7).
- **Wirkung auf Fehler.** Zeilen- und Binding-Abdeckung sagen, was *ausgeführt* wird, nicht, ob die Assertions Fehler finden würden. Dafür gäbe es
  `mutation_driver.lua` (TOOLS) — im Audit nicht eingesetzt.
- **Qualität der Assertions** außer ihrer Zahl (zwei Mal `H.ok(true)` zählt wie zwei gute Prüfungen).
- **Flakiness.** Je Repo wurde jede Suite pro Messart einmal gefahren (Basis, Abdeckung, Surface — also dreimal); Abweichungen zwischen den Läufen
  sind in §3.7 genannt, eine Wiederholungsstatistik gibt es nicht.
- **Private Repos in der CI** (`casedesk`, `my`): wegen des Billing-Stopps ohne Aussage.
- **Die `nvim-config` selbst** (Konfig-Spec für die `keys`-Listen von `plugins/personal/init.lua`; der WKDBook-Task nennt ihn als fehlend) — kein `*.nvim`-Repo.
- **Die vier auskommentierten bzw. archivierten Plugins** (`learn-cli`, `mygrep`, `filetreepicker`, `neotree-fs-refactor`) und `sessions.nvim` taucht in den
  Installations-Specs nicht unter `StefanBartl/sessions.nvim` auf (wird aber als Repo vermessen).
- **Code in `tests/` lokal anders benannter Verzeichnisse** (NEW-48-Prüfung): die Konformitäts-Suite meldet dazu je Repo (K15), nicht dieser Bericht.
- **Konformität mit gesetztem `setup`**: ohne `setup` in `.testing.lua` sind K3, K4, K12 und K13 in 22 Repos `n/a`; mit voll eingeschaltetem
  `setup` wären es andere Zahlen.

## 8. Reproduktion und Werkzeuge

Alle Werkzeuge liegen in `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/TOOLS/scripts/fleet-test-audit/` (README dort). Gesamtablauf, die Befehle sind
die der Messung (Bash unter Windows, Verzeichnisse Beispiele):

```bash
T=…/TOOLS/scripts/fleet-test-audit ; W=/c/tnf          # kurzer Arbeitspfad: MAX_PATH
bash $T/sh/make_clones.sh $W/fleet && bash $T/sh/fix_remotes.sh $W/fleet
nvim -n -i NONE --headless -u NONE -l $T/lua/cfg_dump.lua $W/fleet $W/out/cfg_dump.json
node $T/js/inventory.js $W/fleet $W/out/cfg_dump.json $W/out         # statische Inventur
bash $T/sh/run_suites.sh $W/fleet $W/out/base 4                      # Basis-Lauf (testing.nvim-Runner)
bash $T/sh/run_conformance.sh $W/fleet $W/out/conf
bash $T/sh/prep_cov.sh $W/fleet $W/fleet-cov $W/tools $W/cov        # instrumierte Kopie (Hook in jeder minit)
bash $T/sh/run_cov.sh  $W/fleet-cov $W/cov $W/out/cov $W/tools 3
bash $T/sh/rerun_timeouts.sh $W/fleet-cov $W/cov $W/out/covre $W/tools   # schwere Dateien mit großen Limits; danach *.cov2.json über *.cov.json kopieren
bash $T/sh/run_surface.sh $W/fleet $W/out/surface 3
node $T/js/irstats.js $W/out/base ; node $T/js/covagg.js $W/out/cov ; node $T/js/confagg.js $W/out/conf
node $T/js/merge.js $W/out $W ; node $T/js/tables.js $W/out ampel ; node $T/js/numbers.js $W/out
```

| Datei | Zweck |
|---|---|
| `lua/covprelude.lua` | der Zeilen-Hook (komponiert mit fremden Hooks, wickelt Coroutinen), von jeder `minimal_init.lua` zuerst geladen |
| `lua/covreport.lua` | ausführbare Zeilen (`jit.util`) minus ausgeführte → JSON je Repo |
| `lua/cfg_dump.lua` | wertet die `.testing.lua` aller Repos aus (Funktionen → `"<function>"`) |
| `js/lualex.js`, `js/inventory.js` | Scanner (Kommentare/Strings maskiert, Funktionsgrenzen) und Inventur |
| `js/census.js`, `js/funcs.js`, `js/families.js`, `js/showfn.js` | Idiome, Hilfsfunktionen nach Name/Body, Familien, Varianten einer Funktion anzeigen |
| `js/drift.js`, `js/drift2.js`, `js/contract_specs.js` | Boilerplate-Drift (Hash / Zeilen-Diff zum Medoid), gleichnamige Specs |
| `js/churn.js` | Ko-Änderung Code/Test aus `git log --numstat` |
| `js/irstats.js`, `js/confagg.js`, `js/covagg.js`, `js/merge.js`, `js/tables.js`, `js/numbers.js`, `js/gapclass.js`, `js/gapinfo.js` | Auswertung und Tabellen für diesen Bericht; Klassifikation der ungetesteten Zeilen |
| `sh/*.sh` | Klone, Läufe, Konformität, Surface, instrumentierte Kopie, Wiederholung der Timeout-Dateien |

**Warum ein eigener Hook und nicht `luacov`?** luacov braucht PUC-Lua/`luacov`-Rocks und kennt die Kind-Editoren von testing.nvim nicht; hier wird der
Hook über die `minit` in jeden Editor gebracht, und die Nenner kommen aus dem Bytecode des Neovim-LuaJIT selbst (dieselben Zeilen, die der Hook sieht).

**Platzierung nach TOOL-PLACEMENT.md:** Fall 5 (assume this machine's checkout layout, no plugin home) — daher `TOOLS/scripts/`, nicht in ein Plugin. Zwei Teile gehören
auf Dauer woanders: der Zeilen-Hook (+ Auswertung) nach testing.nvim (E-13), und der Funktions-/Body-Zensus als Option `:LibDuplicateScan --tests` nach
`lib.nvim.dev.duplicates` (das heutige Werkzeug sieht nur Funktionen ab Spalte 0 und scannt kein `TESTS/`).

## Anhang

Alle Tabellen werden aus den Messdaten erzeugt (`tables.js`, §8) — nicht von Hand gepflegt. „–“ = nicht gemessen oder nicht anwendbar, „…“ = Messung fehlt
(§3.2). ¹ `replacer.nvim` ist nicht migriert: Zahlen aus einem migrierten Klon.

### Anhang A — Überblick je Repo

Sortiert nach Zeilenabdeckung (aufsteigend). `T/C` = Test-LOC je Code-LOC. „Dialekt·Isol.“ = `dialect` und `isolated` aus `.testing.lua`. „Lauf heute“ = Verdikt des
Basis-Laufs (Windows).

| Plugin | Module / Code-LOC | Specs / Test-LOC | T/C | Dialekt·Isol. | Fälle | Assertions | Fälle je Datei (Median) | Zeilenabd. % | Dateien ohne jeden Treffer | Lauf heute |
| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | --- |
| media | 40 / 3.997 | 39 / 3.060 | 0,77 | h·file | 39 | 841 | 1 | 58,1 | 3 | grün |
| images | 39 / 5.128 | 37 / 3.155 | 0,62 | h·file | 37 | 1.181 | 1 | 61,9 | 4 | grün |
| my | 73 / 5.434 | 24 / 2.249 | 0,41 | auto·file | 220 | 814 | 10 | 65,5 | 15 | grün |
| recommender | 24 / 1.704 | 17 / 1.256 | 0,74 | h·none | 17 | 361 | 1 | 67,5 | 7 | grün |
| mdview | 83 / 7.220 | 47 / 6.256 | 0,87 | auto·file | 572 | 1.419 | 7 | 67,6 | 12 | grün |
| markdown | 88 / 10.335 | 50 / 5.814 | 0,56 | h·file | 50 | 1.323 | 1 | 69,5 | 5 | grün |
| lib | 469 / 34.311 | 112 / 25.294 | 0,74 | -·- | 112 | 20.587 | 1 | 70,0 | 165 | **rot** |
| debugging | 39 / 3.935 | 18 / 2.196 | 0,56 | h·file | 18 | 641 | 1 | 72,6 | 4 | grün |
| gitsuite | 58 / 7.099 | 31 / 8.198 | 1,15 | auto·file | 528 | 3.058 | 11 | 74,7 | 3 | **rot** |
| rules | 24 / 1.360 | 16 / 1.769 | 1,30 | map·file | 167 | 446 | 9 | 74,9 | 4 | grün |
| filetree | 145 / 22.560 | 18 / 19.161 | 0,85 | script·none | 18 | 18 | 1 | 77,1 | 5 | grün |
| replacer ¹ | 40 / 5.407 | 0 / 0 | 0,00 | -·- | 14 | 14 | 1 | 77,6 | 3 | grün |
| buffer-ctx | 48 / 4.499 | 14 / 2.353 | 0,52 | h·file | 14 | 913 | 1 | 78,1 | 6 | grün |
| runtime-analysis | 47 / 7.733 | 30 / 6.295 | 0,81 | h·file | 30 | 1.279 | 1 | 78,3 | 2 | grün |
| hover | 43 / 8.183 | 35 / 9.984 | 1,22 | auto·file | 765 | 89.522 | 17 | 80,2 | 7 | grün (Skip) |
| open | 26 / 2.366 | 17 / 2.560 | 1,08 | h·file | 17 | 531 | 1 | 81,0 | 2 | grün |
| sessions | 24 / 4.346 | 22 / 3.895 | 0,90 | h·file | 22 | 1.021 | 1 | 83,9 | 0 | grün |
| language | 62 / 8.763 | 39 / 7.223 | 0,82 | h·none | 39 | 39.929 | 1 | 84,2 | 4 | grün |
| lsp | 183 / 18.916 | 67 / 20.162 | 1,07 | map·file | 1.557 | 7.103 | 15 | 84,4 | 14 | grün (Skip) |
| pickers | 88 / 7.499 | 1 / 7.346 | 0,98 | auto·none | 1 | 1 | 1 | 85,2 | 13 | grün |
| casedesk | 121 / 21.159 | 107 / 29.567 | 1,40 | auto·file | 2.497 | 21.168 | 12 | 85,4 | 0 | grün |
| documentation | 148 / 26.551 | 117 / 20.033 | 0,75 | h·none | 117 | 6.003 | 1 | 85,6 | 13 | grün |
| cmdlog | 40 / 2.198 | 1 / 2.615 | 1,19 | auto·none | 1 | 1 | 1 | 86,6 | 0 | grün |
| sandbox | 268 / 7.812 | 39 / 8.261 | 1,06 | auto·file | 966 | 4.339 | 12 | 87,2 | 4 | grün |
| insights | 52 / 7.317 | 35 / 5.488 | 0,75 | h·file | 35 | 2.105 | 1 | 89,1 | 1 | grün |
| reposcope | 97 / 5.735 | 35 / 5.369 | 0,94 | h·file | 35 | 1.843 | 1 | 89,2 | 12 | grün |
| ui | 146 / 21.833 | 93 / 28.067 | 1,29 | auto·file | 1.906 | 35.502 | 10 | 89,2 | 6 | **rot** |
| ai | 33 / 5.486 | 37 / 10.443 | 1,90 | auto·file | 848 | 5.619 | 18 | 89,5 | 2 | grün |
| color_my_ascii | 93 / 8.125 | 29 / 3.486 | 0,43 | h·file | 29 | 5.635 | 1 | 89,8 | 2 | grün |
| fileops | 20 / 3.109 | 22 / 3.882 | 1,25 | h·none | 22 | 1.153 | 1 | 90,5 | 2 | grün (Skip) |
| dap | 40 / 2.177 | 30 / 2.634 | 1,21 | auto·file | 246 | 707 | 5 | 90,9 | 2 | grün |
| gopath | 77 / 7.002 | 22 / 9.039 | 1,29 | map·file | 22 | 2.526 | 1 | 91,0 | 10 | grün |
| cascade | 50 / 5.241 | 20 / 4.737 | 0,90 | h·file | 20 | 3.504 | 1 | 91,2 | 4 | grün |
| tasks | 43 / 14.613 | 44 / 13.235 | 0,91 | h·file | 44 | 9.615 | 1 | 91,6 | 4 | grün |
| emojis | 26 / 2.834 | 26 / 3.164 | 1,12 | h·file | 26 | 933 | 1 | 92,1 | 3 | grün |
| spotlight | 28 / 3.419 | 34 / 4.315 | 1,26 | auto·file | 34 | 1.470 | 1 | 92,2 | 1 | grün |
| terminal | 30 / 4.168 | 20 / 7.726 | 1,85 | auto·file | 544 | 79.657 | 22 | 92,3 | 1 | grün |
| pdfport | 53 / 4.327 | 21 / 4.940 | 1,14 | h·file | 21 | 1.580 | 1 | 92,4 | 2 | grün |
| diff | 28 / 2.914 | 34 / 4.711 | 1,62 | h·file | 34 | 1.308 | 1 | 93,1 | 2 | grün |
| github_stats | 48 / 5.723 | 25 / 7.147 | 1,25 | auto·file | 584 | 1.820 | 21 | 93,9 | 6 | grün |
| data | 22 / 1.497 | 31 / 5.867 | 3,92 | auto·file | 525 | 1.668 | 15 | 97,7 | 1 | grün |
| testing | 159 / 44.701 | 167 / 40.516 | 0,91 | auto·- | 167 | 20.274 | 1 | … | … | grün |

### Anhang B — Hygiene, Pflege, Konformität, Binding-Coverage je Repo

| Plugin | state-Guard | State-Funde (Zähler) | Fälle ohne Assertion | feat/fix ohne Test (30 Tage) | Konformität | Surface (Treffer/Gesamt) | .testing.lua |
| --- | --- | ---: | ---: | ---: | --- | ---: | --- |
| ai | error | 627 | 0 | 6/59 (10 %) | fail | 4/29 | ja |
| buffer-ctx | error | 0 | 0 | 6/33 (18 %) | warn | 8/64 | ja |
| cascade | error | 0 | 0 | 3/30 (10 %) | warn | … | ja |
| casedesk | warn | 3078 | 5 | 17/207 (8 %) | warn | 25/126 | ja |
| cmdlog | error | 0 | 0 | 3/20 (15 %) | warn | … | ja |
| color_my_ascii | error | 0 | 0 | 7/21 (33 %) | warn | 15/23 | ja |
| dap | off | 0 | 0 | 5/25 (20 %) | fail | 0/15 | ja |
| data | off | 0 | 0 | 1/27 (4 %) | warn | 23/29 | ja |
| debugging | error | 0 | 0 | 5/28 (18 %) | warn | 5/47 | ja |
| diff | error | 0 | 0 | 5/29 (17 %) | warn | 6/9 | ja |
| documentation | warn | 209 | 0 | 5/25 (20 %) | warn | 0/2 | ja |
| emojis | warn | 0 | 0 | 3/23 (13 %) | warn | 11/13 | ja |
| fileops | warn | 223 | 0 | 7/34 (21 %) | warn | 26/35 | ja |
| filetree | default | 0 | 0 | 18/144 (13 %) | warn | leer | ja |
| github_stats | warn | 575 | 4 | 3/20 (15 %) | fail | 3/13 | ja |
| gitsuite | warn | 924 | 0 | 15/67 (22 %) | warn | 8/50 | ja |
| gopath | error | 0 | 0 | 7/45 (16 %) | warn | 25/35 | ja |
| hover | off | 0 | 0 | 6/41 (15 %) | warn | 4/27 | ja |
| images | error | 0 | 0 | 14/34 (41 %) | warn | 0/28 | ja |
| insights | error | 0 | 0 | 10/43 (23 %) | fail | 20/31 | ja |
| language | warn | 151 | 0 | 4/38 (11 %) | warn | 4/5 | ja |
| lib | default | 423 | 0 | 98/305 (32 %) | – | leer | **nein** |
| lsp | warn | 3198 | 2 | 12/129 (9 %) | fail | 64/157 | ja |
| markdown | error | 0 | 0 | 14/46 (30 %) | fail | 3/8 | ja |
| mdview | warn | 915 | 2 | 16/43 (37 %) | warn | 0/36 | ja |
| media | error | 0 | 0 | 9/36 (25 %) | warn | 2/19 | ja |
| my | off | 0 | 0 | 19/44 (43 %) | fail | 18/49 | ja |
| open | error | 0 | 0 | 1/17 (6 %) | warn | 4/5 | ja |
| pdfport | error | 0 | 0 | 9/31 (29 %) | warn | 9/10 | ja |
| pickers | warn | 0 | 0 | 18/73 (25 %) | fail | leer | ja |
| recommender | warn | 112 | 0 | 3/12 (25 %) | warn | 0/9 | ja |
| replacer ¹ | default | 0 | 0 | 6/26 (23 %) | – | … | **nein** |
| reposcope | error | 0 | 0 | 10/45 (22 %) | warn | 15/18 | ja |
| rules | warn | 58 | 0 | 5/37 (14 %) | warn | 0/5 | ja |
| runtime-analysis | error | 0 | 0 | 3/28 (11 %) | warn | 7/29 | ja |
| sandbox | warn | 1134 | 0 | 3/32 (9 %) | error | 14/132 | ja |
| sessions | error | 0 | 0 | 12/64 (19 %) | warn | 19/39 | ja |
| spotlight | error | 0 | 0 | 0/18 (0 %) | fail | 20/33 | ja |
| tasks | error | 0 | 0 | 14/69 (20 %) | warn | 0/15 | ja |
| terminal | default | 814 | 0 | 5/35 (14 %) | warn | 13/23 | ja |
| testing | error | 178 | 0 | 1/53 (2 %) | pass | 5/16 | ja |
| ui | off | 0 | 1 | 40/300 (13 %) | warn | leer | ja |

### Anhang C — Die 45 größten nicht ausgeführten Dateien

Dateien mit ≥ 90 nicht ausgeführten Zeilen. Zeilen, die nur `end` enthalten, zählen nicht; Konstanten-Tabellen und Funktionsköpfe zählen mit (§1).

| Plugin | Datei | nicht ausgeführte Zeilen | ausführbare Zeilen | Abd. % |
| --- | --- | ---: | ---: | ---: |
| gitsuite | `lua/gitsuite/features/dashboard/view.lua` | 723 | 723 | 0 |
| markdown | `lua/markdown/commands/mdtable.lua` | 364 | 397 | 8 |
| runtime-analysis | `lua/runtime-analysis/telemetry/command.lua` | 347 | 588 | 41 |
| markdown | `lua/markdown/core/table_wrap.lua` | 289 | 306 | 6 |
| filetree | `lua/filetree/adapter/neotree.lua` | 288 | 527 | 45 |
| filetree | `lua/filetree/commands.lua` | 282 | 477 | 41 |
| images | `lua/images/init.lua` | 279 | 322 | 13 |
| casedesk | `lua/casedesk/ui/cases.lua` | 276 | 418 | 34 |
| casedesk | `lua/casedesk/ui/lifecycle.lua` | 268 | 289 | 7 |
| documentation | `lua/documentation/editor/health.lua` | 261 | 261 | 0 |
| hover | `lua/hover/init.lua` | 258 | 992 | 74 |
| media | `lua/media/bindings/usrcmds.lua` | 252 | 388 | 35 |
| runtime-analysis | `lua/runtime-analysis/bindings/usrcmds.lua` | 250 | 480 | 48 |
| media | `lua/media/hub/dashboard.lua` | 217 | 302 | 28 |
| documentation | `lua/documentation/editor/browse/init.lua` | 209 | 666 | 69 |
| hover | `lua/hover/preview/media.lua` | 206 | 348 | 41 |
| lib | `lua/lib/nvim/buf_win_tab/windows_utils.lua` | 205 | 205 | 0 |
| filetree | `lua/filetree/adapter/nvimtree.lua` | 193 | 229 | 16 |
| tasks | `lua/tasks_nvim/ui/cmd.lua` | 187 | 945 | 80 |
| lib | `lua/lib/lua/time/diff/init.lua` | 182 | 190 | 4 |
| replacer ¹ | `lua/replacer/rg.lua` | 181 | 520 | 65 |
| images | `lua/images/calibrate.lua` | 175 | 175 | 0 |
| debugging | `lua/debugging/views/debug_helper.lua` | 166 | 166 | 0 |
| filetree | `lua/filetree/features/fileops/trash/platform.lua` | 164 | 175 | 6 |
| documentation | `lua/documentation/core/cli.lua` | 160 | 241 | 34 |
| images | `lua/images/debug.lua` | 160 | 189 | 15 |
| buffer-ctx | `lua/buffer_ctx/commands.lua` | 154 | 285 | 46 |
| lib | `lua/lib/nvim/bindings/audit.lua` | 153 | 348 | 56 |
| recommender | `lua/recommender/bindings/usrcmds.lua` | 153 | 241 | 37 |
| language | `lua/language/translate/window.lua` | 146 | 146 | 0 |
| markdown | `lua/markdown/commands/links.lua` | 144 | 213 | 32 |
| ui | `lua/ui/bindings/usrcmds/init.lua` | 144 | 470 | 69 |
| lib | `lua/lib/strategies/lazy.lua` | 142 | 142 | 0 |
| lib | `lua/lib/nvim/normalize/validators.lua` | 142 | 182 | 22 |
| tasks | `lua/tasks_nvim/ui/dash.lua` | 139 | 705 | 80 |
| runtime-analysis | `lua/runtime-analysis/health.lua` | 138 | 138 | 0 |
| sessions | `lua/sessions/marks/menu.lua` | 135 | 320 | 58 |
| lib | `lua/lib/nvim/bindings/autocmd/docs.lua` | 129 | 275 | 53 |
| lib | `lua/lib/nvim/fs/path_shorten/init.lua` | 125 | 126 | 1 |
| images | `lua/images/health.lua` | 124 | 124 | 0 |
| debugging | `lua/debugging/autocmds/sources.lua` | 122 | 306 | 60 |
| lib | `lua/lib/nvim/ui/kit/chip.lua` | 122 | 341 | 64 |
| lib | `lua/lib/nvim/treesitter/parser_policy/init.lua` | 118 | 118 | 0 |
| lib | `lua/lib/lua/tables/core.lua` | 118 | 153 | 23 |
| documentation | `lua/documentation/editor/browse/view.lua` | 117 | 856 | 86 |

### Anhang D — Stand der Repos

Alle Repos standen auf `main`, ohne geänderte oder ungetrackte Dateien (`repo_state.sh`). Die Klone sind auf diesen Commits aufgesetzt.

| Repo | Commit (main) |
| --- | --- |
| ai.nvim | `69bd6be7` |
| buffer-ctx.nvim | `901fb10b` |
| cascade.nvim | `f3b15c5e` |
| casedesk.nvim | `c6a1f57a` |
| cmdlog.nvim | `3fdcef48` |
| color_my_ascii.nvim | `82e902d4` |
| dap.nvim | `660a5dfc` |
| data.nvim | `54a9d6f2` |
| debugging.nvim | `47ea51ad` |
| diff.nvim | `ae8c7838` |
| documentation.nvim | `bc26fa88` |
| emojis.nvim | `ee8764bb` |
| fileops.nvim | `f390c004` |
| filetree.nvim | `d0617bf4` |
| github_stats.nvim | `f3b47fe9` |
| gitsuite.nvim | `ac54fdf8` |
| gopath.nvim | `35062703` |
| hover.nvim | `63ac5b93` |
| images.nvim | `9f19c620` |
| insights.nvim | `f329e768` |
| language.nvim | `c659fe77` |
| lib.nvim | `67d9e89d` |
| lsp.nvim | `d0b9a5de` |
| markdown.nvim | `20ed40f7` |
| mdview.nvim | `b4941e6e` |
| media.nvim | `1965f81a` |
| my.nvim | `387d084b` |
| open.nvim | `b4de920b` |
| pdfport.nvim | `1d8995fe` |
| pickers.nvim | `fc780b15` |
| recommender.nvim | `8648a78d` |
| replacer.nvim | `518b149d` |
| reposcope.nvim | `cdf6897d` |
| rules.nvim | `51f377cc` |
| runtime-analysis.nvim | `2cff7787` |
| sandbox.nvim | `5623a062` |
| sessions.nvim | `a5513935` |
| spotlight.nvim | `4f7bb1f0` |
| tasks.nvim | `1267b957` |
| terminal.nvim | `ab1d6a4b` |
| testing.nvim | `41a3e1f3` |
| ui.nvim | `16aeaff1` |

### Anhang E — Boilerplate-Drift

Zeilen-Diff jeder Kopie gegen den Medoid (die Kopie mit der kleinsten Summe der Abstände), Repo-Namen normalisiert (`drift2.js`).

| Datei | Kopien | identisch zum Medoid | ≤ 6 Zeilen abweichend | > 6 Zeilen abweichend | Medoid |
| --- | ---: | ---: | ---: | ---: | --- |
| luacheckrc | 42 | 1 | 0 | 41 | cmdlog |
| stylua | 42 | 8 | 33 | 1 | ai |
| luarc | 42 | 3 | 12 | 27 | cmdlog |
| gitattributes | 42 | 20 | 1 | 21 | buffer-ctx |
| ci.yml | 42 | 1 | 0 | 41 | sessions |
| test.sh | 40 | 6 | 24 | 10 | gopath |
| minit | 40 | 8 | 11 | 21 | buffer-ctx |
