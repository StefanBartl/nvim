# Roadmap-Effort-Overview — alle Custom-Plugins

## Umsetzungsstand (laufend aktualisiert)

Abgearbeitet werden die Plugins in aufsteigender Aufwandsreihenfolge. Jedes
Feature einzeln committet, Docs + Vimdocs mitgeführt, auf `main` gepusht.

| Plugin | Status | Ergebnis |
|---|---|---|
| `lib.nvim` (Teil 1) | ✅ erledigt | Neues Modul `cross.fs.wslpath` (`to_win`/`to_unix`) — deduped drei unabhängige Kopien desselben Helpers aus open.nvim + lib.nvim selbst. Inkl. README, Spec, Vimdoc. |
| `open.nvim` | ✅ erledigt | 3 Commits: WSL-Bugfix in `notepad` (Windows-Binary bekam Linux-Pfad → schlug unter WSL immer fehl), Adoption des neuen lib-Moduls, fehlende Test-Assertion ergänzt, stylua+luacheck+CI eingeführt (0 Warnings), Audit-Docs entstaubt. |
| `debugging.nvim` | ✅ erledigt | CI ergänzt (Configs lagen da, liefen aber nie), beide "bewusst zurückgestellten" Audit-Items erledigt (`@see`-Verlinkung, `@types`-Gruppierung), Tree formatiert. |
| `buffer-ctx.nvim` | ✅ erledigt | Extmark-Drift-Bug behoben: Marks sind jetzt über Extmark-IDs verankert statt über rohe Zeilennummern. Zwei im Konzept nicht vorhergesehene Punkte mitgefixt (gelöschte Zeile vererbte die Marke an den Nachbarn; `sign_place`-Branch vereinheitlicht). 3 Regressionstests. |
| `pdfport.nvim` | ✅ erledigt | Testsuite von Null aufgebaut (4 Specs, alle Backends gefaked → läuft ohne pdftotext/python/ollama), stylua+luacheck+CI. Audit-Item "eager backend require" war bereits erledigt — jetzt per Test gegen Regression abgesichert. stylua-Instabilität in `usrcmds.lua` gefunden und behoben (hätte CI dauerhaft rot gemacht). |
| `markdown.nvim` | ✅ erledigt | Roadmap-Item 9a: In-Neovim-Bildvorschau via snacks.nvim/image.nvim (beide soft deps), konfigurierbar über `image.preview` (`ask`/`preview`/`system`). Fallback auf Systemviewer bei Fehlschlag, URLs immer System. 7 neue Testfälle. |
| `cmdlog.nvim` | ✅ erledigt | Roadmap war auf `main` bereits vollständig abgehakt. Stattdessen: `feature-notes` → `main` gemergt (11 Konflikte, inkl. zweier Architektur-Divergenzen), danach die gestashte plenary-Entfernung zurückgeholt **und fertiggestellt** (`core/store.lua` fehlte noch). |
| `lib.nvim` (Teil 2: `debug`-Modul) | ✅ erledigt (anders als geplant) | Das Konzept war **bereits umgesetzt** — als `lib.nvim.logger`. Ich hatte versehentlich ein Duplikat gebaut und wieder entfernt. Stattdessen: die zwei real fehlenden Funktionen (`count`/`counters`, `add_sink`) in `logger` ergänzt + Konzeptdokument als „shipped" markiert, damit der Irrtum nicht wiederkehrt. |

**Befund aus der Umsetzung — die Roadmap-Dokumente sind der unzuverlässigste
Teil dieses Ökosystems.** In fast jedem Repo war mindestens ein Punkt bereits
erledigt, als er notiert wurde:

- `open.nvim`: zwei von drei Action-Items schon umgesetzt (TESTS/ existierte,
  composer-Migration war durch)
- `pdfport.nvim`: „eager backend require" längst auf Lazy-Proxies umgestellt
- `cmdlog.nvim`: die komplette Feature-Roadmap auf `main` abgehakt, während
  die ROADMAP.md des Feature-Branches sie noch als offen führte
- `lib.nvim`: das gesamte Debug-Konzept war als `lib.nvim.logger` implementiert,
  das Dokument sagte weiterhin „no code yet" — **das hat mich zu einem
  Duplikat verleitet**, das ich wieder entfernen musste

Umgekehrt fand sich beim Umsetzen echte, in keiner Roadmap notierte Arbeit:
der WSL-`notepad`-Bug (Windows-Binary bekam Linux-Pfad), eine Test-Assertion
die nie geprüft wurde, das Vererben gelöschter Marks an die Nachbarzeile, eine
stylua-Instabilität die CI dauerhaft rot gemacht hätte, und eine unvollständige
plenary-Entfernung.

**Empfehlung:** Vor jeder weiteren Roadmap-Umsetzung erst den Code prüfen, nicht
das Dokument. Die Schätzungen unten bleiben als Ausgangslage stehen; der reale
Aufwand lag durchweg am unteren Ende der Spanne, weil viel schon gebaut war.

---

Stand der Analyse: 2026-07-30. Basis: `plugins/personal/source.lua` (28 Einträge, davon 27 aktiv
geladen + `learn-cli.nvim` disabled). Für jedes Repo unter `E:/repos/<name>` wurden
alle `docs/ROADMAP*`-Dokumente gelesen (teils per Recherche-Agents, wegen Umfang von
insgesamt >800KB Roadmap-Content über alle Repos). Aufwandsschätzung = Solo-Dev,
Feierabend/Wochenende, für den **kompletten dokumentierten Rest-Scope** des jeweiligen
Roadmaps (nicht: Neuentwicklung von Null).

**Wichtiger Befund:** Bei den meisten Repos existiert unter `docs/ROADMAP/` ein
Ordner mit **Audit-/Checklisten-Dokumenten** (Arch&Coding.md, Checklist.md,
Zentral-Prinzipien.md — generische Lua/Neovim-Qualitätschecklisten, die immer wieder
angewendet werden) statt einer echten Feature-Roadmap. Die eigentliche Feature-Roadmap
liegt bei einigen Plugins zusätzlich als eigenständige `docs/ROADMAP.md`-Datei *neben*
diesem Ordner (z.B. `github_stats.nvim`, `markdown.nvim`, `pickers.nvim`,
`debugging.nvim`, `color_my_ascii.nvim`). Das wurde unten überall berücksichtigt —
wo es einen relevanten Unterschied macht, ist es explizit vermerkt (v.a.
`github_stats.nvim`, dort war der Unterschied groß).

---

## Zusammenfassung (sortiert nach Aufwand, absteigend)

| Plugin | Aufwand (Rest-Scope) | Status |
|---|---|---|
| `mdview.nvim` | **6–10 Wochen** | größtes offenes Backlog (Overlay-System, Standalone-Binary, Highlighting-Mirror) |
| `github_stats.nvim` | **2–3 Wochen** (Kern) — bis zu **+11 Wochen** wenn alle mittleren/großen Features inkl. Webhook verfolgt werden | einzige Roadmap mit umfangreichem, konkret durchgeplantem Backlog inkl. Bugs |
| `lib.nvim` | 2–4 Wochen | Debug-Modul (`lib.nvim.debug`) komplett unstarted, Rest fertig |
| `spotlight.nvim` | 2–4 Wochen | 6 kleine + 2 größere ("needs design") offene Items |
| `filetree.nvim` | 1,5–3 Wochen | Markdown-Link-Bridge, Testcoverage, Perf-Audits |
| `color_my_ascii.nvim` | 1–3 Wochen | LSP-in-Fence (via otter.nvim-Adapter empfohlen) ist das einzige substanzielle Item |
| `documentation.nvim` | 1–3 Wochen | Reference-Tab (Lua-Syntax/LuaCATS) einzig scoped-aber-ungebaute Feature |
| `cmdlog.nvim` | 1–2 Wochen | Notes-Feature (nur Phase-1-Planung existiert), Preview-Pane, ein Persistenz-Bug |
| `markdown.nvim` | ~1 Woche | Bild-Preview-Integration (9a) + laufende Testerweiterung |
| `pdfport.nvim` | 3–6 Tage | Smoke-Tests, eager→lazy Backend-Loading, optionaler Window-Helper |
| `buffer-ctx.nvim` | 2–4 Tage | ein einzelner, aber gut durchdachter Bugfix (Extmark-Drift) |
| `open.nvim` | 0,5–1,5 Tage | reine Refactoring-Poliermaßnahmen |
| `debugging.nvim` | 0–1 Tag | v0.1–v0.3 vollständig fertig, nur 2 triviale "deferred" Cosmetics |
| `pickers.nvim` | 0 Tage | Roadmap zu 100% abgehakt (auch die reale Feature-Liste, nicht nur Audit) |
| `reposcope.nvim` | 0 Tage | "kein offener Backlog" laut eigener Roadmap |
| `sandbox.nvim` | 0 Tage | "nichts aktuell in der Queue" |
| `language.nvim` | 0 Tage | "All roadmap items implemented" |
| `replacer.nvim` | 0 Tage | Roadmap ist reines Done-Changelog, keine offenen Punkte |
| `recommender.nvim` | 0 Tage | "No open items" |
| `insights.nvim` | 0 Tage (eigenes Roadmap) | evtl. 3–6 Tage Feature-Portierung — aber das ist eigentlich `filetree.nvim`-Scope |
| `sessions.nvim` | — | Roadmap-Datei ist Platzhalter, kein Inhalt |
| `fileops.nvim` | — | Roadmap-Datei leer (37 Byte) |
| `dap.nvim` | — | Roadmap-Datei ist Platzhalter ("nichts geplant") |
| `diff.nvim` | — | Roadmap-Datei leer (34 Byte) |
| `emojis.nvim` | — | Roadmap-Datei komplett leer (0 Byte) |
| `gopath.nvim` | **nicht bewertbar** | kein Feature-Roadmap vorhanden, nur generische Audit-Checkliste (s. Flags unten) |
| `cascade.nvim` | **nicht bewertbar** | Repo liegt nicht lokal unter `E:/repos` (s. Flags unten) |
| `learn-cli.nvim` | ausgeschlossen | in `source.lua` explizit `disabled`, wird nicht geladen |

**Grobe Gesamtsumme** (nur Plugins mit echtem offenem Backlog, ohne die
`github_stats.nvim`-Zusatzoptionen mittel/groß, ohne unbewertbare/leere/fertige
Plugins): **rund 18–35 Wochen** Feierabend-Arbeit. Wird bei `github_stats.nvim` der
volle Roadmap-Umfang (inkl. Webhook-Integration und den drei "medium"-Features)
mitgerechnet, kommen realistisch nochmal **8–12 Wochen** dazu.

---

## 1. Core / Infrastructure, Utilities & System

### `lib.nvim` — 2–4 Wochen
Shared-Helper-Library, von der alle anderen ~27 Plugins abhängen (Fenster/Buffer,
Filesystem, Notify/Logging, UserCommand-Builder, Git-Helper, UI-Kit). Fast alles ist
fertig und mit ✅/`~~strikethrough~~` als erledigt markiert (UI-Kit, `usrcmd.composer`,
`store.project`, alle Audit-Findings). Offen ist nur ein einziges, aber konkret
gescoptes Feature: `lib.nvim.debug` (strukturiertes Logging/Crash-Dump-Modul, 4
Phasen, aktuell **null Code** — Logger-Factory, JSONL-Encoder + `fs.write.append`
fehlen komplett, xpcall-basiertes Crash-Capture, `:LibDebug`-Command). Dazu ein vages
`vim-parity`-Item ohne Detailplan. Kleiner interner Widerspruch: `fs.collect_recursive`
ist in einer Datei noch als ❌ gelistet, im Top-Level-`ROADMAP.md` aber schon als Done.

### `sessions.nvim` — kein Aufwand ermittelbar
Roadmap-Datei ist reiner Platzhalter ohne Inhalt.

### `pickers.nvim` — 0 Tage
Sowohl die Audit-Checklisten als auch die **echte Feature-Roadmap**
(`docs/ROADMAP.md`, separat gelesen) sind komplett abgehakt — inklusive der großen
Sachen wie Smart-Action (Grep+Find kombiniert mit Frecency-Boost), Native-Builtin-
Picker-Registry (52 Einträge), File-Explorer-Integration, Selected-Index-Overlay.
Einziger offener Punkt: "keine weiteren Autocmds geplant" (explizit leer).

### `buffer-ctx.nvim` — 2–4 Tage
Kein Feature-Backlog, sondern ein einzelner, bereits im Detail durchdachter Bug:
Marks werden über rohe Zeilennummern statt Extmark-IDs verfolgt, wodurch `:Mark yank`
nach Edits oberhalb eines Marks die falschen Zeilen kopiert. Fix-Design (inkl.
Code-Skizze) liegt schon vor, fehlt nur die Umsetzung + Edge-Case-Tests
(sign-column-Branch vs. Extmark-Branch).

### `open.nvim` — 0,5–1,5 Tage
Fast fertiges, kleines Utility-Plugin (~600 Zeilen). Reine Poliermaßnahmen: doppelten
`wsl_to_win_path`-Helper dedupen, stylua/luacheck-Config ergänzen, zwei Stellen auf
`lib.nvim`-Helper umstellen statt Handrolled-Code. Nichts davon blockiert irgendwas.

### `sandbox.nvim` — 0 Tage
Docker/Podman-Sandbox-Plugin (Hexagonal Architecture). Roadmap sagt explizit: "Nothing
queued right now — every item that was on this list has shipped."

### `spotlight.nvim` — 2–4 Wochen
Buffer-Highlighting/Log-Marking-Plugin. Vier der fünf Dateien sind abgeschlossene
Audit-Retrospektiven (heute, 2026-07-30 durchgeführt). Die echte Roadmap listet:
6 kleine, risikoarme Items (Match-Counts über alle Buffer, Quickfix-Integration,
Count/Dot-Repeat, Statusline-Component — zusammen ca. ein Wochenende) plus 2 größere,
noch nicht designte Features ("Spotlight Sets" = neues Persistenz-Format + UX, sowie
eine Occurrence-Density-Map in der Sign-Column — je 3–6 Abende). Explizit abgelehnte
Ideen (Regex-Mode, Auto-Rules, Live-Counts) zählen nicht mit.

### `documentation.nvim` — 1–3 Wochen
Doxygen-artiger Modul-Map/Doc-Drift-Generator, kürzlich aus `lib.nvim` in ein eigenes
Repo extrahiert. Sehr sauber getrackt: der komplette "Finish"-Plan (README,
Checkhealth, Tests, CI, Security-Audit) ist als DONE markiert. Genuinely offen sind
nur "costed, but not scheduled"-Punkte (Sprachsupport für JS/TS/Go, Lauffähigkeit
ohne Neovim) sowie ein einzelnes konkret gescoptes, aber ungebautes Feature: der
Reference-Tab (Lua-Syntax + LuaCATS-Tag-Crib-Sheets) — das größte tatsächlich
einplanbare Stück Arbeit hier.

---

## 2. Navigation, File System, Search & Trees

### `fileops.nvim` — kein Aufwand ermittelbar
Roadmap-Datei ist praktisch leer (37 Byte, nur Überschrift).

### `gopath.nvim` — nicht bewertbar (Flag)
**Wichtig:** Der `docs/ROADMAP`-Ordner enthält hier *keine* Feature-Roadmap, sondern
ausschließlich die generische, plugin-übergreifende Lua/Neovim-Auditcheckliste (die
gleiche Vorlage wie bei vielen anderen Plugins) — ohne jeden gopath.nvim-spezifischen
Inhalt. Es referenziert sogar andere Repos (`reposcope.config`,
`StefanBartl/lib.nvim`) als Beispiele, was bestätigt, dass es eine wiederverwendete
Vorlage ist. Es gibt keine erkennbare echte Roadmap für dieses Plugin — entweder liegt
sie woanders (GitHub Issues, TODOs im Code) oder existiert schlicht nicht.
**Empfehlung:** separat prüfen, ob es überhaupt eine gopath.nvim-Feature-Roadmap gibt.

### `replacer.nvim` — 0 Tage
Search-and-Replace-Plugin. Die Roadmap-Datei ist ein reines "Already shipped"-Log
(~35 Punkte: Dry-Run, Quickfix, Git-Changed-Scope, LSP-Rename, CI …), kein einziger
offener Punkt. Eigentlich eher ein CHANGELOG als ein ROADMAP.

### `insights.nvim` — 0 Tage
Eigene Roadmap explizit "Nothing currently open" (Multi-Language-Import-Scan über
Python/JS/TS/Go/Rust/C/C++ ist bereits fertig). Die einzige weitere Datei im Ordner
(`NEOTREE_FEATURES.md`) ist kein insights.nvim-Task, sondern eine Liste von
Features, die es wert wären, nach `filetree.nvim` portiert zu werden (Tree-Export,
Directory-Compression, File-Info-Float, File/Dir-Counts) — geschätzt 3–6 Tage, aber
das ist Scope von `filetree.nvim`, nicht von `insights.nvim` selbst.

### `filetree.nvim` — 1,5–3 Wochen
Großes Plugin: 70+ Feature-Module, 5-Backend-Adapter-Layer (neo-tree/nvim-tree/
netrw/oil/mini.files). CWD-Mode-Subsystem (6 Follow-Modi, Locking, Persistenz,
Statusline) ist explizit "Done — Nothing remaining", PDF-Integration ist laut Doku
bereits umgesetzt, Neo-Tree-Parity-Audit zeigt fast alle 62 Features schon portiert.
Offen: Markdown-Link-Bridge (soft dependency auf `markdown.nvim`, echte neue Arbeit),
Testcoverage-Ausbau über `test/smoke.lua` hinaus, Performance-Audits beim
Tree-Walk auf sehr großen Bäumen. Optional dazu käme noch das oben genannte
`insights.nvim`-Portierungsvorhaben (3–6 Tage).

### `reposcope.nvim` — 0 Tage
GitHub/GitLab/Codeberg-Repo-Browser mit vollem UI, Cloning, README-Cache,
Session-Persistenz — alle 14 gelisteten Punkte sind ✅, Roadmap sagt explizit: "no
open backlog at the moment."

---

## 3. Code Quality, UI, Logging & Productivity

### `debugging.nvim` — 0–1 Tag
Sehr diszipliniert getrackt über v0.1 → v0.2 → v0.3, alles fertig implementiert
(Tree-Sitter-Parser für Autocmd-Audits, Keylogger mit Logfile, Startup-Benchmark,
Scratch/Float-UI-Migration in `lib.nvim`). Explizite "Nicht geplant"-Sektion (kein
generischer Profiler, kein Locals/Upvalues-Dump — bewusste Scope-Grenzen). Nur zwei
triviale, selbst als "deliberately deferred" markierte Cosmetics offen (<1h
zusammen).

### `dap.nvim` — kein Aufwand ermittelbar
Roadmap-Datei ist Platzhalter: "Planned: Nothing currently planned."

### `diff.nvim` — kein Aufwand ermittelbar
Roadmap-Datei komplett leer (34 Byte).

### `language.nvim` — 0 Tage
Spell-Check + Übersetzungs-Plugin (Google/DeepL/Shell/Custom-Provider, Review-Panel,
Treesitter-Regionen, CLI-Adapter, persistenter Node-cspell-Sidecar). ~25 Punkte über
8 Phasen alle ✅. Roadmap-Text wörtlich: "All roadmap items implemented. Future ideas
welcome" — aber ohne eine einzige gelistete Idee. Empfehlung: ggf. gegen Commit-
Historie gegenchecken, ob die Datei wirklich aktuell gehalten wird.

### `cmdlog.nvim` — 1–2 Wochen
Command-History/Favorites-Manager (Telescope/fzf-lua). Vier shipped Features (Project
Favorites, Which-Key, Risky-Pattern-Highlighting, Delete-History-Entries) vs. offene
Preview-Pane sowie ein Notes-Feature für Favorites (nur Phase-1-Planung existiert,
noch kein Code) und ein noch ungefixter Bug (nvim-Log persistiert nicht korrekt).
Flag: Inhalt ist über 4 Dateien verstreut (teils Deutsch, teils Englisch) mit
Überschneidungen — Konsolidierung würde sich lohnen.

### `emojis.nvim` — kein Aufwand ermittelbar
Roadmap-Datei ist komplett leer (0 Byte). Plugin selbst funktioniert laut README
(Emoji entfernen/zählen/auflisten/ersetzen/einfügen über Zeile/Selection/Buffer/
Projekt), nur eben ohne dokumentierten Rest-Scope.

### `github_stats.nvim` — 2–3 Wochen (Kern), bis zu +8–11 Wochen optional
**Größte Abweichung zwischen Audit-Ordner und echter Roadmap** in diesem gesamten
Review: Die drei Audit-Dateien allein sahen nach reiner Tooling-Hygiene aus (kein
stylua/luacheck, kaputte Testreferenzen). Die separate `docs/ROADMAP.md` enthält aber
einen **großen, konkret durchgeplanten Feature-Backlog mit expliziten
Aufwandsschätzungen des Autors selbst**:
- **Priorität 0 (Bugs, Root Cause bekannt):** Dashboard-Scrolling schneidet letzten
  Eintrag ab (Off-by-one in der Zeilen-Berechnung), zweiter unabhängiger Cursor-Bug
  derselben Klasse, kaputte Testsuite-Referenzen (nicht-existente Module) ohne
  CI-Runner — zusammen ca. 2–4 Tage.
- **Priorität 1 (kleine, bereits gescopte Features):** Autocomplete Date Suggestions
  (2–3 Tage), Export Templates (3–5 Tage), Fetch Progress Indicators (3–4 Tage),
  Comparison Baseline (~1 Woche) — zusammen **~2–3 Wochen**.
- **Priorität 2 (mittlere Features, laut Roadmap "pick one at a time"):**
  Notification Thresholds (1–2 Wochen), Repository Groups/Tags (1–2 Wochen),
  Interactive Chart Navigation (2–3 Wochen, größtes der drei) — zusammen **4–7
  Wochen**, falls alle drei verfolgt werden.
- **Priorität 3 (groß, bewusst zuletzt):** Webhook-Integration — eigener HTTP-Server
  in reinem Lua, Cross-Platform NAT/ngrok, HMAC-Verifizierung. Vom Autor selbst auf
  **4–5 Wochen** geschätzt, im Dokument ausdrücklich vertagt ("Revisit only once
  Priority 0-2 are done and there's a concrete user request").
- Zwei "Experimental Ideas" (KI-gestützte Insights, GitHub-Actions-Integration)
  sind bewusst nicht priorisiert/designt, zählen hier nicht mit.

Kern-Commitment (P0+P1) ≈ **2–3 Wochen**. Voller Roadmap-Umfang inkl. aller
mittleren Features und Webhook ≈ **3–4 Monate** Feierabend-Arbeit.

### `learn-cli.nvim` — ausgeschlossen
In `source.lua` explizit `"disabled"` ("gebraucht weder lokal noch remote") — wird
nicht geladen. Hat zwar `README.md` + ein pädagogisches Konzept-Dokument, aber keine
`ROADMAP`. Aus der Schätzung ausgeklammert, da inaktiv.

---

## 4. File Types (Markdown & Documents)

### `cascade.nvim` — nicht bewertbar (Flag)
**Repo existiert nicht lokal unter `E:/repos`** (im Gegensatz zu allen anderen 27
Plugins aus `source.lua`). Da `OVERRIDE = "dir"` aktuell fest auf lokale Checkouts
erzwungen ist, würde lazy.nvim beim Fehlen des Ordners laut `personal_utils.local_dev`
automatisch auf Remote (GitHub) zurückfallen — die Roadmap müsste dafür aus dem
GitHub-Repo gezogen werden, was hier nicht gemacht wurde. **Empfehlung:** separat
klären, ob das Repo umbenannt/verschoben wurde oder ob es nur remote existiert.

### `pdfport.nvim` — 3–6 Tage
PDF-Backend-Dispatcher mit 6 Backends. Architektur größtenteils ✅ (Registry/Resolver/
Dispatcher-Trennung, strukturierte Result-Objekte, async via `vim.uv.spawn`).
Konkreter Rest-Backlog, in allen drei Audit-Dokumenten übereinstimmend: fehlende
automatisierte Tests (klarste Lücke, `test/smoke.lua` vorgeschlagen, 1–2 Tage),
`backends/init.lua` lädt aktuell eager statt lazy (wenige Stunden), optionaler
Window-Lifecycle-Helper (nur relevant falls ein 4. Renderer dazukommt).
`NEOTREE_FEATURES.md` hier ist wieder kein pdfport-Task, sondern Pattern-Vorlagen
für `filetree.nvim`.

### `markdown.nvim` — ~1 Woche (3–6 Abende)
Die echte Roadmap (separate `docs/ROADMAP.md`) zeigt: **alle** Haupt-Features als
Done markiert (Picker-Backends, Link-Diagnostics, konfigurierbare TOC, Anchor-Styles,
Table-Format-Optionen, HTML-Import, Theme-derivierte Blockquote-Farben). Einzig
laufend offen: Test-Suite-Wachstum (ongoing, kein Enddatum). Der detailliertere
`IMPLEMENTATION_PLAN.md` im Audit-Ordner nennt zusätzlich ein einzelnes konkretes
Feature (In-Buffer-Bildvorschau via snacks.nvim/image.nvim als Alternative zum
externen Viewer) als noch offen. Ein vim9script-Full-Port ist nur eine
Machbarkeitsstudie ("This is a first analysis, not a port"), abhängig von Bedarf, der
laut Autor noch nicht besteht — nicht mitgezählt.

### `color_my_ascii.nvim` — 1–3 Wochen
ASCII-Art-Highlighter mit Treesitter-Integration, 31 Sprachen, vollem `:Fence`-
Subcommand-Toolkit. Die echte Roadmap listet nur "Additional built-in color schemes"
als geplant (klein) und "Deeper lib.nvim integration" als "Under Consideration"
(bewusst blockiert, bis die lib-API stabil ist). Das eigentlich substanzielle Stück
Arbeit steckt in einem separaten Design-Dokument im Audit-Ordner: LSP-in-Fence-Support
(Hover/Completion/Diagnostics in Code-Fences) — empfohlener Weg über einen dünnen
otter.nvim-Adapter (1–3 Wochen); eine eigenständige Embedded-LSP-Engine wird im
Dokument selbst als "mehrere Wochen" geschätzt und explizit davon abgeraten.

### `recommender.nvim` — 0 Tage
Analysiert Buffer/Projekt auf wiederholte dotted chains (`vim.api`, `table.insert`)
und schlägt Alias-Deklarationen vor. Roadmap explizit: "No open items" — "currently
empty; every previously tracked idea has shipped."

### `mdview.nvim` — 6–10 Wochen
**Größtes offenes Backlog im gesamten Review.** Live-Markdown-Preview mit Go-Relay-
Server + WebSocket + Rust/comrak→WASM-Rendering im Browser, aktuell v0.2.0 nach einem
Node→Go/Rust-Rewrite. Genuinely offen:
- **Overlay-System** (explizit "not yet implemented"): generischer Overlay-Manager +
  `:MDViewOverlay`-Command, danach Floating-TOC, Focus-Zoom/Magnifier, Keycast (mit
  Privacy-Scoping), Reading-Progress-Bar, Attention-Ping, Presenter-Notes, Minimap —
  mit Abstand der größte Einzelposten.
- **Standalone/Serverless-Variante**: statischer HTML-Export sowie ein eigenständiges
  Single-Binary (`go:embed`, fsnotify-File-Watching, keine nvim-Abhängigkeit) — beides
  noch offen.
- **WebTransport**: Backend laut Design-Doc bereits fertig implementiert, aber
  echte Browser-Verifikation (Chromium HTTP/3) steht noch aus (nicht headless in CI
  testbar).
- **Highlighting-Mirror**: Syntax-Farben aus nvim/Treesitter oder `color_my_ascii.nvim`
  im Browser nachbilden — vom Autor selbst als "groß" eingestuft, nicht begonnen.

Flag: `Roadmap.md` verweist auf eine `TASKS.md` als eigentliche Backlog-Quelle — diese
Datei **existiert im Repo nicht** (nur ein False-Positive in `node_modules`), d.h. der
Verweis ist ein toter Link bzw. die Datei fehlt/wurde nie committed. Außerdem
widersprechen sich zwei Dateien zum WebTransport-Entscheid (eine sagt "verworfen",
eine neuere sagt "implementiert") — die neuere (`DESIGN.md`) wurde hier als
maßgeblich behandelt.

---

## Datenqualitäts-Flags (Zusammenfassung)

- **`gopath.nvim`**: keine echte Feature-Roadmap auffindbar, nur eine generische,
  offenbar repo-übergreifend kopierte Checkliste. Separat prüfen.
- **`cascade.nvim`**: Repo fehlt komplett unter `E:/repos` — nicht analysierbar ohne
  Remote-Zugriff auf GitHub.
- **`github_stats.nvim`**: hat als einziges Plugin eine **separate**, sehr
  ausführliche Feature-Roadmap neben dem Audit-Ordner — hier lag der größte
  Unterschied zwischen "nur Audit gelesen" und "vollständiges Bild".
- **`mdview.nvim`**: referenzierte `TASKS.md` existiert nicht im Repo (toter Verweis).
- Mehrere Plugins (`replacer.nvim`, `reposcope.nvim`, `language.nvim`) benutzen ihre
  `ROADMAP.md` faktisch als **Done-Changelog**, nicht als Vorausschau — Umbenennung
  würde künftige Verwechslungen vermeiden.
- `sessions.nvim`, `fileops.nvim`, `dap.nvim`, `diff.nvim`, `emojis.nvim`: Roadmap-
  Dateien sind leer/Platzhalter — nicht "kein Aufwand", sondern schlicht "noch nie
  geplant".
