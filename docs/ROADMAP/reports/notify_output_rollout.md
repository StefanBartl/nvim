# Notify/Output-Rollout — offene Aufgaben

Stand: 2026-09-27 · Historie, Architektur-Entscheidungen und Erledigtes:
[WKDBooks `lib.nvim/Backlog/TASKS/notify-output-rollout-2026-09-25.md`](https://github.com/StefanBartl/WKDBooks/blob/main/Development/wkdbook-myplugins/lib.nvim/Backlog/TASKS/notify-output-rollout-2026-09-25.md)

Diese Datei ersetzt die frühere Report-Serie `00`-`06` in diesem Ordner
(sieben Zwischendateien, die zunehmend auseinanderdrifteten — ins Archiv
verdichtet, siehe Link oben). Ab hier steht nur noch **offene** Arbeit,
gepflegt als einzige lebende Datei statt als Plan+Worklist-Paar.

## Status

| Phase | Inhalt | Status |
|---|---|---|
| P0 | `lib.nvim.notify.popup` erweitern (Kappung, `toast_min_level`, globaler Default, `expand_last`, `:Lib notify`) | ✅ erledigt (`80bdc3d`, `a60c481`) |
| P1 | `lib.nvim.echo`, `lib.nvim.output`-Fassade, `output.viewer` | ✅ erledigt |
| P2 | Progress-Style `echo`, Style-Liste | offen |
| P3 | Aktivierung in der Installations-Spec | offen — braucht eine Rückfrage (siehe unten) |
| P4 | Wrapper-Repos umstellen | ✅ erledigt — 11/12, 1 bewusst zurückgestellt (siehe Tabelle) |
| P5 | Load-Time-Bindungen | offen |
| P6 | `print`-Dumps auf `output.viewer.show_lines` | offen |

## P2 — Progress-Style `echo` + Style-Liste

**Dateien:** `lua/lib/nvim/progress/styles/echo.lua` (neu),
`lua/lib/nvim/progress/resolve_style.lua`, `lua/lib/nvim/progress/init.lua`

- `styles/echo.lua` implementiert denselben Vertrag wie `styles/statusline.lua`
  (`start(spec, opts, request_cancel) -> state`, `update(state, spec, opts) -> state`,
  `finish(state, spec, opts)`, `cancel(state, spec, opts)`), rendert über
  `lib.nvim.echo.write(chunks, {history=false})` bei `update`, und einmalig
  `history=true` bei `finish`/`cancel` (Abschluss-Nachricht bleibt im Log).
- `resolve_style.lua`: neuer Zweig `if want == "echo" then return require(...) end`,
  analog zu `"statusline"` — kein Soft-Dependency-Check nötig, `nvim_echo`
  ist Core-API.
- **Style-Liste:** `lib.nvim.progress`s `create(opts)` nimmt `opts.style`
  heute als **einen** Wert. Für `opts.style = {"statusline", "echo"}` muss
  `create()` **mehrere** `style_state`s parallel führen: aus
  `local style_state = nil` wird `local style_states = {}` (Liste), aus
  `style.start(...)`/`.update(...)`/`.finish(...)`/`.cancel(...)` werden
  Schleifen über alle aufgelösten Styles. **Rückwärtskompatibel:** ein
  String-`opts.style` wird zu einer Einzel-Element-Liste normalisiert,
  bestehende Aufrufer (`style = "notify"` etc.) ändern sich nicht.
- `@types/init.lua`: `Lib.Progress.Opts.style` Alias erweitern auf
  `Lib.Progress.Style|Lib.Progress.Style[]`.

### Tests (P2)

- Neue `TESTS/progress_echo_style_spec.lua` (vorher prüfen, ob es bereits
  Tests für `progress/init.lua` gibt und deren Konventionen übernehmen).
- Style-Liste: `create({style = {"statusline", "echo"}})`, `update(...)`
  aufrufen, prüfen dass **beide** Styles ihre `update`-Funktion mit
  demselben `spec` erhalten (zwei Stubs, zwei Call-Counts).

**Akzeptanzkriterium P2:** ein Handle mit `style = {"statusline", "echo"}`
zeigt Statusline-Badge UND eine Cmdline-Zeile für dieselbe Operation, ohne
doppelten aufruferseitigen Code.

## P3 — Aktivierung in der Installations-Spec

**Datei:** `C:\Users\bartl\AppData\Local\nvim\lua\plugins\personal\init.lua`
(dort, wo lib.nvim konfiguriert wird)

```lua
require("lib.nvim.notify").setup({ popup = true })
require("lib.nvim.notify.popup").setup({
  toast_min_level = vim.log.levels.INFO,
  -- max_lines/width/toast_max_bytes/entry_max_bytes: Defaults reichen erstmal
})
```

- **Offene Entscheidung (bei dir):** ein optionaler globaler Keymap für
  `popup.toggle_full()`/`expand_last()` zusätzlich zu `:Lib notify last`.
  Komfortfrage, der Befehl funktioniert auch ohne Taste — in dieser Runde
  nachfragen, welche Taste (`<leader>n…`-Namespace prüfen, ob frei).
- Falls die Taste gewünscht wird: Eintrag in **lib.nvims** `docs/BINDINGS.md`
  (nicht nvim-config), wenn der Keymap über `lib.nvim.bindings.keymap`
  läuft; sonst ins nvim-configs eigenes `docs/BINDINGS.md`.

**Akzeptanzkriterium P3:** nach einem `:so` der Spec zeigen alle ~30
lib-Nutzer Toasts, ohne dass ein Plugin angefasst wurde.

## P4 — Wrapper-Repos (abgeschlossen)

Reihenfolge nach Hebelwirkung. Je Repo, eine Runde (max. 1 Agent): Wrapper
ändern (nicht die Aufrufer), Repo-eigenen `:<Plugin> messages`-Befehl
ergänzen falls ein Command-Baum existiert, Tests/`stylua`/`luacheck` grün,
Commit/Push auf `main`.

| Rang | Repo | Status | Befund | Notiz |
|---|---|---|---|---|
| 1 | sessions.nvim | ✅ erledigt (`6bda06f`) | 7-fache Wrapper-Duplikation + 2 unangebundene `M.pick()`-Aufrufe | `sessions/util/notify.lua` |
| 2 | rules.nvim | ✅ erledigt (`f4e4fea`) | 15 raw `vim.notify`, null `lib_notify` | `rules/util/notify.lua`, harte Abhängigkeit |
| 3 | mdview.nvim | ✅ erledigt (`2aa6978`) | 7 raw `nvim_echo` in `ws_client.lua` | explizites `popup=true, source="mdview"` |
| 4 | media.nvim | ✅ erledigt (`308ddee`) | `ui.lua`, `hub/dashboard.lua`, `bindings/*`: 6 raw `notify`, kein `lib_notify` | `media/util/notify.lua` (soft dependency, wie `sessions.nvim`) |
| 5 | my.nvim (privat) | ✅ erledigt (`73670ce`) | `declarative/clipboard.lua:178,180,185`: 3 raw `notify` | hart auf `lib.nvim.notify.create("[my]")` |
| 6 | dap.nvim | ✅ erledigt (`892e804`) | `languages/rust.lua:138`, `zig.lua:109,119`: 3 raw `notify` WARN | auf bestehenden `wkddap.utils.notify`-Wrapper umgestellt |
| 7 | sandbox.nvim | ✅ erledigt (`b8c4c12`) | `notify.lua:17-23` | **Korrektur:** Wrapper rief `lib.nvim.notify.create()` schon korrekt mit Fallback auf — Scanner zählte den Fallback-Zweig mit. Fix: `popup=true, source="sandbox"` ergänzt |
| 8 | buffer-ctx.nvim | ✅ erledigt (`de930b8`) | `util/notify.lua:29-56` | dieselbe Korrektur wie sandbox.nvim: `popup=true, source="buffer-ctx"` ergänzt |
| 9 | markdown.nvim | ✅ erledigt (`a89d578`) | `util/notify.lua:29` | dieselbe Korrektur: `popup=true, source="markdown"` ergänzt |
| 10 | insights.nvim | ✅ erledigt (`68671e6`) | `config/init.lua:158`: 1 raw `notify` WARN, mehrzeilig | auf bestehenden `insights.util.notify`-Wrapper umgestellt (hart) |
| 11 | diff.nvim | ✅ erledigt (`e331128`) | `util/notify.lua`: `popup=true, source="diff"` ergänzt | **Reklassifiziert:** die 2 `nvim_echo`-Stellen (`core/directory.lua:281`, `core/render.lua:755`) sind bewusste Inhalts-Ausgabe (voller Diffstat/Unified-Diff-Text als eigener, expliziter Output-Modus), keine Notify-Kandidaten — unangetastet gelassen, siehe P6 |
| 12 | pickers.nvim | zurückgestellt | `cheatsheet/init.lua:122` | **Bestätigt kein P4-Fall:** `vim.notify`-Dump ist der Fallback für `ui.kit.viewer` (Cheatsheet-Inhalt, kein Ereignis) — gehört zu P6 (`output.viewer.show_lines`), sobald P1 steht. Kein Code geändert |

**Nicht anfassen:** `buffer-ctx.nvim/health.lua` (checkhealth),
`debugging.nvim/views/debug_helper.lua:260` (Selbsttest).

**Muster, das sich durch Rang 7-9 zog:** bei drei von zwölf Repos
(`sandbox.nvim`, `buffer-ctx.nvim`, `markdown.nvim`) war der vermeintlich
"unmigrierte" Wrapper bereits korrekt auf `lib.nvim.notify.create()` mit
sauberem Fallback gebaut — der Scanner zählte den Fallback-Zweig (nur
erreichbar, wenn `lib.nvim` fehlt) als "raw `vim.notify`" mit. Echte Lücke
war jeweils nur das fehlende `popup=true`/`source=...`. Bei zwei Repos
(`diff.nvim`, `pickers.nvim`) waren die gemeldeten `nvim_echo`/`vim.notify`-
Stellen bei genauerem Lesen bewusste Inhalts-Ausgabe statt Notify-Events —
Report 06 (jetzt archiviert) hatte das als reinen Zeilen-Scanner nicht
unterscheiden können.

## P5 — Load-Time-Bindungen

| Repo | Fundstelle | Hinweis |
|---|---|---|
| color_my_ascii.nvim | `commands/fence_check.lua:15`, `commands/format.lua:8`, `config/init.lua:10`, `highlighter.lua:15` | 4× `local notify = vim.notify` bei Modulload — klarer Bug, zuerst dran |
| filetree.nvim | `features/infra/watcher_quarantine/init.lua:85` | **erst Absicht prüfen** — sieht nach bewusster Sicherung fürs temporäre Unterdrücken aus |
| sandbox.nvim | `bindings/usrcmds/init.lua:85` | **erst Absicht prüfen** — vermutlich Sicherung rund um einen Sandbox-Lauf |
| mdview.nvim | `test/runner.lua:12` | Test-Runner, ignorieren |

`filetree.nvim`s eigener Notify-Wrapper (`util/notify.lua:13`) ist bereits
sauber `lib_notify` — nur die Load-Time-Bindung braucht hier noch etwas.

## P6 — `print`-Dumps

Je Fundstelle: `print(x)`/mehrere `print(...)`-Zeilen sammeln → ein
`require("lib.nvim.output.viewer").show_lines(title, lines)`-Aufruf (P1 muss
dafür stehen).

- **Größere Dumps:** color_my_ascii (`debug/commands.lua`, 35 Zeilen),
  replacer (`debug.lua`, 14 Zeilen), reposcope (`utils/debug.lua`,
  `bindings/usrcmds.lua`, mehrere Provider-/Query-Dumps), lsp
  (`lspdoctor/init.lua:202`), pdfport (`backends/docling.lua`,
  `backends/pdfplumber.lua`).
- **Einzeiler, vermutlich Debug-Reste (einzeln prüfen, nicht pauschal
  migrieren):** filetree (`features/nav/source_switcher/init.lua:410`,
  `features/infra/who_locks/init.lua:139,145,169`), fileops
  (`bindings/usrcmds.lua:660`), data (`bindings/usrcmds.lua:119`), debugging
  (`commands.lua:149`, `tools/cursor/state.lua:15`), lsp
  (`htmx/filter_logs.lua:59`, ein `echo`).

## Sonderfälle

- **reposcope.nvim** — die Referenzumsetzung, praktisch fertig. Nur eine
  Rest-Stelle offen: `utils/debug.lua:23`, ein dynamischer raw
  `vim.notify`-Aufruf neben dem bereits migrierten `lib_notify` in
  derselben Datei.
- **my.nvim ist privat** — keine technische Sonderbehandlung, nur als
  Hinweis bei einer eventuellen `ultracode`-Review oder einem geteilten
  Report zu beachten.
- **lib.nvim** — kein Konsument, ist die Quelle des Moduls selbst.
- **ui.nvim** — kein Konsument im Migrationssinn; liefert `ui.kit.toast`
  (weiche Abhängigkeit von `popup.lua`) und `ui.notify` (bereits erkannt
  über `ui_notify_active()`).
- **docmap-desktop, loomAI** — keine Neovim-Plugins, nicht anwendbar.

## Kategorie A — kein Handlungsbedarf (Referenz, 20 Plugins)

Diese rufen ausschließlich `lib.nvim.notify.create(...)` auf (direkt oder
über einen lib-first-Wrapper mit ungenutztem Fallback). Sobald P3 den
globalen Default setzt, zeigen sie Toasts, ohne dass hier etwas geändert
wird: ai.nvim, casedesk.nvim, cmdlog.nvim, open.nvim, language.nvim,
images.nvim, documentation.nvim, hover.nvim, github_stats.nvim,
gitsuite.nvim, lsp.nvim (plus 1 `echo`/1 `print`, P6-Kandidaten), debugging.nvim
(plus 1 Selbsttest, 2 `print`, P6-Kandidaten), data.nvim (plus 1 `print`,
P6-Kandidat), runtime-analysis.nvim (1 Kopierrest, optional), emojis.nvim,
gopath.nvim, recommender.nvim, spotlight.nvim, cascade.nvim, fileops.nvim
(plus 1 `print`, P6-Kandidat).
